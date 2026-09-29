import Byte
import RFC_5321
import Testing

@Suite
struct `RFC_5321.EmailAddress.LocalPart Tests` {

    @Test
    func `a local part reads a dot-atom`() throws {
        let localPart = try RFC_5321.EmailAddress.LocalPart("first.last")

        #expect(localPart.description == "first.last")
    }

    @Test
    func `a local part reads a quoted string`() throws {
        let localPart = try RFC_5321.EmailAddress.LocalPart("\"user name\"")

        #expect(localPart.description == "\"user name\"")
    }

    @Test
    func `a local part reads the atext punctuation`() throws {
        let localPart = try RFC_5321.EmailAddress.LocalPart("a!#$%&'*+-/=?^_`{|}~")

        #expect(localPart.description == "a!#$%&'*+-/=?^_`{|}~")
    }

    @Test
    func `a local part reads bytes`() throws {
        let localPart = try RFC_5321.EmailAddress.LocalPart(
            ascii: "user".utf8.map(Byte.init(bitPattern:))
        )

        #expect(localPart.description == "user")
    }

    @Test
    func `an empty local part is refused`() throws {
        #expect(throws: RFC_5321.EmailAddress.LocalPart.Error.empty) {
            try RFC_5321.EmailAddress.LocalPart("")
        }
    }

    @Test
    func `a local part longer than sixty-four bytes is refused`() throws {
        #expect(throws: RFC_5321.EmailAddress.LocalPart.Error.tooLong(65)) {
            try RFC_5321.EmailAddress.LocalPart(String(repeating: "a", count: 65))
        }
    }

    @Test
    func `a non-ASCII local part is refused`() throws {
        #expect(throws: RFC_5321.EmailAddress.LocalPart.Error.nonASCII) {
            try RFC_5321.EmailAddress.LocalPart("renée")
        }
    }

    @Test
    func `a local part with a leading dot is refused`() throws {
        #expect(throws: RFC_5321.EmailAddress.LocalPart.Error.invalidDotAtom(".user")) {
            try RFC_5321.EmailAddress.LocalPart(".user")
        }
    }

    @Test
    func `a local part with consecutive dots is refused`() throws {
        #expect(throws: RFC_5321.EmailAddress.LocalPart.Error.invalidDotAtom("first..last")) {
            try RFC_5321.EmailAddress.LocalPart("first..last")
        }
    }

    @Test
    func `a local part with an unbalanced quote is refused`() throws {
        #expect(throws: RFC_5321.EmailAddress.LocalPart.Error.invalidQuotedString("\"user")) {
            try RFC_5321.EmailAddress.LocalPart("\"user")
        }
    }
}
