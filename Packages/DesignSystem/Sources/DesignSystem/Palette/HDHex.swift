public struct HDHexComponents: Sendable, Equatable {
    public let red: Double
    public let green: Double
    public let blue: Double

    public init?(hex: String) {
        var value = hex
        if value.hasPrefix("#") {
            value.removeFirst()
        }
        guard value.count == 6, let intValue = UInt32(value, radix: 16) else {
            return nil
        }
        red = Double((intValue >> 16) & 0xFF) / 255.0
        green = Double((intValue >> 8) & 0xFF) / 255.0
        blue = Double(intValue & 0xFF) / 255.0
    }
}
