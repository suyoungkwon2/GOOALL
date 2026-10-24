//
//  widget.swift
//  widget
//
//  Created by Mel Kwon on 10/24/26.
//

import WidgetKit
import SwiftUI

struct GoalEntry: TimelineEntry {
    let date: Date
    let snapshot: ProgressSnapshot?
}

/// App Group 스냅샷만 읽는다 (F05-R4). 타임라인 = 현재 + 리셋 엔트리, 1시간 후 재요청 (F05-R5).
struct GoalProvider: TimelineProvider {
    func placeholder(in context: Context) -> GoalEntry {
        GoalEntry(date: .now, snapshot: .sample(stage: 5))
    }

    func getSnapshot(in context: Context, completion: @escaping (GoalEntry) -> Void) {
        let stored = SharedStore.shared.progressSnapshot
        // 위젯 갤러리에서는 데이터가 없어도 샘플로 보여준다
        completion(GoalEntry(date: .now, snapshot: stored ?? (context.isPreview ? .sample(stage: 5) : nil)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GoalEntry>) -> Void) {
        let now = Date()
        let refresh = now.addingTimeInterval(60 * 60)
        guard let stored = SharedStore.shared.progressSnapshot else {
            completion(Timeline(entries: [GoalEntry(date: now, snapshot: nil)], policy: .after(refresh)))
            return
        }
        let snapshots = ProgressEngine.timelineSnapshots(from: stored, now: now, calendar: .current)
        let entries = [GoalEntry(date: now, snapshot: snapshots[0])]
            + snapshots.dropFirst().map { GoalEntry(date: $0.periodStart, snapshot: $0) }
        completion(Timeline(entries: entries, policy: .after(refresh)))
    }
}

struct GoalWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: GoalEntry

    var body: some View {
        GoalWidgetContent(snapshot: entry.snapshot, family: family)
            .containerBackground(for: .widget) {
                if family == .accessoryRectangular {
                    Color.clear
                } else {
                    Color(.systemBackground)
                }
            }
    }
}

struct GoalWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: AppConstants.widgetKind, provider: GoalProvider()) { entry in
            GoalWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(AppConstants.appName)
        .description("Watch your glow-up happen, one step at a time.")
        .supportedFamilies([.systemLarge, .systemMedium, .accessoryRectangular])
        // 이미지가 여백 없이 위젯을 꽉 채우도록
        .contentMarginsDisabled()
    }
}

#Preview(as: .systemLarge) {
    GoalWidget()
} timeline: {
    GoalEntry(date: .now, snapshot: .sample(stage: 0))
    GoalEntry(date: .now, snapshot: .sample(stage: 5))
    GoalEntry(date: .now, snapshot: .sample(stage: 10))
    GoalEntry(date: .now, snapshot: nil)
}

#Preview(as: .systemMedium) {
    GoalWidget()
} timeline: {
    GoalEntry(date: .now, snapshot: .sample(themeID: "eyeglow", stage: 0))
    GoalEntry(date: .now, snapshot: .sample(themeID: "eyeglow", stage: 5))
    GoalEntry(date: .now, snapshot: .sample(themeID: "eyeglow", stage: 10))
}

#Preview(as: .accessoryRectangular) {
    GoalWidget()
} timeline: {
    GoalEntry(date: .now, snapshot: .sample(stage: 0))
    GoalEntry(date: .now, snapshot: .sample(stage: 5))
    GoalEntry(date: .now, snapshot: .sample(stage: 10))
}
