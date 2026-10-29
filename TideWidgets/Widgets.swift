import SwiftUI
import TideCore
import WidgetKit

struct ScoreSmallWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "jp.tide.app.widget.score", provider: TideTimelineProvider()) { entry in
            WidgetScoreSmallView(snapshot: entry.snapshot, now: entry.date)
                .containerBackground(DesignTokens.Colors.surface, for: .widget)
                .widgetURL(DeepLink.home.url)
        }
        .configurationDisplayName("釣れ率")
        .description("最寄りの釣り場の釣れ率")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

struct HoursSmallWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "jp.tide.app.widget.hours", provider: TideTimelineProvider()) { entry in
            WidgetHoursSmallView(snapshot: entry.snapshot, now: entry.date)
                .containerBackground(DesignTokens.Colors.surface, for: .widget)
                .widgetURL(DeepLink.catchScreen.url)
        }
        .configurationDisplayName("24時間")
        .description("潮回りと時間ごとの釣れ率")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

struct ConditionsMediumWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "jp.tide.app.widget.conditions", provider: TideTimelineProvider()) { entry in
            WidgetMediumView(snapshot: entry.snapshot, now: entry.date)
                .containerBackground(DesignTokens.Colors.surface, for: .widget)
        }
        .configurationDisplayName("釣れ率と条件")
        .description("釣れ率、風・波・水温・気圧")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}
