import LayoutCore
import ThemeCore

/// How a node's box looks. Changing it redraws the node without laying anything out.
///
/// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
public struct Appearance: Sendable, Hashable {
    /// Fill of the box; `nil` for none.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var background: Color?

    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var cornerRadius: Double = 0

    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var borderWidth: Double = 0

    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var borderColor: Color?

    /// From 0 (invisible) to 1.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var opacity: Double = 1

    /// Subnodes are cut to the box (and its corner radius).
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var clipsContent = false

    /// Size of the drawn box relative to its frame, around its center: 1.1 is a tenth
    /// bigger. Layout, taps and focus see the frame, not the scaled box.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var scale: Double = 1

    /// Points the box is drawn moved by from its frame, as a CSS translation: the layout does
    /// not change, and taps, focus and accessibility find the node where it is drawn. A row
    /// swiped aside moves so.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var offset = LayoutPoint.zero

    /// Turns a second the drawn box keeps turning by, clockwise about its center — a
    /// spinner's — for as long as it is set; 0, the default, does not turn. Nothing else
    /// sees the turn.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var spin: Double = 0

    /// A shadow under the box; `nil` for none.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var shadow: Shadow?

    /// Where the box is drawn among its siblings, as CSS `z-index`: higher is drawn over
    /// lower, and at the same one sticky boxes are over the rest, which keep their layout
    /// order. Taps find the one drawn on top. A row lifted to be moved is drawn over the
    /// others so.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var zIndex = 0

    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public init() {}
}

/// A shadow cast by a node's box.
///
/// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
public struct Shadow: Sendable, Hashable {
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var color: Color
    /// From 0 to 1.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var opacity: Double
    /// Blur radius in points.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var radius: Double
    /// Offset in points, rightward.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var x: Double
    /// Offset in points, downward.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var y: Double

    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public init(
        color: Color = .black,
        opacity: Double = 0.3,
        radius: Double = 12,
        x: Double = 0,
        y: Double = 8
    ) {
        self.color = color
        self.opacity = opacity
        self.radius = radius
        self.x = x
        self.y = y
    }
}
