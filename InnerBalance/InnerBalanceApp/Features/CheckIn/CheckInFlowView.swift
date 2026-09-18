import SwiftUI

struct CheckInFlowView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var viewModel: CheckInViewModel
  let onPrimarySaved: (StateOfMindRecord) -> Void

  init(
    saver: any CheckInSaving,
    diagnostics: any CheckInDiagnosticsRecording,
    onPrimarySaved: @escaping (StateOfMindRecord) -> Void
  ) {
    _viewModel = State(
      initialValue: CheckInViewModel(saver: saver, diagnostics: diagnostics)
    )
    self.onPrimarySaved = onPrimarySaved
  }

  var body: some View {
    ZStack {
      InnerBalanceTheme.canvas.ignoresSafeArea()
      switch viewModel.step {
      case .compass, .words:
        EmotionCompassView(viewModel: viewModel) { dismiss() }
      case .saved:
        OptionalContextSheet(viewModel: viewModel) {
          publishLatestRecordAndDismiss()
        }
      }
    }
    .onChange(of: viewModel.step) { _, step in
      guard step == .saved, let record = viewModel.savedRecord else { return }
      onPrimarySaved(record)
    }
    .sensoryFeedback(.success, trigger: viewModel.saveState == .saved)
  }

  private func publishLatestRecordAndDismiss() {
    if let record = viewModel.savedRecord {
      onPrimarySaved(record)
    }
    dismiss()
  }
}
