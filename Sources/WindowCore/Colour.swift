import Foundation

extension RGBA {
    /// Reads a hex colour: `#RGB`, `#RRGGBB` or `#RRGGBBAA`, with or without the `#`. The
    /// components are sRGB, as the system and the screen report them.
    public init?(hex text: String) {
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 3 || s.count == 6 || s.count == 8, s.allSatisfy(\.isHexDigit) else { return nil }
        let pairs: [String]
        if s.count == 3 {
            pairs = s.map { "\($0)\($0)" }
        } else {
            var out: [String] = []
            var i = s.startIndex
            while i < s.endIndex {
                let next = s.index(i, offsetBy: 2)
                out.append(String(s[i..<next]))
                i = next
            }
            pairs = out
        }
        let values = pairs.map { Double(Int($0, radix: 16) ?? 0) }
        self.init(r: values[0] / 255, g: values[1] / 255, b: values[2] / 255,
                  a: values.count == 4 ? values[3] / 255 : 1)
    }

    /// The colour written back for the config file: `#RRGGBB`, plus `AA` when not opaque.
    public var hex: String {
        func byte(_ v: Double) -> Int { Int(((v < 0 ? 0 : v > 1 ? 1 : v) * 255).rounded()) }
        let rgb = String(format: "#%02X%02X%02X", byte(r), byte(g), byte(b))
        return a >= 1 ? rgb : rgb + String(format: "%02X", byte(a))
    }
}
