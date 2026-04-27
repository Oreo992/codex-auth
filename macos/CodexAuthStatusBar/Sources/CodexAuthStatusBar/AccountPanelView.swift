import CodexAuthStatusBarCore
import SwiftUI

struct AccountPanelView: View {
    @ObservedObject var store: AccountStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            if let message = store.errorMessage {
                ErrorLine(message: message)
            }
            accountList
        }
        .padding(12)
        .frame(width: 302, height: store.panelHeight)
        .liquidGlassSurface(cornerRadius: 22)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Codex Auth")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Text(activeSubtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                CompactIconButton(systemName: "arrow.clockwise", help: "Refresh locally") {
                    Task { await store.refresh(refreshFromAPI: false) }
                }
                .disabled(store.isLoading)

                CompactIconButton(systemName: "waveform.path.ecg", help: "Refresh usage from API") {
                    Task { await store.refresh(refreshFromAPI: true) }
                }
                .disabled(store.isLoading)
            }
        }
    }

    private var activeSubtitle: String {
        if store.isLoading { return "Refreshing..." }
        guard let row = store.activeRow else { return "No active account" }
        return row.switchSelector
    }

    private var accountList: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                if store.rows.isEmpty, !store.isLoading {
                    Text("No accounts")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 110)
                }

                ForEach(store.rows) { row in
                    AccountRowView(
                        row: row,
                        isSwitching: store.switchingIndex == row.index,
                        action: {
                            Task { await store.switchTo(row) }
                        }
                    )
                }
            }
            .padding(.vertical, 1)
        }
        .scrollIndicators(.hidden)
    }
}

private struct ErrorLine: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.red)
            .lineLimit(2)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}

private struct CompactIconButton: View {
    let systemName: String
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .medium))
                .frame(width: 27, height: 24)
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary.opacity(0.82))
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .help(help)
    }
}

private struct AccountRowView: View {
    let row: AccountRow
    let isSwitching: Bool
    let action: () -> Void

    var body: some View {
        Button {
            if !row.isActive {
                action()
            }
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(row.isActive ? Color.green : Color.secondary.opacity(0.24))
                    .frame(width: 5, height: 5)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 5) {
                        Text(row.switchSelector)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.primary.opacity(0.86))
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Text(row.plan)
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(.regularMaterial, in: Capsule())
                    }

                    HStack(spacing: 8) {
                        MiniUsageBar(label: "5h", value: row.fiveHourUsage)
                        MiniUsageBar(label: "wk", value: row.weeklyUsage)
                    }
                }

                Spacer(minLength: 4)

                RowAccessory(isActive: row.isActive, isSwitching: isSwitching)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(row.isActive ? "Active account" : "Switch to \(row.switchSelector)")
        .disabled(isSwitching)
        .liquidGlassRow(active: row.isActive)
    }
}

private struct RowAccessory: View {
    let isActive: Bool
    let isSwitching: Bool

    var body: some View {
        Group {
            if isSwitching {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: isActive ? "checkmark.circle.fill" : "arrow.right.circle")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isActive ? .green : .secondary)
            }
        }
        .frame(width: 16, height: 16)
    }
}

private struct MiniUsageBar: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 15, alignment: .leading)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.13))
                    Capsule()
                        .fill(progressTint)
                        .frame(width: proxy.size.width * (fraction ?? 0))
                }
            }
            .frame(height: 3)

            Text(value.isEmpty ? "-" : compactValue(value))
                .font(.system(size: 8, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 25, alignment: .trailing)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private var fraction: Double? {
        let percentText = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")
            .first
            .map(String.init) ?? value
        guard percentText.hasSuffix("%") else { return nil }
        guard let percent = Double(percentText.dropLast()) else { return nil }
        return max(0, min(percent / 100, 1))
    }

    private var progressTint: Color {
        guard let fraction else { return .secondary.opacity(0.26) }
        if fraction < 0.20 { return .red.opacity(0.72) }
        if fraction < 0.50 { return .yellow.opacity(0.76) }
        return .green.opacity(0.66)
    }

    private func compactValue(_ value: String) -> String {
        let first = value.split(separator: " ").first.map(String.init) ?? value
        return first.isEmpty ? "-" : first
    }
}

private extension View {
    func liquidGlassSurface(cornerRadius: CGFloat) -> some View {
        modifier(LiquidGlassSurface(cornerRadius: cornerRadius))
    }

    func liquidGlassRow(active: Bool) -> some View {
        modifier(LiquidGlassRow(active: active))
    }
}

private struct LiquidGlassSurface: ViewModifier {
    let cornerRadius: CGFloat

    @ViewBuilder
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(macOS 26.0, *) {
            content
                .glassEffect(.clear.interactive(), in: shape)
                .overlay {
                    shape.strokeBorder(.white.opacity(0.22), lineWidth: 0.55)
                }
                .shadow(color: .black.opacity(0.08), radius: 16, y: 9)
        } else {
            content
                .background(.ultraThinMaterial, in: shape)
                .overlay {
                    shape.strokeBorder(.white.opacity(0.24), lineWidth: 0.6)
                }
                .shadow(color: .black.opacity(0.09), radius: 18, y: 10)
                .clipShape(shape)
        }
    }
}

private struct LiquidGlassRow: ViewModifier {
    let active: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        if #available(macOS 26.0, *) {
            content
                .glassEffect(glass, in: shape)
                .overlay {
                    shape.strokeBorder(.white.opacity(active ? 0.22 : 0.12), lineWidth: 0.5)
                }
        } else {
            content
                .background(active ? AnyShapeStyle(Color.green.opacity(0.085)) : AnyShapeStyle(.ultraThinMaterial), in: shape)
                .overlay {
                    shape.strokeBorder(.white.opacity(active ? 0.20 : 0.12), lineWidth: 0.55)
                }
        }
    }

    @available(macOS 26.0, *)
    private var glass: Glass {
        active ? .clear.tint(.green.opacity(0.08)).interactive() : .clear.interactive()
    }
}
