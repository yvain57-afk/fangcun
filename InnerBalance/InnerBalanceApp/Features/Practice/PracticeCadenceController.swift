import InnerBalanceCore
import Observation

@MainActor
@Observable
final class PracticeCadenceController {
  var isEnabled = true
  private(set) var trigger = 0
  private var lastCueID: Int?
  private var lastGeneration: Int?

  func run(_ viewModel: PracticeSessionViewModel) async {
    guard viewModel.phase == .running else { return }
    while !Task.isCancelled && viewModel.phase == .running {
      if viewModel.remainingTime <= 0 {
        viewModel.finish()
        return
      }
      viewModel.checkpointIfNeeded()
      let cueID = viewModel.timelineSnapshot.cueID
      if isEnabled, cueID != lastCueID || lastGeneration != viewModel.timelineGeneration {
        lastGeneration = viewModel.timelineGeneration
        lastCueID = cueID
        trigger += 1
      }
      try? await Task.sleep(for: .milliseconds(25))
    }
  }
}
