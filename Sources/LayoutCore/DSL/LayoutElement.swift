import Foundation

/// An object a `LayoutSpec` places: a view, or anything else with a frame. The spec asks it
/// how its content measures and hands it its final frame.
///
/// Ownership: elements are owned by whoever created them (for views: their superview); a
/// spec only borrows them for one layout pass. Isolation: MainActor — elements are UI objects.
/// Errors: none. Cancellation: not applicable.
@MainActor
public protocol LayoutElement: AnyObject, LayoutSpecConvertible {
    /// How the element's content measures, or `nil` when it has none (its size then comes
    /// only from the spec's modifiers and from flex layout).
    ///
    /// Ownership: returns a value. Isolation: MainActor. Errors: none. Cancellation: none.
    var layoutContent: LeafContent? { get }

    /// The layout of the element's own sub elements, laid out in the same pass as the spec
    /// that places the element: the element becomes a flex container whose style is that
    /// layout's, with the element's place modifiers on top, and whose items are that
    /// layout's items. `nil` places the element as a leaf measured by `layoutContent`.
    ///
    /// Ownership: returns a value borrowing the element's sub elements. Isolation: MainActor.
    /// Errors: none. Cancellation: none.
    var embeddedLayout: LayoutSpec? { get }

    /// Receives the element's frame: in the coordinate space of the element whose
    /// `embeddedLayout` placed it, or else of the rectangle the spec was applied in.
    ///
    /// Ownership: the element stores what it needs. Isolation: MainActor. Errors: none.
    /// Cancellation: none.
    func applyLayoutFrame(_ frame: LayoutRect)

    /// Shows or hides the element — called only for elements of specs that manage visibility
    /// (`hidden`, `invisible`, `Breakpoint`). The default does nothing.
    ///
    /// Ownership: the element stores what it needs. Isolation: MainActor. Errors: none.
    /// Cancellation: none.
    func applyLayoutVisibility(_ isVisible: Bool)

    /// Receives where the element sticks (`sticky`), or `nil` when it does not — after its
    /// frame, in every pass. The default does nothing: moving with a scroll is up to the
    /// element.
    ///
    /// Ownership: the element stores what it needs. Isolation: MainActor. Errors: none.
    /// Cancellation: none.
    func applyLayoutSticky(_ sticky: StickyPosition?)
}

/// Where a `sticky` element keeps itself while a scroll moves: its distances from the
/// scroll's edges, and the box it may not leave.
///
/// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
public struct StickyPosition: Sendable, Hashable {
    /// Distance from the scroll's top edge the element keeps; `nil` does not stick there.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var top: Double?
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var left: Double?
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var bottom: Double?
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var right: Double?
    /// The frame of the container the element is laid out in, in the coordinates of the
    /// element's own frame: sticking never takes the element out of it.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var bounds: LayoutRect

    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public init(
        top: Double? = nil,
        left: Double? = nil,
        bottom: Double? = nil,
        right: Double? = nil,
        bounds: LayoutRect
    ) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
        self.bounds = bounds
    }
}

extension LayoutElement {
    /// Ownership: none. Isolation: MainActor. Errors: none. Cancellation: none.
    public func applyLayoutVisibility(_ isVisible: Bool) {}

    /// Ownership: none. Isolation: MainActor. Errors: none. Cancellation: none.
    public func applyLayoutSticky(_ sticky: StickyPosition?) {}

    /// No embedded layout: the element is a leaf.
    ///
    /// Ownership: none. Isolation: MainActor. Errors: none. Cancellation: none.
    public var embeddedLayout: LayoutSpec? { nil }

    /// A spec that places this element as a single item.
    ///
    /// Ownership: the spec borrows the element. Isolation: MainActor. Errors: none.
    /// Cancellation: not applicable.
    public var asLayoutSpec: LayoutSpec { LayoutSpec(element: self) }
}
