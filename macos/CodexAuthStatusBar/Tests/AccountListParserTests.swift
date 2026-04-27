import CodexAuthStatusBarCore
import Foundation

@main
enum AccountListParserSelfTest {
    static func main() {
        parsesCodexAuthListRows()
        parsesGroupedAccountLabels()
        emptyOutputReturnsNoRows()
        print("CodexAuthStatusBarSelfTest passed")
    }

    private static func parsesCodexAuthListRows() {
        let output = """
             ACCOUNT                 PLAN  5H USAGE  WEEKLY USAGE  LAST ACTIVITY
        -------------------------------------------------------------------------
        * 01 personal@example.com    Plus  78%       42%           2m ago
          02 work@example.com        Team  100%      91%           1h ago
        """

        let rows = AccountListParser.parse(output)

        expect(rows.count == 2, "expected two account rows")
        expect(rows[0].index == "01", "expected first row index")
        expect(rows[0].account == "personal@example.com", "expected first row account")
        expect(rows[0].plan == "Plus", "expected first row plan")
        expect(rows[0].fiveHourUsage == "78%", "expected first row 5h usage")
        expect(rows[0].weeklyUsage == "42%", "expected first row weekly usage")
        expect(rows[0].lastActivity == "2m ago", "expected first row last activity")
        expect(rows[0].isActive, "expected first row to be active")
        expect(rows[1].index == "02", "expected second row index")
        expect(rows[1].account == "work@example.com", "expected second row account")
        expect(rows[1].plan == "Team", "expected second row plan")
        expect(!rows[1].isActive, "expected second row to be inactive")
    }

    private static func parsesGroupedAccountLabels() {
        let output = """
             ACCOUNT                 PLAN  5H USAGE  WEEKLY USAGE  LAST ACTIVITY
        -------------------------------------------------------------------------
             shared@example.com
        * 01   Work Workspace        Team  64%       88%           4m ago
          02   Personal Workspace    Plus  -         -             -
        """

        let rows = AccountListParser.parse(output)

        expect(rows.count == 2, "expected two grouped account rows")
        expect(rows[0].account == "Work Workspace", "expected first grouped label")
        expect(rows[0].group == "shared@example.com", "expected first grouped parent")
        expect(rows[0].switchSelector == "shared@example.com", "expected grouped selector to use email")
        expect(rows[0].isActive, "expected first grouped row to be active")
        expect(rows[1].account == "Personal Workspace", "expected second grouped label")
        expect(rows[1].group == "shared@example.com", "expected second grouped parent")
    }

    private static func emptyOutputReturnsNoRows() {
        expect(AccountListParser.parse("").isEmpty, "expected empty output to return no rows")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        if !condition() {
            fputs("Self-test failed: \(message)\n", stderr)
            Foundation.exit(1)
        }
    }
}
