import InnerBalanceCore
import Observation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class HomeEchoController {
  var currentDate = Date.now
  private(set) var savedEcho: DailyEchoRecord?
  private(set) var history: [DailyEchoRecord] = []
  private(set) var saveMessage: String?

  func moveToCurrentDay(modelContext: ModelContext) {
    currentDate = .now
    load(modelContext: modelContext)
  }

  func load(modelContext: ModelContext) {
    let store = DailyEchoStore(modelContext: modelContext)
    savedEcho = try? store.echo(on: currentDate)
    history = (try? store.history()) ?? []
    saveMessage = nil
  }

  func save(state: DailyEchoState, modelContext: ModelContext) {
    do {
      let savedAt = Date.now
      currentDate = savedAt
      let store = DailyEchoStore(modelContext: modelContext)
      try store.save(
        state: state,
        note: savedEcho?.text ?? "",
        reflection: DailyReflectionSelector.reflection(on: savedAt, echo: state),
        date: savedAt
      )
      guard let verifiedEcho = try store.echo(on: savedAt), verifiedEcho.state == state else {
        throw HomeEchoSaveError.verificationFailed
      }
      savedEcho = verifiedEcho
      history = try store.history()
      saveMessage = "已记下"
      AccessibilityNotification.Announcement("已记下").post()
    } catch {
      saveMessage = "这次没存上，请再试一次"
      AccessibilityNotification.Announcement("这次没存上，请再试一次").post()
    }
  }
}

private enum HomeEchoSaveError: Error {
  case verificationFailed
}
