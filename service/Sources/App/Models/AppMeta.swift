import Fluent
import Vapor

final class AppMeta: Model, Content {
    static let schema = "app_meta"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String

    @Field(key: "content")
    var content: String
    
    @Enum(key: "platform")
    var platform: Platform
    
    @Field(key: "access_token")
    var accessToken: String
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }

    init(id: UUID? = nil, title: String, content: String, platform: Platform) {
        self.id = id
        self.title = title
        self.content = content
        self.platform = platform
        self.accessToken = UUID().uuidString
    }
}
