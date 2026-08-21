import RFC_5321
import Testing

extension RFC_5321.EmailAddress {
    @Suite
    struct `Angle Bracket Parsing` {
        @Suite struct `Edge Case` {}
    }
}

extension RFC_5321.EmailAddress.`Angle Bracket Parsing`.`Edge Case` {
    @Test
    func `init(ascii:) throws instead of trapping when a close angle precedes the open angle`() {

        let malformed = [Byte]("a>b<c@example.com".utf8)
        #expect(throws: RFC_5321.EmailAddress.Error.self) {
            _ = try RFC_5321.EmailAddress(ascii: malformed)
        }
    }

    @Test
    func
        `init(ascii:) throws instead of silently succeeding when an open angle has no close angle anywhere after it`()
    {

        let malformed = [Byte](#""john<doe"@example.com"#.utf8)
        #expect(throws: RFC_5321.EmailAddress.Error.self) {
            _ = try RFC_5321.EmailAddress(ascii: malformed)
        }
    }
}
