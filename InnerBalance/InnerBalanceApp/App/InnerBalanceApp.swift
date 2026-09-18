import SwiftData
import SwiftUI

@main
struct InnerBalanceApp: App {
  @State private var readiness = ReadinessCoordinator.make()
  private let modelContainer: ModelContainer

  init() {
    let schema = Schema([
      PendingHealthWrite.self,
      CheckInDiagnosticEvent.self,
      LocalDiagnosticEvent.self,
      CachedCheckIn.self,
      StoredPracticeCompletion.self,
      StoredDailyEcho.self,
    ])
    #if DEBUG
    let isUITesting = ProcessInfo.processInfo.arguments.contains("--ui-testing")
    #else
    let isUITesting = false
    #endif
    let configuration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: isUITesting
    )
    do {
      modelContainer = try ModelContainer(for: schema, configurations: [configuration])
    } catch {
      fatalError("Unable to create the local persistence container.")
    }
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(\.readinessOwner, readiness)
        .modifier(FangcunDisplayPreferences())
    }
    .modelContainer(modelContainer)
  }
}
