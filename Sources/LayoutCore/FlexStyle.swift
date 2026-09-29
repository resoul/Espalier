/// A length that may be absolute, relative to the containing block, or automatic.
///
/// Ownership: value type. Isolation: none. Errors: none. Cancellation: not applicable.
public enum Length: Sendable, Hashable, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
    case auto
    case points(Double)
    case fraction(Double)

    /// A literal means points.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public init(integerLiteral value: Int) {
        self = .points(Double(value))
    }

    /// A literal means points.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public init(floatLiteral value: Double) {
        self = .points(value)
    }

    func resolve(_ base: Double?) -> Double? {
        switch self {
        case .auto:
            return nil
        case let .points(value):
            return value.isFinite ? max(0, value) : nil
        case let .fraction(value):
            guard let base, value.isFinite else { return nil }

            return max(0, base * value)
        }
    }
}

/// A margin value: points or `auto` (absorbs free space, CSS Flexbox §8.1).
///
/// Ownership: value type. Isolation: none. Errors: none. Cancellation: not applicable.
public enum Margin: Sendable, Hashable, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
    case points(Double)
    case auto

    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public init(integerLiteral value: Int) {
        self = .points(Double(value))
    }

    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public init(floatLiteral value: Double) {
        self = .points(value)
    }

    var points: Double {
        if case let .points(value) = self, value.isFinite { return value }
        return 0
    }

    var isAuto: Bool { self == .auto }
}

/// Logical edges: `leading`/`trailing` follow the node's `LayoutDirection`.
///
/// Ownership: value type. Isolation: none. Errors: none. Cancellation: not applicable.
public struct Edges<Value: Sendable & Hashable>: Sendable, Hashable {
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var top: Value
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var leading: Value
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var bottom: Value
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var trailing: Value

    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public init(top: Value, leading: Value, bottom: Value, trailing: Value) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }

    /// The same value on every edge.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public init(all value: Value) {
        self.init(top: value, leading: value, bottom: value, trailing: value)
    }

    func physical(_ direction: LayoutDirection) -> Physical<Value> {
        switch direction {
        case .leftToRight:
            Physical(top: top, left: leading, bottom: bottom, right: trailing)
        case .rightToLeft:
            Physical(top: top, left: trailing, bottom: bottom, right: leading)
        }
    }
}

/// Edges resolved to physical sides.
struct Physical<Value> {
    var top: Value
    var left: Value
    var bottom: Value
    var right: Value
}

/// CSS `flex-direction`.
///
/// Ownership: value type. Isolation: none. Errors: none. Cancellation: not applicable.
public enum FlexDirection: Sendable, Hashable {
    case row
    case column
    case rowReverse
    case columnReverse

    var isRow: Bool { self == .row || self == .rowReverse }
    var isReverse: Bool { self == .rowReverse || self == .columnReverse }
}

/// CSS `flex-wrap`.
///
/// Ownership: value type. Isolation: none. Errors: none. Cancellation: not applicable.
public enum FlexWrap: Sendable, Hashable {
    case noWrap
    case wrap
    case wrapReverse
}

/// CSS `justify-content`.
///
/// Ownership: value type. Isolation: none. Errors: none. Cancellation: not applicable.
public enum JustifyContent: Sendable, Hashable {
    case start
    case end
    case center
    case spaceBetween
    case spaceAround
    case spaceEvenly
}

/// CSS `align-content`; `stretch` is also what CSS `normal` does in a flex container.
///
/// Ownership: value type. Isolation: none. Errors: none. Cancellation: not applicable.
public enum AlignContent: Sendable, Hashable {
    case stretch
    case start
    case end
    case center
    case spaceBetween
    case spaceAround
    case spaceEvenly
}

/// CSS `align-items`.
///
/// Ownership: value type. Isolation: none. Errors: none. Cancellation: not applicable.
public enum AlignItems: Sendable, Hashable {
    case stretch
    case start
    case end
    case center
    case baseline
}

/// CSS `align-self`; `auto` defers to the container's `alignItems`.
///
/// Ownership: value type. Isolation: none. Errors: none. Cancellation: not applicable.
public enum AlignSelf: Sendable, Hashable {
    case auto
    case stretch
    case start
    case end
    case center
    case baseline
}

/// CSS `position`: in flow, or absolutely positioned against the parent's padding box.
///
/// Ownership: value type. Isolation: none. Errors: none. Cancellation: not applicable.
public enum Position: Sendable, Hashable {
    case relative
    case absolute
}

/// Everything the flex algorithm reads from one node. Field names and defaults follow CSS,
/// with one deliberate difference: sizes are border-box (`width` includes `padding`), as in
/// every UI toolkit and in Yoga. Every node is a flex container.
///
/// Ownership: value type. Isolation: none. Errors: none. Cancellation: not applicable.
public struct FlexStyle: Sendable, Hashable {
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var direction: FlexDirection = .row
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var wrap: FlexWrap = .noWrap
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var justifyContent: JustifyContent = .start
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var alignItems: AlignItems = .stretch
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var alignSelf: AlignSelf = .auto
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var alignContent: AlignContent = .stretch
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var grow: Double = 0
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var shrink: Double = 1
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var basis: Length = .auto
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var width: Length = .auto
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var height: Length = .auto
    /// `auto` is the CSS automatic minimum size for flex items (§4.5), zero otherwise.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var minWidth: Length = .auto
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var minHeight: Length = .auto
    /// `auto` means no limit.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var maxWidth: Length = .auto
    /// `auto` means no limit.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var maxHeight: Length = .auto
    /// Width divided by height, or `nil`.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var aspectRatio: Double?
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var padding = Edges<Double>(all: 0)
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var margin = Edges<Margin>(all: .points(0))
    /// Space between rows (CSS `row-gap`).
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var rowGap: Double = 0
    /// Space between columns (CSS `column-gap`).
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var columnGap: Double = 0
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var position: Position = .relative
    /// Offsets of an absolutely positioned node from its parent's padding box.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var insets = Edges<Double?>(all: nil)
    /// CSS `order`: lower values are laid out first; ties keep document order.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var order: Int = 0

    /// A style with every CSS default.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public init() {}
}
