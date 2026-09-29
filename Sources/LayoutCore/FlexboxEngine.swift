
public enum FlexboxEngine {

    public static func layout(
        _ root: LayoutNode,
        size: LayoutSize,
        context: LayoutContext = LayoutContext()
    ) throws -> LayoutResult {
        var solver = Solver(root: root, context: context)
        solver.frames[0] = LayoutRect(origin: .zero, size: size)
        _ = try solver.compute(
            0,
            known: OptionalSize(width: size.width, height: size.height),
            parent: OptionalSize(width: size.width, height: size.height),
            available: AvailableSize(width: .definite(size.width), height: .definite(size.height)),
            mode: .layout(.zero)
        )
        return LayoutResult(
            frames: solver.nodes.indices.map { (solver.nodes[$0].id, solver.frames[$0]) }
        )
    }

    public static func measure(
        _ root: LayoutNode,
        width: AvailableSpace,
        height: AvailableSpace,
        context: LayoutContext = LayoutContext()
    ) throws -> LayoutSize {
        var solver = Solver(root: root, context: context)
        return try solver.compute(
            0,
            known: OptionalSize(),
            parent: OptionalSize(),
            available: AvailableSize(width: width, height: height),
            mode: .size
        )
    }
}

struct OptionalSize: Hashable {
    var width: Double?
    var height: Double?

    init(width: Double? = nil, height: Double? = nil) {
        self.width = width
        self.height = height
    }

    init(main: Double?, cross: Double?, isRow: Bool) {
        self.init(width: isRow ? main : cross, height: isRow ? cross : main)
    }
}

struct AvailableSize: Hashable {
    var width: AvailableSpace
    var height: AvailableSpace

    init(width: AvailableSpace, height: AvailableSpace) {
        self.width = width
        self.height = height
    }

    init(main: AvailableSpace, cross: AvailableSpace, isRow: Bool) {
        self.init(width: isRow ? main : cross, height: isRow ? cross : main)
    }
}

enum RunMode {
    case size
    case layout(LayoutPoint)
}

struct FlatNode {
    let id: LayoutID
    let style: FlexStyle
    let content: LayoutSize?
    let direction: LayoutDirection
    var children: [Int]
}

struct MeasureKey: Hashable {
    let node: Int
    let known: OptionalSize
    let parent: OptionalSize
    let available: AvailableSize
    let contentOnly: Bool
}

struct Solver {
    var nodes: [FlatNode] = []
    var frames: [LayoutRect] = []
    var cache: [MeasureKey: LayoutSize] = [:]
    let context: LayoutContext

    init(root: LayoutNode, context: LayoutContext) {
        self.context = context
        flatten(root)
        frames = Array(repeating: LayoutRect(x: 0, y: 0, width: 0, height: 0), count: nodes.count)
    }

    @discardableResult
    private mutating func flatten(_ node: LayoutNode) -> Int {
        let index = nodes.count
        nodes.append(
            FlatNode(
                id: node.id,
                style: node.style,
                content: node.content,
                direction: node.direction,
                children: []
            )
        )
        var children: [Int] = []
        children.reserveCapacity(node.children.count)
        for child in node.children {
            children.append(flatten(child))
        }
        nodes[index].children = children
        return index
    }

    mutating func compute(
        _ index: Int,
        known: OptionalSize,
        parent: OptionalSize,
        available: AvailableSize,
        mode: RunMode,
        contentOnly: Bool = false
    ) throws -> LayoutSize {
        if case .size = mode {
            let key = MeasureKey(
                node: index,
                known: known,
                parent: parent,
                available: available,
                contentOnly: contentOnly
            )
            if let cached = cache[key] { return cached }

            let size = try computeUncached(index, known, parent, available, mode, contentOnly)
            cache[key] = size
            return size
        }

        return try computeUncached(index, known, parent, available, mode, contentOnly)
    }

