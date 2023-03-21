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
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }

    init(id: UUID? = nil, title: String, desc: String, platform: Platform) {
        self.id = id
        self.title = title
    }
}
