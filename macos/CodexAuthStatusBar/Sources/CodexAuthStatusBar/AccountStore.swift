import CodexAuthStatusBarCore
import Foundation

@MainActor
final class AccountStore: ObservableObject {
    @Published private(set) var rows: [AccountRow] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var switchingIndex: String?
    @Published private(set) var isAddingAccount = false
    @Published private(set) var panelHeight: Double = 150

    var onActiveSummaryChange: ((String) -> Void)?
    var onPanelHeightChange: ((Double) -> Void)?

    private let cli: CodexAuthCLI?

    init() {
        cli = try? CodexAuthCLI()
        if cli == nil {
            errorMessage = CodexAuthCLIError.executableNotFound.localizedDescription
        }
        updatePanelHeight()
    }

    var activeRow: AccountRow? {
        rows.first(where: \.isActive)
    }

    func refresh(refreshFromAPI: Bool) async {
        guard let cli else { return }
        isLoading = true
        errorMessage = nil
        do {
            rows = try await cli.list(refreshFromAPI: refreshFromAPI)
            lastUpdated = Date()
            updateStatusTitle()
        } catch {
            errorMessage = error.localizedDescription
            updateStatusTitle()
        }
        isLoading = false
        updatePanelHeight()
    }

    func switchTo(_ row: AccountRow) async {
        guard let cli else { return }
        switchingIndex = row.index
        errorMessage = nil
        do {
            try await cli.switchAccount(selector: row.switchSelector)
            await refresh(refreshFromAPI: false)
        } catch {
            errorMessage = error.localizedDescription
        }
        switchingIndex = nil
        updatePanelHeight()
    }

    func addAccount() async {
        guard let cli else { return }
        isAddingAccount = true
        errorMessage = nil
        do {
            try await cli.login()
            await refresh(refreshFromAPI: false)
        } catch {
            errorMessage = error.localizedDescription
            updateStatusTitle()
        }
        isAddingAccount = false
        updatePanelHeight()
    }

    private func updateStatusTitle() {
        guard let activeRow else {
            onActiveSummaryChange?("Codex Auth")
            return
        }
        if activeRow.fiveHourUsage == "-" || activeRow.fiveHourUsage.isEmpty {
            onActiveSummaryChange?("Codex Auth: \(activeRow.account)")
        } else {
            onActiveSummaryChange?("Codex Auth: \(activeRow.account) · 5h \(activeRow.fiveHourUsage)")
        }
    }

    private func updatePanelHeight() {
        let visibleRows = rows.isEmpty ? 1 : min(rows.count, 4)
        let listHeight = rows.isEmpty ? 108 : Double(visibleRows * 54 + max(visibleRows - 1, 0) * 6 + 2)
        let errorHeight = errorMessage == nil ? 0 : 38
        let errorSpacing = errorMessage == nil ? 0 : 10
        let contentHeight = 24 + 36 + 10 + Double(errorHeight + errorSpacing) + listHeight
        let nextHeight = min(max(contentHeight, 142), 336)
        panelHeight = nextHeight
        onPanelHeightChange?(nextHeight)
    }
}
