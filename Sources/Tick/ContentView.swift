import SwiftUI

struct ContentView: View {
    @ObservedObject private var timer = TimerManager.shared

    @State private var inputMinutes: String = ""
    @State private var inputSeconds: String = ""
    @State private var inputNote: String = ""
    @State private var alwaysOnTop = false

    var body: some View {
        VStack(spacing: 0) {
            // Pin button row
            HStack {
                Spacer()
                Button {
                    alwaysOnTop.toggle()
                    setWindowLevel(alwaysOnTop ? .floating : .normal)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: alwaysOnTop ? "pin.fill" : "pin")
                            .font(.system(size: 12, weight: .medium))
                        Text(alwaysOnTop ? "Pinned" : "Pin")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(alwaysOnTop ? .accentColor : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(alwaysOnTop ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.08))
                    )
                }
                .buttonStyle(.plain)
                .help("Always on Top")
            }
            .padding(.top, 8)
            .padding(.trailing, 20)

            Spacer()

            // Progress ring
            CircularProgressView(
                progress: timer.progress,
                timeString: timer.timerState == .idle ? idleTimeString : timer.formattedTime,
                timerState: timer.timerState
            )

            Spacer()

            // Controls section
            VStack(spacing: 20) {
                presetButtons

                if timer.timerState == .idle {
                    noteInput
                    customInput
                } else if !timer.note.isEmpty {
                    Text(timer.note)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                controlButtons
            }
            .padding(.bottom, 32)
        }
        .frame(width: 380, height: 490)
        .background(KeyEventHandler(
            onSpace: handleSpace,
            onEscape: handleEscape,
            onReturn: handleReturn
        ))
    }

    // MARK: - Preset Buttons

    @State private var selectedPreset: TimerPreset?

    private var presetButtons: some View {
        HStack(spacing: 12) {
            ForEach(TimerPreset.defaults) { preset in
                Button(preset.label) {
                    selectedPreset = preset
                    inputMinutes = String(preset.minutes)
                    inputSeconds = "0"
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(selectedPreset?.minutes == preset.minutes ? .accentColor : nil)
                .disabled(timer.timerState != .idle)
            }
        }
    }

    // MARK: - Note Input

    private var noteInput: some View {
        TextField("备注（选填）", text: $inputNote)
            .textFieldStyle(.roundedBorder)
            .frame(width: 130)
            .multilineTextAlignment(.center)
            .font(.system(size: 13))
    }

    // MARK: - Custom Input

    private var customInput: some View {
        HStack(spacing: 8) {
            TextField("00", text: $inputMinutes)
                .textFieldStyle(.roundedBorder)
                .frame(width: 56)
                .multilineTextAlignment(.center)
                .onChange(of: inputMinutes) { newValue in
                    inputMinutes = filterNumericInput(newValue, max: 999)
                }

            Text(":")
                .font(.title3)
                .foregroundStyle(.tertiary)

            TextField("00", text: $inputSeconds)
                .textFieldStyle(.roundedBorder)
                .frame(width: 56)
                .multilineTextAlignment(.center)
                .onChange(of: inputSeconds) { newValue in
                    inputSeconds = filterNumericInput(newValue, max: 59)
                }
        }
    }

    // MARK: - Control Buttons

    private var controlButtons: some View {
        HStack(spacing: 14) {
            switch timer.timerState {
            case .idle:
                Button("Start") {
                    startFromInput()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!hasValidCustomInput)

            case .running:
                Button("Pause") {
                    timer.pause()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button("Cancel") {
                    timer.cancel()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.red)

            case .paused:
                Button("Resume") {
                    timer.resume()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Cancel") {
                    timer.cancel()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.red)
            }
        }
    }

    // MARK: - Helpers

    private var idleTimeString: String {
        let mins = Int(inputMinutes) ?? 0
        let secs = Int(inputSeconds) ?? 0
        return String(format: "%02d:%02d", mins, secs)
    }

    private var hasValidCustomInput: Bool {
        let mins = Int(inputMinutes) ?? 0
        let secs = Int(inputSeconds) ?? 0
        return (mins * 60 + secs) > 0
    }

    private func startFromInput() {
        let mins = Int(inputMinutes) ?? 0
        let secs = Int(inputSeconds) ?? 0
        timer.start(minutes: mins, seconds: secs, note: inputNote)
        inputMinutes = ""
        inputSeconds = ""
        inputNote = ""
        selectedPreset = nil
    }

    private func filterNumericInput(_ value: String, max: Int) -> String {
        let filtered = value.filter { $0.isNumber }
        if let num = Int(filtered), num > max {
            return String(max)
        }
        return filtered
    }

    private func setWindowLevel(_ level: NSWindow.Level) {
        for window in NSApp.windows where window.canBecomeKey {
            window.level = level
        }
    }

    // MARK: - Keyboard Handlers

    private func handleSpace() {
        switch timer.timerState {
        case .running: timer.pause()
        case .paused: timer.resume()
        case .idle: break
        }
    }

    private func handleEscape() {
        if timer.timerState != .idle {
            timer.cancel()
        }
    }

    private func handleReturn() {
        if timer.timerState == .idle && hasValidCustomInput {
            startFromInput()
        }
    }
}

// MARK: - Key Event Handler

struct KeyEventHandler: NSViewRepresentable {
    let onSpace: () -> Void
    let onEscape: () -> Void
    let onReturn: () -> Void

    func makeNSView(context: Context) -> KeyCaptureView {
        let view = KeyCaptureView()
        view.onSpace = onSpace
        view.onEscape = onEscape
        view.onReturn = onReturn
        return view
    }

    func updateNSView(_ nsView: KeyCaptureView, context: Context) {
        nsView.onSpace = onSpace
        nsView.onEscape = onEscape
        nsView.onReturn = onReturn
    }
}

class KeyCaptureView: NSView {
    var onSpace: (() -> Void)?
    var onEscape: (() -> Void)?
    var onReturn: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 49: // Space
            onSpace?()
        case 53: // Escape
            onEscape?()
        case 36: // Return
            onReturn?()
        default:
            super.keyDown(with: event)
        }
    }
}
