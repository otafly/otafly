import Foundation
import Vapor
import NIO
import MultipartKit

enum FormDataValue {
    
    case text(String?)
    case file(URL)
}

class FormDataResolver {
    
    private let tempDir: URL
    
    init(tempDir: URL) {
        self.tempDir = tempDir
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            fatalError("failed to create tempDir:\(tempDir) error:\(error)")
        }
    }
    
    func resolve(req: Request) async throws -> AsyncThrowingStream<(String, FormDataValue), Error> {
        guard let boundary = req.headers.contentType?.parameters["boundary"] else {
            throw Abort(.unsupportedMediaType)
        }
        let stream = MultipartParser(boundary: boundary).drain(req: req)
        return AsyncThrowingStream {
            try await self.resolve(req: req, stream: stream)
        }
    }
    
    private func resolve(req: Request, stream: PartEvents) async throws -> (String, FormDataValue)? {
        var partResolver: FormPartResolver?
        var headers = HTTPHeaders()
        
        for try await event in stream {
            switch event {
            case let .header(field, value):
                headers.replaceOrAdd(name: field, value: value)
            case .headerEnded:
                guard let name = headers.contentName else {
                    throw Abort(.badRequest, reason: "missing name in form-data")
                }
                let resolver: FormPartResolver
                if headers.isFile {
                    let tempURL = tempDir.appendingPathComponent(UUID().uuidString, isDirectory: false)
                    resolver = FormPartFileResolver(eventLoop: req.eventLoop, name: name, tempFileURL: tempURL)
                } else {
                    resolver = FormPartTextResolver(name)
                }
                partResolver = resolver
                try await resolver.open()
            case .body(var new):
                guard let partResolver else {
                    throw Abort(.badRequest, reason: "missing name in form-data")
                }
                try await partResolver.write(buffer: &new)
            case .complete:
                guard let partResolver else {
                    throw Abort(.badRequest, reason: "missing name in form-data")
                }
                return try await partResolver.finish(headers: headers)
            }
        }
        return nil
    }
}

private typealias PartEvents = AsyncThrowingStream<MultipartParser.PartEvent, Error>

private protocol FormPartResolver {
    
    func open() async throws
        
    func write(buffer: inout ByteBuffer) async throws
    
    func finish(headers: HTTPHeaders) async throws -> (String, FormDataValue)
}

private class FormPartTextResolver: FormPartResolver {
    
    let name: String
    
    private var data = ByteBuffer()
    
    init(_ name: String) {
        self.name = name
    }
    
    func open() async throws {}
    
    func write(buffer: inout ByteBuffer) async throws {
        data.writeBuffer(&buffer)
    }
    
    func finish(headers: HTTPHeaders) async throws -> (String, FormDataValue) {
        (name, .text(data.readString(length: data.readableBytes)))
    }
}

private class FormPartFileResolver: FormPartResolver {
    
    let name: String
    
    var tempFileURL: URL
    
    private let eventLoop: EventLoop
    
    private var handler: NIOFileHandle?
    
    init(eventLoop: EventLoop, name: String, tempFileURL: URL) {
        self.eventLoop = eventLoop
        self.name = name
        self.tempFileURL = tempFileURL
    }
    
    func open() async throws {
        handler = try await NonBlockingFileIO.default.openFile(
            path: tempFileURL.path,
            mode: .write,
            flags: .allowFileCreation(),
            eventLoop: eventLoop).get()
    }
    
    func write(buffer: inout ByteBuffer) async throws {
        guard let handler else { return }
        try await NonBlockingFileIO.default.write(fileHandle: handler, buffer: buffer, eventLoop: eventLoop).get()
    }
    
    func finish(headers: HTTPHeaders) async throws -> (String, FormDataValue) {
        try await eventLoop.performWithTask {
            try self.handler?.close()
        }.get()
        return (name, .file(tempFileURL))
    }
}

private extension HTTPHeaders {
    
    var isFile: Bool {
        if let contentType = headerParts(name: "Content-Type")?.first {
            return contentType != "text/plain"
        } else {
            return false
        }
    }
    
    var contentName: String? {
        getParameter("Content-Disposition", "name")
    }
    
    func getParameter(_ name: String, _ key: String) -> String? {
        return self.headerParts(name: name).flatMap {
            $0.filter { $0.hasPrefix("\(key)=") }
                .first?
                .split(separator: "=")
                .last
                .flatMap { $0 .trimmingCharacters(in: .quotes)}
        }
    }
    
    func headerParts(name: String) -> [String]? {
        return self[name]
            .first
            .flatMap {
                $0.split(separator: ";")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
            }
    }
}

extension CharacterSet {
    static var quotes: CharacterSet {
        return .init(charactersIn: #""'"#)
    }
}

private extension MultipartParser {
    
    enum PartEvent {
        case header(String, String)
        case headerEnded
        case body(ByteBuffer)
        case complete
    }
    
    func drain(req: Request) -> PartEvents {
        AsyncThrowingStream { cont in
            var isBody = false
            let chunkSize = NonBlockingFileIO.defaultChunkSize
            var buffer = ByteBuffer()
            buffer.reserveCapacity(chunkSize)
            onHeader = { (field, value) in
                isBody = false
                cont.yield(.header(field, value))
            }
            onBody = { new in
                if isBody == false {
                    cont.yield(.headerEnded)
                    isBody = true
                }
                buffer.writeBuffer(&new)
                if buffer.readableBytes > chunkSize {
                    cont.yield(.body(buffer))
                    buffer.clear()
                }
            }
            onPartComplete = {
                isBody = false
                if buffer.readableBytes > 0 {
                    cont.yield(.body(buffer))
                    buffer.clear()
                }
                cont.yield(.complete)
            }
            drain(req: req) { error in
                cont.finish(throwing: error)
            }
        }
    }
    
    private func drain(req: Request, completion: @escaping (Error?) -> Void) {
        var hasExecuteError = false
        req.body.drain {
            guard hasExecuteError == false else {
                return req.eventLoop.makeSucceededFuture(())
            }
            switch $0 {
            case .buffer(let buffer):
                do {
                    try self.execute(buffer)
                } catch {
                    hasExecuteError = true
                    completion(error)
                }
            case .error(let error):
                completion(error)
            case .end:
                completion(nil)
            }
            return req.eventLoop.makeSucceededFuture(())
        }
    }
}
