import Foundation
import RFC_1123
import RFC_5321
import Testing

@Suite
struct `RFC 5321 Domain Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `RFC 5321 Domain Tests`.Unit {
    @Test
    func `Successfully creates standard domain`() throws {
        let domain = try RFC_1123.Domain("mail.example.com")
        #expect(domain.name == "mail.example.com")
    }

    @Test
    func `Fails with empty address literal`() throws {
        #expect(throws: RFC_1123.Domain.Error.self) {
            _ = try RFC_1123.Domain("[]")
        }
    }

    @Test
    func `Successfully encodes and decodes standard domain`() throws {
        let original = try RFC_1123.Domain("mail.example.com")
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RFC_1123.Domain.self, from: encoded)
        #expect(original == decoded)
    }

}
