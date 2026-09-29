import Foundation
import RFC_5321
import RFC_5321_Foundation_Integration
import Testing

@Suite
struct `RFC_5321+Codable Tests` {

    @Test
    func `an email address codes as its text form`() throws {
        let email = try RFC_5321.EmailAddress("user@example.com")

        let encoded = try JSONEncoder().encode(email)

        #expect(String(decoding: encoded, as: UTF8.self) == #""user@example.com""#)
        #expect(try JSONDecoder().decode(RFC_5321.EmailAddress.self, from: encoded) == email)
    }

    @Test
    func `an email address with a display name round-trips`() throws {
        let email = try RFC_5321.EmailAddress("John Doe <john@example.com>")

        let encoded = try JSONEncoder().encode(email)

        #expect(try JSONDecoder().decode(RFC_5321.EmailAddress.self, from: encoded) == email)
    }

    @Test
    func `a malformed email address fails to decode`() throws {
        let encoded = Data(#""no-at-sign""#.utf8)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(RFC_5321.EmailAddress.self, from: encoded)
        }
    }

    @Test
    func `a local part codes as its text form`() throws {
        let localPart = try RFC_5321.EmailAddress.LocalPart("first.last")

        let encoded = try JSONEncoder().encode(localPart)

        #expect(String(decoding: encoded, as: UTF8.self) == #""first.last""#)
        #expect(
            try JSONDecoder().decode(RFC_5321.EmailAddress.LocalPart.self, from: encoded)
                == localPart
        )
    }

    @Test
    func `a malformed local part fails to decode`() throws {
        let encoded = Data(#""first..last""#.utf8)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(RFC_5321.EmailAddress.LocalPart.self, from: encoded)
        }
    }
}
