import Foundation
import Queues

struct CleanupJob: AsyncScheduledJob {

    func run(context: QueueContext) async throws {
        context.logger.notice("starting cleanup job...")
        context.logger.notice("finished cleanup job")
    }
}
