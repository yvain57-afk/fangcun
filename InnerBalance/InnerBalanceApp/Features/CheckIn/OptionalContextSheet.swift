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
    ("shoulders_tight", "肩颈紧"),
    ("chest_tight", "胸口紧"),
    ("stomach_discomfort", "胃部不适"),
    ("shallow_breath", "呼吸浅"),
    ("heavy_head", "头沉"),
    ("fatigue", "疲惫"),
    ("none", "无明显感觉"),
  ]

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: FangcunLayout.spacing(6)) {
        savedHeader

        if viewModel.showsSupportGuidance {
          supportGuidance
        }

        optionalSection(title: "压力主要来自哪里（选一个即可）") {
          LazyVGrid(columns: columns, alignment: .leading, spacing: FangcunLayout.spacing(2)) {
            ForEach(CheckInAssociation.allCases, id: \.self) { association in
              associationChip(association)
            }
          }
        }

        optionalSection(title: "身体有什么感觉（可选）") {
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
            "补充信息暂时无法安全保存；主记录已经保留，不受影响。",
            systemImage: "exclamationmark.circle"
          )
          .font(.caption)
          .foregroundStyle(InnerBalanceTheme.emphasis)
        }

        VStack(spacing: FangcunLayout.spacing(3)) {
          if !bodyCodes.isEmpty || !associations.isEmpty {
            Button(isSaving ? "正在保存补充…" : "保存补充") {
              Task { await saveOptionalContext() }
            }
            .buttonStyle(InnerBalancePrimaryButtonStyle())
            .disabled(isSaving)
          }
          Button("先这样", action: onDone)
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
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 38))
        .foregroundStyle(InnerBalanceTheme.strongFill)
        .accessibilityHidden(true)
      Text("已记录此刻")
        .font(.title.weight(.semibold))
      if let record = viewModel.savedRecord, record.unclassified {
        Text("都不像，也已保留罗盘位置")
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
      ? "已保存在本机，将在健康权限可用时重试。下面都可以跳过。"
      : "主记录已经保存。下面都可以跳过，不会阻塞完成。"
  }

  private var supportGuidance: some View {
    VStack(alignment: .leading, spacing: 8) {
      Label("不用独自承受", systemImage: "person.2.fill")
        .font(.headline)
        .foregroundStyle(InnerBalanceTheme.emphasis)
      Text("如果这份绝望很难独自承受，请现在联系一位你信任的人，或寻求当地的专业或紧急支持。")
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
    let selectionRole = position == 0 ? "主要" : (position == 1 ? "其次" : nil)

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
      selectionRole.map { "\(association.displayName)，\($0)来源" }
        ?? association.displayName
    )
    .accessibilityHint(
      !selected && associations.count == 2 ? "先取消一个已选来源" : ""
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
    case .work: "工作"
    case .tasks: "任务"
    case .health: "健康"
    case .family: "家庭"
    case .relationship: "关系"
    case .money: "金钱"
    case .training: "训练"
    case .sleep: "睡眠"
    }
  }
}
