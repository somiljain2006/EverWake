import SwiftUI

struct PomodoroTimerBadge: View {
    let timeText: String
        let isRunning: Bool

        var body: some View {
            Text(timeText)
                .font(.system(size: 60, weight: .light, design: .monospaced))
                .monospacedDigit()
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.6), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 6)
                .padding(.vertical, 0)
                .accessibilityLabel(isRunning ? "Timer running \(timeText)" : "Timer \(timeText)")
        }
}
