import Foundation

struct TimerPreset: Identifiable {
    let id = UUID()
    let label: String
    let minutes: Int

    static let defaults: [TimerPreset] = [
        TimerPreset(label: "5 min", minutes: 5),
        TimerPreset(label: "10 min", minutes: 10),
        TimerPreset(label: "15 min", minutes: 15),
        TimerPreset(label: "25 min", minutes: 25),
    ]
}
