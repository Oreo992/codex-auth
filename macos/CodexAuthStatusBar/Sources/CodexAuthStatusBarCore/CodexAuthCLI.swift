import Foundation

public struct CommandResult: Sendable {
    public let status: Int32
    public let output: String
    public let errorOutput: String
}

public enum CodexAuthCLIError: Error, LocalizedError, Sendable {
    case executableNotFound
    case commandFailed(String)

    public var errorDescription: String? {
        switch self {
        case .executableNotFound:
            "codex-auth was not found. Install @loongphy/codex-auth or set CODEX_AUTH_BIN."
        case .commandFailed(let message):
            message
        }
    }
}

public protocol CommandRunning: Sendable {
    func run(arguments: [String]) async throws -> CommandResult
}

public struct CodexAuthCLI: CommandRunning {
    private let executable: String

    public init(executable: String? = ProcessInfo.processInfo.environment["CODEX_AUTH_BIN"]) throws {
        guard let resolved = executable ?? Self.findExecutable() else {
            throw CodexAuthCLIError.executableNotFound
        }
        self.executable = resolved
    }

    public func run(arguments: [String]) async throws -> CommandResult {
        try await Task.detached {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            process.environment = Self.processEnvironment()

            let output = Pipe()
            let errorOutput = Pipe()
            process.standardOutput = output
            process.standardError = errorOutput

            try process.run()
            process.waitUntilExit()

            let outputText = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let errorText = String(data: errorOutput.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

            return CommandResult(status: process.terminationStatus, output: outputText, errorOutput: errorText)
        }.value
    }

    public func list(refreshFromAPI: Bool) async throws -> [AccountRow] {
        let args = refreshFromAPI ? ["list", "--api"] : ["list", "--skip-api"]
        let result = try await run(arguments: args)
        guard result.status == 0 else {
            throw CodexAuthCLIError.commandFailed(Self.message(from: result))
        }
        return AccountListParser.parse(result.output)
    }

    public func switchAccount(selector: String) async throws {
        let result = try await run(arguments: ["switch", selector])
        guard result.status == 0 else {
            throw CodexAuthCLIError.commandFailed(Self.message(from: result))
        }
    }

    public func login() async throws {
        let result = try await run(arguments: Self.loginArguments())
        guard result.status == 0 else {
            throw CodexAuthCLIError.commandFailed(Self.message(from: result))
        }
    }

    public static func loginArguments() -> [String] {
        ["login"]
    }

    private static func findExecutable() -> String? {
        let environment = ProcessInfo.processInfo.environment
        var candidates: [String] = []

        if let path = environment["PATH"] {
            candidates.append(contentsOf: path.split(separator: ":").map { "\($0)/codex-auth" })
        }
        if let home = environment["HOME"] {
            candidates.append("\(home)/.npm-global/bin/codex-auth")
            candidates.append("\(home)/.local/bin/codex-auth")
        }
        candidates.append("/opt/homebrew/bin/codex-auth")
        candidates.append("/usr/local/bin/codex-auth")

        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private static func processEnvironment() -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        environment["NO_COLOR"] = "1"
        environment["CODEX_AUTH_SKIP_SERVICE_RECONCILE"] = "1"
        return environment
    }

    private static func message(from result: CommandResult) -> String {
        let message = result.errorOutput.isEmpty ? result.output : result.errorOutput
        return message.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
