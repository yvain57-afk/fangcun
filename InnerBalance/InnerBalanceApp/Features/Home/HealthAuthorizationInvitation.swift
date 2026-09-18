import SwiftUI

struct HealthAuthorizationInvitation: View {
  let isRequesting: Bool
  let onRequest: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Label("愿意的话，看看身体数据", systemImage: "heart.text.clipboard")
        .font(.headline)
        .foregroundStyle(InnerBalanceTheme.ink)
      Text("读取哪些内容，由你来选。方寸不把健康数据上传到自己的或第三方服务器；Apple 健康是否通过 iCloud 同步，由你的系统设置决定。")
        .font(.subheadline)
        .foregroundStyle(InnerBalanceTheme.mutedInk)
        .fixedSize(horizontal: false, vertical: true)
      Button(isRequesting ? "正在打开 Apple 健康…" : "选择健康权限", action: onRequest)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(InnerBalanceTheme.strongFill)
        .frame(minHeight: 44, alignment: .leading)
        .disabled(isRequesting)
        .accessibilityHint("打开系统健康权限表，可分别允许或拒绝每一项")
    }
    .padding(FangcunLayout.spacing(5))
    .fangcunLevelOneSurface()
  }
}
