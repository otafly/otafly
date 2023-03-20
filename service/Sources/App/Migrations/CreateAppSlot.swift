import Fluent

struct CreateAppSlot: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("app_slot")
            .id()
            .field("title", .string, .required)
            .field("desc", .string, .required)
            .field("app_key", .string, .required)
            .field("platform", .enum(.init(name: "Platform", cases: Platform.allCases.map(\.rawValue))), .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("app_meta").delete()
    }
}
