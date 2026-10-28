import InnerBalanceCore
import SwiftUI

struct OptionalContextSheet: View {
  @Bindable var viewModel: CheckInViewModel
  let onDone: () -> Void

  @State private var bodyCodes: Set<String> = []
  @State private var associations: [CheckInAssociation] = []
  @State private var isSaving = false

  private let columns = [
    GridItem(.adaptive(minimum: FangcunLayout.spacing(26)), spacing: FangcunLayout.spacing(2))
  ]
  private let bodyOptions: [(code: String, title: String)] = [
    ("shoulders_tight", "Tight shoulders or neck"),
    ("chest_tight", "Chest tightness"),
    ("stomach_discomfort", "Stomach discomfort"),
    ("shallow_breath", "Shallow breathing"),
    ("heavy_head", "Heavy-headed"),
    ("fatigue", "Worn out"),
    ("none", "Nothing noticeable"),
  ]

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: FangcunLayout.spacing(6)) {
        savedHeader

        if viewModel.showsSupportGuidance {
          supportGuidance
        }

        optionalSection(title: "What's on your mind? One is enough.") {
          LazyVGrid(columns: columns, alignment: .leading, spacing: FangcunLayout.spacing(2)) {
            ForEach(CheckInAssociation.allCases, id: \.self) { association in
              associationChip(association)
            }
          }
        }

        optionalSection(title: "Anything in your body? (Optional)") {
          LazyVGrid(columns: columns, alignment: .leading, spacing: FangcunLayout.spacing(2)) {
            ForEach(bodyOptions, id: \.code) { option in
              chip(option.title, selected: bodyCodes.contains(option.code)) {
                toggleBodyCode(option.code)
              }
            }
          }
        }

        if viewModel.optionalContextFailed {
          Label(
            "Couldn't safely save the extra details. Your main check-in is already saved.",
            systemImage: "exclamationmark.circle"
          )
          .font(.caption)
          .foregroundStyle(InnerBalanceTheme.emphasis)
        }

        VStack(spacing: FangcunLayout.spacing(3)) {
          if !bodyCodes.isEmpty || !associations.isEmpty {
            Button(isSaving ? "Saving the extra details…" : "Save details") {
              Task { await saveOptionalContext() }
            }
            .buttonStyle(InnerBalancePrimaryButtonStyle())
            .disabled(isSaving)
          }
          Button("Leave it here", action: onDone)
            .font(.headline)
            .foregroundStyle(InnerBalanceTheme.mutedInk)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, FangcunLayout.pageHorizontalPadding)
      .padding(.vertical, FangcunLayout.spacing(6))
    }
    .background(InnerBalanceTheme.canvas)
    .foregroundStyle(InnerBalanceTheme.ink)
  }

  private var savedHeader: some View {
    VStack(alignment: .leading, spacing: FangcunLayout.spacing(2)) {
      HStack {
        Label("A small moment, saved", systemImage: "checkmark.circle.fill")
          .font(.caption.weight(.semibold)).foregroundStyle(Color("FangcunExhale"))
        Spacer()
        PracticeCompanionV4(kind: .meditation, elapsed: 0, duration: 300, isActive: false)
          .frame(width: 92, height: 80).accessibilityHidden(true)
      }
      Text("Check-in saved")
        .font(.title.weight(.semibold))
      if let record = viewModel.savedRecord, record.unclassified {
        Text("No label needed. Your position is saved.")
          .font(.headline)
      } else if let label = viewModel.savedRecord?.labels.first {
        Text(label.displayName)
          .font(.title3.weight(.medium))
      }
      Text(saveDetail)
        .font(.subheadline)
        .foregroundStyle(InnerBalanceTheme.mutedInk)
    }
  }

  private var saveDetail: String {
    viewModel.primaryWriteResult == .queued
      ? "Saved on this device. We'll retry when Health access is available. Everything below is optional."
      : "Your check-in is saved. You can skip everything below."
  }

  private var supportGuidance: some View {
    VStack(alignment: .leading, spacing: 8) {
      Label("You don't have to carry this alone", systemImage: "person.2.fill")
        .font(.headline)
        .foregroundStyle(InnerBalanceTheme.emphasis)
      Text("If this hopelessness feels hard to carry alone, reach out to someone you trust now, or seek local professional or emergency support.")
        .font(.subheadline)
    }
    .fixedSize(horizontal: false, vertical: true)
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      InnerBalanceTheme.subtleFill,
      in: RoundedRectangle(
        cornerRadius: FangcunLayout.spacing(5),
        style: .continuous
      )
    )
    .overlay {
      RoundedRectangle(
        cornerRadius: FangcunLayout.spacing(5),
        style: .continuous
      )
      .strokeBorder(InnerBalanceTheme.hairline, lineWidth: 1)
    }
    .accessibilityElement(children: .combine)
  }

  private func optionalSection<Content: View>(
    title: String,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: FangcunLayout.spacing(3)) {
      Text(title)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(InnerBalanceTheme.mutedInk)
      content()
    }
  }

  private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(title)
        .font(.subheadline.weight(.medium))
        .padding(.horizontal, 12)
        .padding(.vertical, FangcunLayout.spacing(3))
        .frame(minHeight: 44)
        .frame(maxWidth: .infinity)
        .background(
          selected ? InnerBalanceTheme.strongFill : InnerBalanceTheme.surface,
          in: Capsule()
        )
        .overlay {
          Capsule()
            .strokeBorder(
              selected ? InnerBalanceTheme.emphasis : InnerBalanceTheme.hairline,
              lineWidth: selected ? 2 : 1
            )
        }
    }
    .buttonStyle(.plain)
    .foregroundStyle(selected ? InnerBalanceTheme.inverseInk : InnerBalanceTheme.ink)
    .accessibilityAddTraits(selected ? .isSelected : [])
  }

  private func associationChip(_ association: CheckInAssociation) -> some View {
    let position = associations.firstIndex(of: association)
    let selected = position != nil
    let selectionRole = position == 0 ? "Primary" : (position == 1 ? "Secondary" : nil)

    return Button {
      toggleAssociation(association)
    } label: {
      VStack(spacing: 2) {
        Text(association.displayName)
          .font(.subheadline.weight(.medium))
        if let selectionRole {
          Text(selectionRole)
            .font(.caption2.weight(.bold))
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, FangcunLayout.spacing(2))
      .frame(minHeight: 44)
      .frame(maxWidth: .infinity)
      .background(
        selected ? InnerBalanceTheme.strongFill : InnerBalanceTheme.surface,
        in: Capsule()
      )
      .overlay {
        Capsule()
          .strokeBorder(
            selected ? InnerBalanceTheme.emphasis : InnerBalanceTheme.hairline,
            lineWidth: selected ? 2 : 1
          )
      }
    }
    .buttonStyle(.plain)
    .foregroundStyle(selected ? InnerBalanceTheme.inverseInk : InnerBalanceTheme.ink)
    .disabled(!selected && associations.count == 2)
    .accessibilityLabel(
      selectionRole.map { "\(association.displayName), \($0) source" }
        ?? association.displayName
    )
    .accessibilityHint(
      !selected && associations.count == 2 ? "Deselect a source first" : ""
    )
    .accessibilityAddTraits(selected ? .isSelected : [])
  }

  private func toggleBodyCode(_ code: String) {
    if code == "none" {
      bodyCodes = bodyCodes == ["none"] ? [] : ["none"]
    } else {
      bodyCodes.remove("none")
      if bodyCodes.contains(code) {
        bodyCodes.remove(code)
      } else {
        bodyCodes.insert(code)
      }
    }
  }

  private func toggleAssociation(_ association: CheckInAssociation) {
    if let index = associations.firstIndex(of: association) {
      associations.remove(at: index)
    } else if associations.count < 2 {
      associations.append(association)
    }
  }

  private func saveOptionalContext() async {
    isSaving = true
    await viewModel.saveOptionalContext(
      bodySensationCodes: Array(bodyCodes),
      associations: associations
    )
    isSaving = false
    if !viewModel.optionalContextFailed {
      onDone()
    }
  }
}

extension CheckInAssociation {
  var displayName: String {
    switch self {
    case .work: "Work"
    case .tasks: "Tasks"
    case .health: "Health"
    case .family: "Family"
    case .relationship: "Relationships"
    case .money: "Money"
    case .training: "Exercise"
    case .sleep: "Sleep"
    }
  }
}
