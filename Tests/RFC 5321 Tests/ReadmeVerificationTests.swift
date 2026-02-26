//
//  ReadmeVerificationTests.swift
//  swift-rfc-5321
//
//  Verifies that README code examples actually work
//

import RFC_5321
import Testing

typealias EmailAddress = RFC_5321.EmailAddress

@Suite
struct `README Verification` {

    @Test
    func `README Line 52-55: Parse simple email address`() throws {
        let email = try EmailAddress("user@example.com")
        #expect(email.localPart.description == "user")
        #expect(email.domain.name == "example.com")
    }

    @Test
    func `README Line 57-60: Parse with display name`() throws {
        let namedEmail = try EmailAddress("John Doe <john@example.com>")
        #expect(namedEmail.displayName == "John Doe")
        #expect(namedEmail.address == "john@example.com")
    }

    @Test
    func `README Line 62-64: Parse with quoted display name`() throws {
        let quotedEmail = try EmailAddress("\"Doe, John\" <john@example.com>")
        #expect(quotedEmail.displayName == "Doe, John")
    }

    @Test
    func `README Line 70-80: Create from components`() throws {
        let localPart = try EmailAddress.LocalPart("support")
        let domain = try RFC_1123.Domain("example.com")
        let email = try EmailAddress(
            displayName: "Support Team",
            localPart: localPart,
            domain: domain
        )

        #expect(email.description == "Support Team <support@example.com>")
        #expect(email.address == "support@example.com")
    }

    @Test
    func `README Line 86-89: Valid addresses`() throws {
        let valid1 = try EmailAddress("simple@example.com")
        let valid2 = try EmailAddress("user.name@example.com")
        let valid3 = try EmailAddress("\"user name\"@example.com")

        #expect(valid1.localPart.description == "simple")
        #expect(valid2.localPart.description == "user.name")
        #expect(valid3.localPart.description == "\"user name\"")
    }

    @Test
    func `README Line 91-96: Invalid address throws missing at sign`() throws {
        #expect(throws: RFC_5321.EmailAddress.Error.missingAtSign) {
            _ = try RFC_5321.EmailAddress("no-at-sign")
        }
    }

    @Test
    func `README Line 98-102: Invalid address local part too long`() throws {
        let longAddress =
            "verylonglocalpartthatexceedssixtyfourcharactersshouldnotbeallowed@example.com"
        #expect(throws: RFC_5321.EmailAddress.Error.self) {
            _ = try RFC_5321.EmailAddress(longAddress)
        }
    }

    @Test
    func `README Line 145: Domain usage`() throws {
        let domain = try RFC_1123.Domain("mail.example.com")
        #expect(domain.name == "mail.example.com")
    }
}
