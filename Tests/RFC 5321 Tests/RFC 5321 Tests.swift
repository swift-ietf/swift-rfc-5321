//
//  File.swift
//  swift-web
//
//  Created by Coen ten Thije Boonkkamp on 28/12/2024.
//

import Foundation
import RFC_1123
import RFC_5321
import Testing

@Suite
struct `RFC 5321 Domain Tests` {
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

    //    @Test("Fails with invalid IPv4 format")
    //    func testInvalidIPv4Format() throws {
    //        #expect(throws: Domain.ValidationError.invalidIPv4("256.256.256.256")) {
    //            _ = try Domain("[256.256.256.256]")
    //        }
    //    }
    //
    //    @Test("Fails with invalid IPv6 format")
    //    func testInvalidIPv6Format() throws {
    //        #expect(throws: Domain.ValidationError.invalidIPv6("not:valid:ipv6")) {
    //            _ = try Domain("[not:valid:ipv6]")
    //        }
    //    }
    //
    //    @Test("Successfully gets standard domain")
    //    func testGetStandardDomain() throws {
    //        let domain = try Domain("mail.example.com")
    //        #expect(domain.standardDomain?.name == "mail.example.com")
    //    }
    //
    //    @Test("Returns nil standard domain for address literal")
    //    func testNilStandardDomainForAddressLiteral() throws {
    //        let domain = try Domain("[192.168.1.1]")
    //        #expect(domain.standardDomain == nil)
    //    }
    //
    //    @Test("Successfully creates from RFC1123")
    //    func testCreateFromRFC1123() throws {
    //        let rfc1123 = try RFC_1123.Domain("mail.example.com")
    //        let domain = Domain(domain: rfc1123)
    //        #expect(domain.name == "mail.example.com")
    //        #expect(domain.isStandardDomain)
    //    }
    //
    //    @Test("Successfully creates IPv4 literal directly")
    //    func testCreateIPv4Literal() throws {
    //        let domain = try Domain(ipv4Literal: "192.168.1.1")
    //        #expect(domain.name == "[192.168.1.1]")
    //        #expect(domain.addressLiteral == "192.168.1.1")
    //    }
    //
    //    @Test("Successfully creates IPv6 literal directly")
    //    func testCreateIPv6Literal() throws {
    //        let ipv6 = "2001:db8:85a3:8d3:1319:8a2e:370:7348"
    //        let domain = try Domain(ipv6Literal: ipv6)
    //        #expect(domain.name == "[\(ipv6)]")
    //        #expect(domain.addressLiteral == ipv6)
    //    }

    @Test
    func `Successfully encodes and decodes standard domain`() throws {
        let original = try RFC_1123.Domain("mail.example.com")
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RFC_1123.Domain.self, from: encoded)
        #expect(original == decoded)
    }

}
