# swift-rfc-5321

Domain model for RFC 5321, the Simple Mail Transfer Protocol mailbox: `RFC_5321.EmailAddress` (display name, `EmailAddress.LocalPart`, `RFC_1123.Domain`) validates on construction, requiring an ASCII-only address whose local-part is a dot-atom or quoted string of at most 64 bytes and whose address is at most 254 bytes, reads its RFC text form through `init(_:)` / `init(ascii:)` and renders it through `description` and `address`; the `RFC 5321 Foundation Integration` product bridges the text forms to `Codable`. The domain target carries no wire coders.

```swift
import RFC_1123
import RFC_5321

let email = try RFC_5321.EmailAddress("John Doe <john@example.com>")
email.displayName                                    // "John Doe"
email.localPart.description                          // "john"
email.domain.name                                    // "example.com"
email.address                                        // "john@example.com"
email.description                                    // "John Doe <john@example.com>"

let support = try RFC_5321.EmailAddress(
    displayName: "Support Team",
    localPart: try .init("support"),
    domain: try .init("example.com")
)
support.description                                  // "Support Team <support@example.com>"

do {
    _ = try RFC_5321.EmailAddress.LocalPart(String(repeating: "a", count: 65))
} catch RFC_5321.EmailAddress.LocalPart.Error.tooLong(let length) {
    length                                           // 65
}
```
