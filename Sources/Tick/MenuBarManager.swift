import AppKit
import SwiftUI
import Combine

@MainActor
final class MenuBarManager: NSObject {
    private var statusItem: NSStatusItem?
    private let timerManager: TimerManager
    private var cancellables = Set<AnyCancellable>()
    private var blinkTimer: Timer?
    private var blinkVisible = true
    private var popover: NSPopover?

    init(timerManager: TimerManager) {
        self.timerManager = timerManager
        super.init()
        setupStatusItem()
        observeTimer()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Tick")
            button.target = self
            button.action = #selector(statusBarClicked)
        }
    }

    @objc private func statusBarClicked() {
        if let popover, popover.isShown {
            popover.performClose(nil)
            return
        }

        let pop = NSPopover()
        pop.behavior = .transient
        pop.contentSize = NSSize(width: 220, height: 0)
        pop.contentViewController = NSHostingController(
            rootView: MenuBarPopoverView(timerManager: timerManager) {
                pop.performClose(nil)
            }
        )

        if let button = statusItem?.button {
            pop.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
        popover = pop
    }

    private func observeTimer() {
        timerManager.$remainingSeconds
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateDisplay()
            }
            .store(in: &cancellables)

        timerManager.$timerState
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateDisplay()
                self?.updateBlink()
            }
            .store(in: &cancellables)
    }

    private func updateDisplay() {
        guard let button = statusItem?.button else { return }

        switch timerManager.timerState {
        case .idle:
            button.title = ""
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Tick")
            button.contentTintColor = nil

        case .running:
            button.image = nil
            button.title = timerManager.formattedTime
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 0, weight: .regular)
            button.contentTintColor = nil

        case .paused:
            button.image = NSImage(systemSymbolName: "pause.circle", accessibilityDescription: "Paused")
            button.title = " \(timerManager.formattedTime)"
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 0, weight: .regular)
        }
    }

    private func updateBlink() {
        blinkTimer?.invalidate()
        blinkTimer = nil
        blinkVisible = true

        if timerManager.timerState == .paused {
            blinkTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    guard let self, let button = self.statusItem?.button else { return }
                    self.blinkVisible.toggle()
                    button.appearsDisabled = !self.blinkVisible
                }
            }
        } else {
            statusItem?.button?.appearsDisabled = false
        }
    }
}

// MARK: - Popover Content

struct MenuBarPopoverView: View {
    @ObservedObject var timerManager: TimerManager
    let dismiss: () -> Void

    @State private var customMinutes: String = ""

    var body: some View {
        VStack(spacing: 0) {
            if timerManager.timerState == .idle {
                idleContent
            } else {
                runningContent
            }

            Divider()

            Button {
                dismiss()
                NSApp.activate(ignoringOtherApps: true)
                for window in NSApp.windows where window.canBecomeKey {
                    window.makeKeyAndOrderFront(nil)
                    return
                }
            } label: {
                Text("Open Tick")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Button {
                NSApp.terminate(nil)
            } label: {
                HStack {
                    Text("Quit Tick")
                    Spacer()
                    Text("⌘Q")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .padding(.vertical, 8)
        .frame(width: 220)
    }

    private var idleContent: some View {
        VStack(spacing: 0) {
            ForEach(TimerPreset.defaults) { preset in
                Button {
                    timerManager.start(minutes: preset.minutes, seconds: 0)
                    dismiss()
                } label: {
                    Text("Start \(preset.label)")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            Divider()
                .padding(.vertical, 4)

            HStack(spacing: 8) {
                TextField("Minutes", text: $customMinutes)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .multilineTextAlignment(.center)
                    .onSubmit {
                        if let mins = Int(customMinutes), mins > 0 {
                            timerManager.start(minutes: mins, seconds: 0)
                            customMinutes = ""
                            dismiss()
                        }
                    }

                Text("min")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Divider()
                .padding(.vertical, 4)
        }
    }

    private var runningContent: some View {
        VStack(spacing: 0) {
            if !timerManager.note.isEmpty {
                Text(timerManager.note)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)

                Divider()
                    .padding(.vertical, 4)
            }

            if timerManager.timerState == .running {
                Button {
                    timerManager.pause()
                    dismiss()
                } label: {
                    Text("Pause")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            } else {
                Button {
                    timerManager.resume()
                    dismiss()
                } label: {
                    Text("Resume")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            Button {
                timerManager.cancel()
                dismiss()
            } label: {
                Text("Cancel")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Divider()
                .padding(.vertical, 4)
        }
    }
}
