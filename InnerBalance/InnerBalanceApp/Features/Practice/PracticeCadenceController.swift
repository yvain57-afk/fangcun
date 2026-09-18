import InnerBalanceCore
import Observation

@MainActor
@Observable
final class PracticeCadenceController {
  var isEnabled = true
  private(set) var trigger = 0
  private var lastCueID: Int?

  func run(_ viewModel: PracticeSessionViewModel) async {
    guard viewModel.phase == .running else { return }
    while !Task.isCancelled && viewModel.phase == .running {
      if viewModel.remainingTime <= 0 {
        viewModel.finish()
        return
      }
      let cueID = PracticeHapticTimeline.cueID(
        for: viewModel.plan.kind,
        elapsed: viewModel.duration - viewModel.remainingTime,
        duration: viewModel.duration
      )
      if isEnabled, cueID != lastCueID {
        lastCueID = cueID
        trigger += 1
      }
      try? await Task.sleep(for: .milliseconds(250))
    }
  }
}
