import SwiftUI
import MuesliCore

struct StatsHeaderView: View {
    let dictationStats: DictationStats
    let meetingStats: MeetingStats

    var body: some View {
        HStack(spacing: MuesliTheme.spacing12) {
            StatCard(
                icon: "flame.fill",
                iconColor: .orange,
                value: "\(dictationStats.currentStreakDays)",
                label: "day streak"
            )
            StatCard(
                icon: "character.cursor.ibeam",
                iconColor: MuesliTheme.accent,
                value: formatWordCount(dictationStats.totalWords),
                label: "words dictated"
            )
            StatCard(
                icon: "gauge.with.dots.needle.33percent",
                iconColor: MuesliTheme.success,
                value: String(format: "%.0f", dictationStats.averageWPM),
                label: "avg WPM"
            )
            StatCard(
                icon: "person.2.fill",
                iconColor: MuesliTheme.accent,
                value: "\(meetingStats.totalMeetings)",
                label: "meetings"
            )
        }
        .padding(.horizontal, MuesliTheme.spacing24)
        .padding(.vertical, MuesliTheme.spacing20)
    }

    private func formatWordCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000.0)
        }
        return "\(count)"
    }
}

private struct StatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    @State private var isHovered = false

    var body: some View {
        VStack(spacing: MuesliTheme.spacing8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(iconColor)
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(MuesliTheme.textPrimary)
                .contentTransition(.numericText())
            Text(label)
                .font(MuesliTheme.caption())
                .foregroundStyle(MuesliTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(MuesliTheme.spacing16)
        .background(
            RoundedRectangle(cornerRadius: MuesliTheme.cornerMedium)
                .fill(isHovered ? MuesliTheme.backgroundHover : MuesliTheme.backgroundRaised)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MuesliTheme.cornerMedium)
                .strokeBorder(MuesliTheme.surfaceBorder, lineWidth: 0.5)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(MuesliTheme.springSnappy) {
                isHovered = hovering
            }
        }
    }
}
