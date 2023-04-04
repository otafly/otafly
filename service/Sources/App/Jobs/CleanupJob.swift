import Foundation
import Queues

struct CleanupJob: AsyncScheduledJob {

    func run(context: QueueContext) async throws {
        context.logger.notice("starting cleanup job...")
        try await context.application.appSvc.cleanupPackages(reserved: 20)
        context.logger.notice("finished cleanup job")
    }
}
