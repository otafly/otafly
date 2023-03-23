import Foundation
import Vapor
import NIO
@testable import MultipartKit

class FormDataResolver {
    
    private var cacheURL: URL
    
    init(cacheURL: URL) {
        self.cacheURL = cacheURL
    }
    
    func handle(req: Request) async throws -> [FormDataValue] {
        guard let boundary = req.headers.contentType?.parameters["boundary"] else {
            throw Abort(.unsupportedMediaType)
        }
        let parser = MultipartParser(boundary: boundary)
        var result = [FormDataValue]()
        
        var current: FormDataValue?
        var headers = HTTPHeaders()
        var data = ByteBuffer()
        for try await event in parser.drain(req: req) {
            switch event {
            case let .header(field, value):
                headers.replaceOrAdd(name: field, value: value)
            case .headerEnded:
                if let name = headers.contentName {
                    if headers.isFile {
                        let tempURL = self.cacheURL.appendingPathComponent(UUID().uuidString, isDirectory: false)
                        let item = FormDataFile(eventLoop: req.eventLoop, name: name, tempFileURL: tempURL)
                        try await item.open()
                        current = .file(item)
                    } else {
                        current = .text(FormDataText(name))
                    }
                }
            case .body(let new):
                guard let current else { continue }
                switch current {
                case .text:
                    data.writeImmutableBuffer(new)
                case .file(let item):
                    try await item.write(buffer: new)
                }
            case .complete:
                if let current {
                    let part = MultipartPart(headers: headers, body: ByteBuffer())
                    switch current {
                    case .text(let item):
                        item.part = part
                        item.value = data.readString(length: data.readableBytes)
                    case .file(let item):
                        item.part = part
                        try await item.close()
                    }
                    result.append(current)
                }
                current = nil
                headers = [:]
                data = ByteBuffer()
            }
        }
        return result
    }
}

enum FormDataValue {
    
    case text(FormDataText)
    case file(FormDataFile)
}

class FormDataText {
    
    let name: String
    
    var value: String?
    
    var part: MultipartPart?
    
    init(_ name: String) {
        self.name = name
    }
}

class FormDataFile {
    
    let name: String
    
    var tempFileURL: URL
    
    var part: MultipartPart?
    
    private let eventLoop: EventLoop
    
    private var handler: NIOFileHandle?
    
    init(eventLoop: EventLoop, name: String, tempFileURL: URL) {
        self.eventLoop = eventLoop
        self.name = name
        self.tempFileURL = tempFileURL
    }
}

fileprivate extension FormDataFile {
    
    func open() async throws {
        handler = try await NonBlockingFileIO.default.openFile(
            path: tempFileURL.path,
            mode: .write,
            flags: .allowFileCreation(),
            eventLoop: eventLoop).get()
    }
    
    func write(buffer: ByteBuffer) async throws {
        guard let handler else { return }
        try await NonBlockingFileIO.default.write(fileHandle: handler, buffer: buffer, eventLoop: eventLoop).get()
    }
    
    func close() async throws {
        try await eventLoop.performWithTask {
            try self.handler?.close()
        }.get()
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
}

extension MultipartParser {
    
    enum PartEvent {
        case header(String, String)
        case headerEnded
        case body(ByteBuffer)
        case complete
    }
    
    func drain(req: Request) -> AsyncThrowingStream<PartEvent, Error> {
        AsyncThrowingStream { cont in
            var isBody = false
            onHeader = { (field, value) in
                isBody = false
                cont.yield(.header(field, value))
            }
            onBody = { new in
                if isBody == false {
                    cont.yield(.headerEnded)
                    isBody = true
                }
                cont.yield(.body(new))
            }
            onPartComplete = {
                isBody = false
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
