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
      .accessibilityIdentifier("practice.close")
    }
  }
}

enum PracticeSessionDialogAction {
  case retry
  case dismiss
}

enum PracticeSessionDialogCopy {
  static let finishActionID = "practice.finish.confirm"
  static let finishMessageKey = "practice.finish.message"
  static var finishActionTitle: String { FangcunCopy.text("practice.finish.action") }
  static var finishMessage: String { FangcunCopy.text(finishMessageKey) }
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
  @Environment(\.dynamicTypeSize) private var typeSize
  @Binding var showFinish: Bool
  @Binding var showExit: Bool
  @Binding var saveErrorMessage: String?
  let onFinish: () -> Void
  let onRetry: () -> Void
  let onDiscard: () -> Void

  func body(content: Content) -> some View {
    content
      .tint(InnerBalanceTheme.strongFill)
      .sheet(isPresented: Binding(get: { showFinish || showExit }, set: { if !$0 { showFinish = false; showExit = false } })) {
        ScrollView {
        VStack(alignment: .leading, spacing: 22) {
          Text("这次先到这里？").font(.title2.weight(.semibold))
          Text(PracticeSessionDialogCopy.finishMessage).font(.body).foregroundStyle(InnerBalanceTheme.mutedInk)
          Button("继续练习") { showFinish = false; showExit = false }
            .buttonStyle(InnerBalancePrimaryButtonStyle()).accessibilityIdentifier("practice.finish.cancel")
          Button(PracticeSessionDialogCopy.finishActionTitle) {
            showFinish = false; showExit = false; onFinish()
          }.frame(maxWidth: .infinity, minHeight: 44).font(.headline)
            .accessibilityIdentifier(PracticeSessionDialogCopy.finishActionID)
        }.padding(24)
        }.foregroundStyle(InnerBalanceTheme.ink)
          .presentationBackground(InnerBalanceTheme.canvas)
          .presentationDetents(typeSize.isAccessibilitySize ? [.large] : [.medium, .large]).presentationDragIndicator(.visible)
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
