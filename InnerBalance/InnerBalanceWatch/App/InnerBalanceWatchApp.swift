import SwiftData
import SwiftUI

@main
struct InnerBalanceWatchApp: App {
  private let modelContainer: ModelContainer

  init() {
    let schema = Schema([
      WatchPendingHealthWrite.self,
      WatchPracticeCompletion.self,
    ])
    let configuration = ModelConfiguration(schema: schema)
    do {
      modelContainer = try ModelContainer(for: schema, configurations: [configuration])
    } catch {
      fatalError("Unable to create the local watch persistence container.")
    }
  }

  var body: some Scene {
    WindowGroup {
      WatchRootView()
        .task { await WatchSyncLifecycle.shared.start(context: modelContainer.mainContext) }
    }
    .modelContainer(modelContainer)
  }
}
