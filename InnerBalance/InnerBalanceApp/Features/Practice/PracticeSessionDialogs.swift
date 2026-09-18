import SwiftUI

struct PracticeCloseToolbar: ToolbarContent {
  let isActive: Bool
  @Binding var showExitConfirmation: Bool
  let onDismiss: () -> Void

  var body: some ToolbarContent {
    ToolbarItem(placement: .cancellationAction) {
      Button("\(Image(systemName: "xmark"))") {
        if isActive { showExitConfirmation = true } else { onDismiss() }
      }
      .frame(minWidth: 44, minHeight: 44)
      .accessibilityLabel("关闭练习")
    }
  }
}

enum PracticeSessionDialogAction {
  case retry
  case dismiss
}

enum PracticeSessionDialogCopy {
  static let finishActionTitle = "结束练习"
  static let finishMessage = "今天到这里，也很好。结束后可保留已完成的时长。"
}

enum PracticeSessionDialogPolicy {
  static func shouldRetry(for action: PracticeSessionDialogAction) -> Bool {
    switch action {
    case .retry: true
    case .dismiss: false
    }
  }
}

private struct PracticeSessionDialogs: ViewModifier {
  @Binding var showFinish: Bool
  @Binding var showExit: Bool
  @Binding var saveErrorMessage: String?
  let onFinish: () -> Void
  let onRetry: () -> Void
  let onDiscard: () -> Void

  func body(content: Content) -> some View {
    content
      .tint(InnerBalanceTheme.strongFill)
      .confirmationDialog("要提前结束吗？", isPresented: $showFinish) {
        Button(PracticeSessionDialogCopy.finishActionTitle, action: onFinish)
        Button("继续练习", role: .cancel) {}
      } message: {
        Text(PracticeSessionDialogCopy.finishMessage)
      }
      .confirmationDialog("正在进行练习", isPresented: $showExit) {
        Button(PracticeSessionDialogCopy.finishActionTitle, action: onFinish)
        Button("直接离开，不记录", action: onDiscard)
        Button("继续练习", role: .cancel) {}
      } message: {
        Text(PracticeSessionDialogCopy.finishMessage)
      }
      .alert(
        "未能保留本次练习",
        isPresented: Binding(
          get: { saveErrorMessage != nil },
          set: { if !$0 { saveErrorMessage = nil } }
        )
      ) {
        Button("重试") {
          saveErrorMessage = nil
          if PracticeSessionDialogPolicy.shouldRetry(for: .retry) { onRetry() }
        }
        Button("稍后处理", role: .cancel) {}
      } message: {
        Text(saveErrorMessage ?? "请重试。")
      }
  }
}

extension View {
  func practiceSessionDialogs(
    showFinish: Binding<Bool>,
    showExit: Binding<Bool>,
    saveErrorMessage: Binding<String?>,
    onFinish: @escaping () -> Void,
    onRetry: @escaping () -> Void,
    onDiscard: @escaping () -> Void
  ) -> some View {
    modifier(
      PracticeSessionDialogs(
        showFinish: showFinish,
        showExit: showExit,
        saveErrorMessage: saveErrorMessage,
        onFinish: onFinish,
        onRetry: onRetry,
        onDiscard: onDiscard
      )
    )
  }
}
