// MARK: - Constants

extension RFC_5321.EmailAddress.LocalPart {
    package enum Limits {}
}

extension RFC_5321.EmailAddress.LocalPart.Limits {
    static let maxLength = 64  // Max length for local-part per RFC 5321
}
