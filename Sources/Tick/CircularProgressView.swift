import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    let timeString: String
    let timerState: TimerState

    @State private var isPulse = false

    private var ringColor: Color {
        switch timerState {
        case .running:
            return .accentColor
        case .paused:
            return .orange
        case .idle:
            return .gray
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: 12)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
                .opacity(timerState == .paused ? (isPulse ? 0.4 : 1.0) : 1.0)

            Text(timeString)
                .font(.system(size: 48, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)
                .opacity(timerState == .paused ? (isPulse ? 0.4 : 1.0) : 1.0)
        }
        .frame(width: 200, height: 200)
        .onChange(of: timerState) { newState in
            if newState == .paused {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isPulse = true
                }
            } else {
                withAnimation(.default) {
                    isPulse = false
                }
            }
        }
    }
}
