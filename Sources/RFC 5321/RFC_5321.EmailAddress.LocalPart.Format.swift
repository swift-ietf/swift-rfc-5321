// MARK: - Format

extension RFC_5321.EmailAddress.LocalPart {
    enum Format: Hashable, Codable {
        case dotAtom  // Regular unquoted format
        case quoted  // Quoted string format
    }
}
