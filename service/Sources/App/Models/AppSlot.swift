import Fluent
import Vapor

enum Platform: String, Codable, CaseIterable {
    case ios
    case android
}

final class AppSlot: Model, Content {
    static let schema = "app_slot"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String

    @Field(key: "desc")
    var desc: String
    
    @Enum(key: "platform")
    var platform: Platform
    
    @Field(key: "app_key")
    var appKey: String
    
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
