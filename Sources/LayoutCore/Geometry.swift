/// A size in points.
///
/// Ownership: value type. Isolation: none. Errors: none. Cancellation: not applicable.
public struct LayoutSize: Sendable, Hashable, CustomStringConvertible {
    /// Horizontal extent.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var width: Double

    /// Vertical extent.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var height: Double

    /// Creates a size.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }

    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public static let zero = LayoutSize(width: 0, height: 0)

    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var description: String { "\(width)×\(height)" }
}

/// A point in points; `y` grows downward.
///
/// Ownership: value type. Isolation: none. Errors: none. Cancellation: not applicable.
public struct LayoutPoint: Sendable, Hashable {
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var x: Double

    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var y: Double

    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public static let zero = LayoutPoint(x: 0, y: 0)
}

/// A rectangle in the root's coordinate space.
///
/// Ownership: value type. Isolation: none. Errors: none. Cancellation: not applicable.
public struct LayoutRect: Sendable, Hashable, CustomStringConvertible {
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var origin: LayoutPoint

    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var size: LayoutSize

    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public init(origin: LayoutPoint, size: LayoutSize) {
        self.origin = origin
        self.size = size
    }

    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public init(x: Double, y: Double, width: Double, height: Double) {
        self.init(origin: LayoutPoint(x: x, y: y), size: LayoutSize(width: width, height: height))
    }

    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var description: String {
        "(\(origin.x), \(origin.y), \(size.width)×\(size.height))"
    }
}

/// Inline direction of a node. Decides which physical side `leading`/`trailing` edges and
/// the start of a `row` mean.
///
/// Ownership: value type. Isolation: none. Errors: none. Cancellation: not applicable.
public enum LayoutDirection: Sendable, Hashable {
    case leftToRight
    case rightToLeft
}

/// Space offered to a node along one axis while it is measured (CSS Sizing §2.1).
///
/// Ownership: value type. Isolation: none. Errors: none. Cancellation: not applicable.
public enum AvailableSpace: Sendable, Hashable {
    case definite(Double)
    case minContent
    case maxContent

    var definiteValue: Double? {
        if case let .definite(value) = self { return value }
        return nil
    }

    func shrunk(by amount: Double) -> AvailableSpace {
        if case let .definite(value) = self { return .definite(max(0, value - amount)) }
        return self
    }
}