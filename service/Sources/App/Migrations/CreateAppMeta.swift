import Fluent
import MySQLKit

struct CreateAppMeta: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("app_meta")
            .id()
            .field("title", .string, .required)
            .field("content", .sql(raw: "TEXT"), .required)
            .field("platform", .enum(.init(name: "Platform", cases: Platform.allCases.map(\.rawValue))), .required)
            .field("access_token", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("app_meta").delete()
    }
}
