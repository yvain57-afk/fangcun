import SwiftUI
import WidgetKit

struct ProbeEntry: TimelineEntry { let date: Date }
struct ProbeProvider: TimelineProvider {
  func placeholder(in context: Context) -> ProbeEntry { ProbeEntry(date: .now) }
  func getSnapshot(in context: Context, completion: @escaping (ProbeEntry) -> Void) {
    completion(ProbeEntry(date: .now))
  }
  func getTimeline(in context: Context, completion: @escaping (Timeline<ProbeEntry>) -> Void) {
    completion(Timeline(entries: [ProbeEntry(date: .now)], policy: .never))
  }
}
@main
struct WidgetProbe: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "FangcunM0Probe", provider: ProbeProvider()) { entry in
      Text("Probe").containerBackground(.background, for: .widget)
    }.supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular, .accessoryInline])
  }
}
