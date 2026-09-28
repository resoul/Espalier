/// A color in sRGB, components from 0 to 1.
///
/// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
public struct Color: Sendable, Hashable {
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var red: Double
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var green: Double
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var blue: Double
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var alpha: Double

    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public static let clear = Color(red: 0, green: 0, blue: 0, alpha: 0)
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public static let black = Color(red: 0, green: 0, blue: 0)
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public static let white = Color(red: 1, green: 1, blue: 1)

    /// This color `amount` of the way to `other`, as paint over it: 0 is this color, 1 is
    /// `other`.
    ///
    /// Ownership: returns a value. Isolation: none. Errors: none. Cancellation: not
    /// applicable.
    public func mixed(with other: Color, amount: Double) -> Color {
        let t = min(max(amount, 0), 1)
        return Color(
            red: red + (other.red - red) * t,
            green: green + (other.green - green) * t,
            blue: blue + (other.blue - blue) * t,
            alpha: alpha + (other.alpha - alpha) * t
        )
    }
}
