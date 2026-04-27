import Foundation

public struct AccountRow: Identifiable, Equatable, Sendable {
    public var id: String { index }

    public let index: String
    public let account: String
    public let group: String?
    public let plan: String
    public let fiveHourUsage: String
    public let weeklyUsage: String
    public let lastActivity: String
    public let isActive: Bool
    public var switchSelector: String { group ?? account }

    public init(
        index: String,
        account: String,
        group: String?,
        plan: String,
        fiveHourUsage: String,
        weeklyUsage: String,
        lastActivity: String,
        isActive: Bool
    ) {
        self.index = index
        self.account = account
        self.group = group
        self.plan = plan
        self.fiveHourUsage = fiveHourUsage
        self.weeklyUsage = weeklyUsage
        self.lastActivity = lastActivity
        self.isActive = isActive
    }
}

public enum AccountListParser {
    public static func parse(_ output: String) -> [AccountRow] {
        let lines = output.split(whereSeparator: \.isNewline).map(String.init)
        guard let headerIndex = lines.firstIndex(where: { $0.contains("ACCOUNT") && $0.contains("PLAN") }) else {
            return []
        }

        let header = lines[headerIndex]
        guard
            let accountStart = header.range(of: "ACCOUNT")?.lowerBound.utf16Offset(in: header),
            let planStart = header.range(of: "PLAN")?.lowerBound.utf16Offset(in: header),
            let fiveHourStart = header.range(of: "5H")?.lowerBound.utf16Offset(in: header),
            let weeklyStart = header.range(of: "WEEKLY")?.lowerBound.utf16Offset(in: header),
            let lastStart = header.range(of: "LAST")?.lowerBound.utf16Offset(in: header)
        else {
            return []
        }

        var group: String?
        var rows: [AccountRow] = []

        for line in lines.dropFirst(headerIndex + 1) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.allSatisfy({ $0 == "-" }) else { continue }

            let prefix = line.slice(accountStart: 0, end: accountStart)
            let account = line.slice(accountStart: accountStart, end: planStart)
                .trimmingCharacters(in: .whitespaces)
            let plan = line.slice(accountStart: planStart, end: fiveHourStart)
                .trimmingCharacters(in: .whitespaces)
            let fiveHour = line.slice(accountStart: fiveHourStart, end: weeklyStart)
                .trimmingCharacters(in: .whitespaces)
            let weekly = line.slice(accountStart: weeklyStart, end: lastStart)
                .trimmingCharacters(in: .whitespaces)
            let last = line.slice(accountStart: lastStart, end: nil)
                .trimmingCharacters(in: .whitespaces)

            if let index = rowIndex(in: prefix), !account.isEmpty {
                rows.append(AccountRow(
                    index: index,
                    account: account,
                    group: group,
                    plan: plan,
                    fiveHourUsage: fiveHour,
                    weeklyUsage: weekly,
                    lastActivity: last,
                    isActive: prefix.contains("*")
                ))
            } else if !account.isEmpty, plan.isEmpty, fiveHour.isEmpty, weekly.isEmpty, last.isEmpty {
                group = account
            }
        }

        return rows
    }

    private static func rowIndex(in prefix: String) -> String? {
        let digits = prefix.filter(\.isNumber)
        return digits.isEmpty ? nil : digits
    }
}

private extension String {
    func slice(accountStart start: Int, end: Int?) -> String {
        let safeStart = Swift.max(0, Swift.min(start, count))
        let safeEnd = Swift.max(safeStart, Swift.min(end ?? count, count))
        let startIndex = index(self.startIndex, offsetBy: safeStart)
        let endIndex = index(self.startIndex, offsetBy: safeEnd)
        return String(self[startIndex..<endIndex])
    }
}