    private mutating func computeUncached(
        _ index: Int,
        _ known: OptionalSize,
        _ parent: OptionalSize,
        _ available: AvailableSize,
        _ mode: RunMode,
        _ contentOnly: Bool
    ) throws -> LayoutSize {
        if let width = known.width, let height = known.height, case .size = mode {
            return LayoutSize(width: width, height: height)
        }

        if nodes[index].children.isEmpty {
            return leafSize(index, known: known, parent: parent, contentOnly: contentOnly)
        }

        return try flexLayout(
            index,
            known: known,
            parent: parent,
            available: available,
            mode: mode,
            contentOnly: contentOnly
        )
    }

    private func leafSize(
        _ index: Int,
        known: OptionalSize,
        parent: OptionalSize,
        contentOnly: Bool
    ) -> LayoutSize {
        let node = nodes[index]
        let own = ownSize(index, known: known, parent: parent, contentOnly: contentOnly)
        let content = node.content ?? .zero
        var width = own.width
        var height = own.height
        if width == nil && height == nil {
            width = clamp(
                content.width + own.paddingWidth,
                own.minWidth,
                own.maxWidth,
                own.paddingWidth
            )
        }

        if let ratio = node.style.aspectRatio, ratio > 0 {
            if let known = width, height == nil {
                height = clamp(known / ratio, own.minHeight, own.maxHeight, own.paddingHeight)
            } else if let known = height, width == nil {
                width = clamp(known * ratio, own.minWidth, own.maxWidth, own.paddingWidth)
            }
        }

        return LayoutSize(
            width: width
                ?? clamp(
                    content.width + own.paddingWidth,
                    own.minWidth,
                    own.maxWidth,
                    own.paddingWidth
                ),
            height: height
                ?? clamp(
                    content.height + own.paddingHeight,
                    own.minHeight,
                    own.maxHeight,
                    own.paddingHeight
                )
        )
    }

    func ownSize(
        _ index: Int,
        known: OptionalSize,
        parent: OptionalSize,
        contentOnly: Bool = false
    ) -> OwnSize {
        let node = nodes[index]
        let style = node.style
        let padding = style.padding.physical(node.direction)
        let paddingWidth = max(0, padding.left) + max(0, padding.right)
        let paddingHeight = max(0, padding.top) + max(0, padding.bottom)
        let minWidth = style.minWidth.resolve(parent.width) ?? 0
        let minHeight = style.minHeight.resolve(parent.height) ?? 0
        let maxWidth = style.maxWidth.resolve(parent.width) ?? .infinity
        let maxHeight = style.maxHeight.resolve(parent.height) ?? .infinity
        let styleWidth = contentOnly ? nil : style.width.resolve(parent.width)
        let styleHeight = contentOnly ? nil : style.height.resolve(parent.height)
        var width = known.width ?? styleWidth.map { clamp($0, minWidth, maxWidth, paddingWidth) }
        var height =
            known.height ?? styleHeight.map { clamp($0, minHeight, maxHeight, paddingHeight) }
        if let ratio = style.aspectRatio, ratio > 0 {
            if let definite = width, height == nil {
                height = clamp(definite / ratio, minHeight, maxHeight, paddingHeight)
            } else if let definite = height, width == nil {
                width = clamp(definite * ratio, minWidth, maxWidth, paddingWidth)
            }
        }

        return OwnSize(
            width: width,
            height: height,
            minWidth: minWidth,
            maxWidth: maxWidth,
            minHeight: minHeight,
            maxHeight: maxHeight,
            paddingWidth: paddingWidth,
            paddingHeight: paddingHeight,
            padding: padding
        )
    }
}

struct OwnSize {
    var width: Double?
    var height: Double?
    var minWidth: Double
    var maxWidth: Double
    var minHeight: Double
    var maxHeight: Double
    var paddingWidth: Double
    var paddingHeight: Double
    var padding: Physical<Double>
}

func clamp(_ value: Double, _ minimum: Double, _ maximum: Double, _ floor: Double = 0) -> Double {
    max(floor, max(minimum, min(maximum, value)))
}