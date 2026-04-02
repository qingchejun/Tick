import AppKit
import SwiftUI

@MainActor
final class AlertPanel {
    private var panel: NSPanel?

    func show(note: String) {
        close()

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 0),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .screenSaver
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true

        let content = AlertContentView(note: note) { [weak self] in
            NotificationManager.shared.stopSound()
            self?.close()
        }

        let hostingView = NSHostingView(rootView: content)
        hostingView.frame = NSRect(x: 0, y: 0, width: 320, height: 1)
        hostingView.setFrameSize(hostingView.fittingSize)
        panel.setContentSize(hostingView.fittingSize)
        panel.contentView = hostingView

        panel.center()
        panel.makeKeyAndOrderFront(nil)

        self.panel = panel
    }

    func close() {
        panel?.close()
        panel = nil
    }
}

// MARK: - Alert Content

struct AlertContentView: View {
    let note: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 36))
                .foregroundStyle(.orange)
                .padding(.top, 4)

            Text("Time's up!")
                .font(.system(size: 24, weight: .semibold))

            if !note.isEmpty {
                Text(note)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }

            Button {
                onDismiss()
            } label: {
                Text("Dismiss")
                    .frame(width: 120)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 28)
        .frame(width: 320)
        .background(
            VisualEffectBackground()
                .clipShape(RoundedRectangle(cornerRadius: 16))
        )
    }
}

struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.state = .active
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
