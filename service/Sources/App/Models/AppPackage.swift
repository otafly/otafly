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
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }

    init(id: UUID? = nil, appMeta: AppMeta, info: PackageInfo, content: String?) throws {
        self.id = id
        self.$appMeta.id = try appMeta.requireID()
        self.title = appMeta.title
        self.platform = appMeta.platform
        self.content = content ?? ""
        self.appBundleId = info.bundleId
        self.appVersion = info.version
        self.appBuild = info.build
        self.appDisplayName = (info.name ?? appMeta.title.replacingOccurrences(of: " ", with: "")) + platform.packageExtension
    }
}

extension AppPackage {
    
    var appId: UUID {
        $appMeta.id
    }
}

private extension Platform {

    var packageExtension: String {
        switch self {
        case .ios: return ".ipa"
        case .android: return ".apk"
        }
    }
}
