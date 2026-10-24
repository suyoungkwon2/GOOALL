import Foundation
import SwiftUI
import Testing
import UIKit
import WidgetKit
@testable import GOOALL

/// F05-R5 타임라인
struct WidgetTimelineTests {

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        return cal
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
    }

    private func snapshot(period: GoalPeriod, value: Int, at now: Date) -> ProgressSnapshot {
        let target = period == .daily ? 10_000 : 70_000
        return ProgressEngine.makeSnapshot(
            value: value, todayValue: value,
            settings: GoalSettings(metric: .steps, period: period, target: target, themeID: "sixpack"),
            stageCount: 11, now: now, calendar: calendar
        )
    }

    @Test func dailyTimelineHasCurrentAndMidnightReset() {
        let stored = snapshot(period: .daily, value: 6_240, at: date(2026, 10, 24, 15))
        let entries = ProgressEngine.timelineSnapshots(from: stored, now: date(2026, 10, 24, 16), calendar: calendar)
        #expect(entries.count == 2)
        #expect(entries[0].stage == 6)
        #expect(entries[1].periodStart == date(2026, 10, 25))
        #expect(entries[1].value == 0)
        #expect(entries[1].stage == 0)
    }

    @Test func weeklyTimelineResetsOnSunday() {
        let stored = snapshot(period: .weekly, value: 30_000, at: date(2026, 10, 21, 12))
        let entries = ProgressEngine.timelineSnapshots(from: stored, now: date(2026, 10, 22, 9), calendar: calendar)
        #expect(entries[0].value == 30_000)
        #expect(entries[1].periodStart == date(2026, 10, 25))
    }

    @Test func staleSnapshotIsShownAsZeroForCurrentPeriod() {
        // 어제 저장된 스냅샷 → 오늘은 0
        let yesterday = snapshot(period: .daily, value: 9_000, at: date(2026, 10, 23, 20))
        let entries = ProgressEngine.timelineSnapshots(from: yesterday, now: date(2026, 10, 24, 9), calendar: calendar)
        #expect(entries[0].value == 0)
        #expect(entries[0].periodStart == date(2026, 10, 24))
        #expect(entries[1].periodStart == date(2026, 10, 25))

        // 며칠 전 스냅샷도 지금 기간으로 맞춘다
        let old = snapshot(period: .daily, value: 9_000, at: date(2026, 10, 18, 20))
        let oldEntries = ProgressEngine.timelineSnapshots(from: old, now: date(2026, 10, 24, 9), calendar: calendar)
        #expect(oldEntries[0].periodStart == date(2026, 10, 24))
        #expect(oldEntries[0].value == 0)
    }
}

/// F05 수용 기준: 단계 0 / 5 / 마지막 × (Large, Medium, 잠금화면) 화면 확인용 렌더.
/// 환경변수 SNAPSHOT_DIR(xcodebuild에서는 TEST_RUNNER_SNAPSHOT_DIR)가 있으면 PNG로 저장한다.
@MainActor
struct WidgetRenderTests {

    private static let sizes: [(name: String, family: WidgetFamily, size: CGSize)] = [
        ("large", .systemLarge, CGSize(width: 364, height: 382)),
        ("medium", .systemMedium, CGSize(width: 364, height: 170)),
        ("lock", .accessoryRectangular, CGSize(width: 172, height: 76)),
    ]

    @Test(arguments: ["sixpack", "eyeglow"], [0, 5, 10])
    func renderAllFamilies(themeID: String, stage: Int) throws {
        for entry in Self.sizes {
            try render(
                GoalWidgetContent(snapshot: .sample(themeID: themeID, stage: stage), family: entry.family),
                size: entry.size,
                lockScreen: entry.family == .accessoryRectangular,
                name: "\(themeID)_\(entry.name)_\(stage)"
            )
        }
    }

    @Test(arguments: [ColorScheme.light, .dark])
    func renderEmptyState(scheme: ColorScheme) throws {
        try render(
            GoalWidgetContent(snapshot: nil, family: .systemLarge),
            size: CGSize(width: 364, height: 382),
            lockScreen: false,
            scheme: scheme,
            name: "empty_large_\(scheme == .dark ? "dark" : "light")"
        )
    }

    private func render(_ view: some View, size: CGSize, lockScreen: Bool, scheme: ColorScheme = .light, name: String) throws {
        let framed = view
            .frame(width: size.width, height: size.height)
            .background(lockScreen ? Color.black : Color(.systemBackground))
            .foregroundStyle(lockScreen ? Color.white : Color.primary)
            .clipShape(.rect(cornerRadius: lockScreen ? 8 : 24))
            .environment(\.colorScheme, lockScreen ? .dark : scheme)
        let renderer = ImageRenderer(content: framed)
        renderer.scale = 2
        let image = try #require(renderer.uiImage)
        #expect(image.size == size)
        if let dir = ProcessInfo.processInfo.environment["SNAPSHOT_DIR"], let png = image.pngData() {
            let url = URL(fileURLWithPath: dir)
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            try png.write(to: url.appendingPathComponent("\(name).png"))
        }
    }
}
