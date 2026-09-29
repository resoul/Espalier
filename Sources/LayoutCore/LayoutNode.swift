/// Opaque identity of a layout element. The adapter that builds the tree (nodes, `UIView`,
/// `NSView`) chooses the values and maps them back to its own objects.
///
/// Ownership: value type. Isolation: none. Errors: none. Cancellation: not applicable.
public struct LayoutID: Sendable, Hashable, CustomStringConvertible {
    let raw: UInt64

    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public init(_ raw: UInt64) {
        self.raw = raw
    }

    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var description: String { "#\(raw)" }
}

/// One element of the immutable input tree. A node without children is a leaf; its
/// `content` is the size of what it shows (for example an image), excluding `padding`.
///
/// Ownership: value type; the tree is an immutable snapshot the caller builds and may send to
/// any task. Isolation: none. Errors: none. Cancellation: not applicable.
public struct LayoutNode: Sendable {
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var id: LayoutID
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var style: FlexStyle
    /// Intrinsic content size of a leaf; ignored for a node with children.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var content: LayoutSize?
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var direction: LayoutDirection
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public var children: [LayoutNode]

    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public init(
        id: LayoutID,
        style: FlexStyle = FlexStyle(),
        content: LayoutSize? = nil,
        direction: LayoutDirection = .leftToRight,
        children: [LayoutNode] = []
    ) {
        self.id = id
        self.style = style
        self.content = content
        self.direction = direction
        self.children = children
    }
}

/// Frames of every node of one layout pass, in the root's coordinate space.
///
/// Ownership: value type. Isolation: none. Errors: none. Cancellation: not applicable.
public struct LayoutResult: Sendable {
    /// Frames in pre-order of the input tree.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public let frames: [(id: LayoutID, frame: LayoutRect)]

    /// Identities that appeared more than once in the input. Their frames are ambiguous: only
    /// the first occurrence is reachable through `frame(for:)`.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public let duplicateIDs: Set<LayoutID>

    private let index: [LayoutID: Int]

    init(frames: [(id: LayoutID, frame: LayoutRect)]) {
        self.frames = frames
        var index: [LayoutID: Int] = [:]
        var duplicates: Set<LayoutID> = []
        for (offset, entry) in frames.enumerated() {
            if index[entry.id] != nil {
                duplicates.insert(entry.id)
                continue
            }

            index[entry.id] = offset
        }
        self.index = index
        self.duplicateIDs = duplicates
    }

    /// The frame of `id`, or `nil` when the id was not in the input.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public func frame(for id: LayoutID) -> LayoutRect? {
        index[id].map { frames[$0].frame }
    }
}

/// Execution context of one layout pass: currently the cancellation check.
///
/// Ownership: value type; the closure is owned by whoever scheduled the pass. Isolation:
/// `isCancelled` is called from the solving task. Errors: none. Cancellation: see
/// `isCancelled`.
public struct LayoutContext: Sendable {
    /// Polled at checkpoints: every container, and every 256 items of a container.
    ///
    /// Ownership: value. Isolation: called on the solving task. Errors: none. Cancellation:
    /// returning `true` makes the pass throw `LayoutCancelled`.
    public var isCancelled: @Sendable () -> Bool

    /// Ownership: value. Isolation: none. Errors: none. Cancellation: not applicable.
    public init(isCancelled: @escaping @Sendable () -> Bool = { false }) {
        self.isCancelled = isCancelled
    }

    /// A context that cancels when the current `Task` is cancelled.
    ///
    /// Ownership: value. Isolation: none. Errors: none. Cancellation: follows the task.
    public static var currentTask: LayoutContext {
        LayoutContext(isCancelled: { Task.isCancelled })
    }

    func checkpoint() throws {
        if isCancelled() { throw LayoutCancelled() }
    }
}

/// Thrown when a pass is cancelled. A cancelled pass produces no result — never a partial one.
///
/// Ownership: value type. Isolation: none. Errors: none. Cancellation: this is the signal.
public struct LayoutCancelled: Error, Sendable {}