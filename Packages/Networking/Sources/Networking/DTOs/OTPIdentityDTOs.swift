public struct OTPIssueRequestDTO: Encodable, Sendable, Equatable {
    public let identifier: String

    public init(identifier: String) {
        self.identifier = identifier
    }
}

public struct OTPIssueResponseDTO: Decodable, Sendable, Equatable {
    public let cooldownSeconds: Int

    public init(cooldownSeconds: Int) {
        self.cooldownSeconds = cooldownSeconds
    }
}

public struct OTPVerifyRequestDTO: Encodable, Sendable, Equatable {
    public let identifier: String
    public let code: String

    public init(identifier: String, code: String) {
        self.identifier = identifier
        self.code = code
    }
}

public struct OTPVerifyResponseDTO: Decodable, Sendable, Equatable {
    public let status: String
    public let roles: [String]?

    public init(status: String, roles: [String]?) {
        self.status = status
        self.roles = roles
    }
}

public struct OTPCreateAccountRequestDTO: Encodable, Sendable, Equatable {
    public let identifier: String
    public let role: String

    public init(identifier: String, role: String) {
        self.identifier = identifier
        self.role = role
    }
}

public struct OTPCreateAccountResponseDTO: Decodable, Sendable, Equatable {
    public let role: String

    public init(role: String) {
        self.role = role
    }
}
