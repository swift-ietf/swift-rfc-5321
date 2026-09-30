import RFC_5321
import Testing

@Suite
struct `SMTP address length boundaries` {
    @Test
    func `a 64-byte local part is accepted`() throws {
        _ = try RFC_5321.EmailAddress.LocalPart(String(repeating: "a", count: 64))
    }

    @Test
    func `a local part with a trailing dot is refused`() {
        #expect(throws: RFC_5321.EmailAddress.LocalPart.Error.self) {
            try RFC_5321.EmailAddress.LocalPart("user.")
        }
    }

    @Test
    func `a 254-byte address is accepted and a 255-byte address is refused`() throws {
        let local = String(repeating: "a", count: 64)
        let label = String(repeating: "b", count: 63)
        let fits = "\(local)@\(label).\(label).\(String(repeating: "c", count: 61))"
        let over = "\(local)@\(label).\(label).\(String(repeating: "c", count: 62))"
        #expect(fits.utf8.count == 254)
        #expect(over.utf8.count == 255)
        _ = try RFC_5321.EmailAddress(fits)
        #expect(throws: RFC_5321.EmailAddress.Error.self) { try RFC_5321.EmailAddress(over) }
    }
}
