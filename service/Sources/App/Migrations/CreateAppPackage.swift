import Fluent

struct CreateAppPackage: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("app_package")
            .id()
            .field("app_meta_id", .uuid, .required, .references("app_meta", "id"))
            .field("title", .string, .required)
            .field("content", .sql(raw: "TEXT"), .required)
            .field("app_bundle_id", .string, .required)
            .field("app_version", .string, .required)
            .field("app_build", .string, .required)
            .field("app_display_name", .string, .required)
            .field("platform", .enum(.init(name: "Platform", cases: Platform.allCases.map(\.rawValue))), .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("app_package").delete()
    }
}
