import Fluent
import Vapor

enum Platform: String, Codable, CaseIterable {
    case ios
    case android
}

final class AppPackage: Model, Content {
    static let schema = "app_package"
    
    @ID(key: .id)
    var id: UUID?

    @Parent(key: "app_meta_id")
    var appMeta: AppMeta
    
    @Field(key: "title")
    var title: String

    @Field(key: "content")
    var content: String
    
    @Enum(key: "platform")
    var platform: Platform
    
    @Field(key: "app_bundle_id")
    var appBundleId: String
    
    @Field(key: "app_version")
    var appVersion: String
    
    @Field(key: "app_build")
    var appBuild: String
    
    @Field(key: "app_display_name")
    var appDisplayName: String
    
    @Timestamp(key: "author_at", on: .none)
    var authorAt: Date?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }

    init(id: UUID? = nil, appMeta: AppMeta, info: PackageInfo, content: String?, authorAt: Date?) throws {
        self.id = id
        self.$appMeta.id = try appMeta.requireID()
        self.title = appMeta.title
        self.platform = appMeta.platform
        self.content = content ?? ""
        self.appBundleId = info.bundleId
        self.appVersion = info.version
        self.appBuild = info.build
        self.appDisplayName = info.name ?? appMeta.title.replacingOccurrences(of: " ", with: "")
        self.authorAt = authorAt ?? Date()
    }
}

extension AppPackage {
    
    var appId: UUID {
        $appMeta.id
    }
}
