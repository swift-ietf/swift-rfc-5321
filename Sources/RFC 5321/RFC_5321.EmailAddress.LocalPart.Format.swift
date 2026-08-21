extension RFC_5321.EmailAddress.LocalPart {
    enum Format: Hashable, Codable {
        case dotAtom
        case quoted
    }
}
