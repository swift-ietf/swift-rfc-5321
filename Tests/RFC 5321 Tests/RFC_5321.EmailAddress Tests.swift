import RFC_1123
import RFC_5321
import Testing

@Suite
struct `RFC_5321.EmailAddress Tests` {

    @Test
    func `an email address reads a bare address`() throws {
        let email = try RFC_5321.EmailAddress("user@example.com")

        #expect(email.localPart.description == "user")
        #expect(email.domain.name == "example.com")
        #expect(email.displayName == nil)
        #expect(email.address == "user@example.com")
    }

    @Test
    func `an email address reads a display name with an angle-addr`() throws {
        let email = try RFC_5321.EmailAddress("John Doe <john@example.com>")

        #expect(email.displayName == "John Doe")
        #expect(email.address == "john@example.com")
        #expect(email.description == "John Doe <john@example.com>")
    }

    @Test
    func `an email address reads a quoted display name`() throws {
        let email = try RFC_5321.EmailAddress("\"Doe, John\" <john@example.com>")

        #expect(email.displayName == "Doe, John")
        #expect(email.address == "john@example.com")
        #expect(email.description == "\"Doe, John\" <john@example.com>")
    }

    @Test
    func `an email address builds from its local part and domain`() throws {
        let email = try RFC_5321.EmailAddress(
            localPart: .init("support"),
            domain: .init("example.com")
        )

        #expect(email.description == "support@example.com")
    }

    @Test
    func `an email address builds with a display name`() throws {
        let email = try RFC_5321.EmailAddress(
            displayName: "Support Team",
            localPart: .init("support"),
            domain: .init("example.com")
        )

        #expect(email.description == "Support Team <support@example.com>")
        #expect(email.rawValue == "Support Team <support@example.com>")
    }

    @Test
    func `an email address trims the whitespace around a display name`() throws {
        let email = try RFC_5321.EmailAddress(
            displayName: "  Jane Smith  ",
            localPart: .init("jane"),
            domain: .init("example.com")
        )

        #expect(email.displayName == "Jane Smith")
    }

    @Test
    func `a blank display name becomes nil`() throws {
        let email = try RFC_5321.EmailAddress(
            displayName: "   ",
            localPart: .init("jane"),
            domain: .init("example.com")
        )

        #expect(email.displayName == nil)
        #expect(email.description == "jane@example.com")
        #expect(try RFC_5321.EmailAddress(email.description).displayName == nil)
    }

    @Test
    func `an email address rejects a non-ASCII display name`() throws {
        #expect(throws: RFC_5321.EmailAddress.Error.self) {
            try RFC_5321.EmailAddress(
                displayName: "Renée",
                localPart: .init("renee"),
                domain: .init("example.com")
            )
        }
    }

    @Test
    func `an email address without an at sign is refused`() throws {
        #expect(throws: RFC_5321.EmailAddress.Error.missingAtSign) {
            try RFC_5321.EmailAddress("no-at-sign")
        }
    }

    @Test
    func `an email address with an unterminated angle bracket is refused`() throws {
        #expect(throws: RFC_5321.EmailAddress.Error.unterminatedAngleBracket) {
            try RFC_5321.EmailAddress("John Doe <john@example.com")
        }
    }

    @Test
    func `a close angle before the open angle is refused`() throws {
        #expect(throws: RFC_5321.EmailAddress.Error.unterminatedAngleBracket) {
            try RFC_5321.EmailAddress("john@example.com> <")
        }
    }

    @Test
    func `an email address longer than the SMTP limit is refused`() throws {
        let local = String(repeating: "a", count: 64)
        let domain = String(repeating: "b", count: 60)

        #expect(throws: RFC_5321.EmailAddress.Error.self) {
            try RFC_5321.EmailAddress(
                "\(local)@\(domain).\(domain).\(domain).\(domain).com"
            )
        }
    }

    @Test
    func `an email address answers to a raw string`() throws {
        #expect(RFC_5321.EmailAddress(rawValue: "user@example.com")?.address == "user@example.com")
        #expect(RFC_5321.EmailAddress(rawValue: "not an address") == nil)
    }

    @Test
    func `reading an address yields the same parts as building it`() throws {
        let first = try RFC_5321.EmailAddress("user@example.com")
        let second = try RFC_5321.EmailAddress(
            localPart: .init("user"),
            domain: .init("example.com")
        )

        #expect(first.localPart.description == second.localPart.description)
        #expect(first.domain.name == second.domain.name)
        #expect(first.displayName == nil && second.displayName == nil)
    }
}
