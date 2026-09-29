
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

struct DefiniteAxes: Hashable {
    var width: Bool
    var height: Bool

    static let both = DefiniteAxes(width: true, height: true)

    init(width: Bool, height: Bool) {
        self.width = width
        self.height = height
    }

    init(main: Bool, cross: Bool, isRow: Bool) {
        self.init(width: isRow ? main : cross, height: isRow ? cross : main)
    }
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
    let definite: DefiniteAxes
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
        contentOnly: Bool = false,
        definite: DefiniteAxes = .both
    ) throws -> LayoutSize {
        if case .size = mode {
            let key = MeasureKey(
                node: index,
                known: known,
                parent: parent,
                available: available,
                contentOnly: contentOnly,
                definite: definite
            )
            if let cached = cache[key] { return cached }

            let size = try computeUncached(
                index,
                known,
                parent,
                available,
                mode,
                contentOnly,
                definite
            )
            cache[key] = size
            return size
        }

        return try computeUncached(index, known, parent, available, mode, contentOnly, definite)
    }

    private mutating func computeUncached(
        _ index: Int,
        _ known: OptionalSize,
        _ parent: OptionalSize,
        _ available: AvailableSize,
        _ mode: RunMode,
        _ contentOnly: Bool,
        _ definite: DefiniteAxes
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
            contentOnly: contentOnly,
            definite: definite
        )
    }

    private func leafSize(
        _ index: Int,
        known: OptionalSize,
        parent: OptionalSize,
        contentOnly: Bool
    ) -> LayoutSize {
        let node = nodes[index]
        let style = node.style
        let own = ownSize(
            index,
            known: known,
            parent: parent,
            contentOnly: contentOnly,
            transferRatio: false
        )
        let content = node.content ?? .zero
        let contentWidth = content.width + own.paddingWidth
        let contentHeight = content.height + own.paddingHeight
        var width = own.width
        var height = own.height

        if let ratio = style.aspectRatio, ratio > 0 {
            if width == nil && height == nil {
                let minHeight = style.minHeight.resolve(parent.height) ?? 0
                let maxHeight = style.maxHeight.resolve(parent.height) ?? .infinity
                width = clamp(
                    max(minHeight * ratio, min(maxHeight * ratio, contentWidth)),
                    own.minWidth,
                    own.maxWidth,
                    own.paddingWidth
                )
            }

            if let base = width, height == nil {
                height = ratioDependent(
                    base / ratio,
                    content: contentHeight,
                    minimum: own.minHeight,
                    maximum: own.maxHeight,
                    floor: own.paddingHeight,
                    automaticMinimum: style.minHeight == .auto
                )
            } else if let base = height, width == nil {
                width = ratioDependent(
                    base * ratio,
                    content: contentWidth,
                    minimum: own.minWidth,
                    maximum: own.maxWidth,
                    floor: own.paddingWidth,
                    automaticMinimum: style.minWidth == .auto
                )
            }
        }

        return LayoutSize(
            width: width ?? clamp(contentWidth, own.minWidth, own.maxWidth, own.paddingWidth),
            height: height ?? clamp(contentHeight, own.minHeight, own.maxHeight, own.paddingHeight)
        )
    }

    private func ratioDependent(
        _ value: Double,
        content: Double,
        minimum: Double,
        maximum: Double,
        floor: Double,
        automaticMinimum: Bool
    ) -> Double {
        let automatic = automaticMinimum ? min(content, maximum) : 0
        return clamp(max(value, automatic), minimum, maximum, floor)
    }

    func ownSize(
        _ index: Int,
        known: OptionalSize,
        parent: OptionalSize,
        contentOnly: Bool = false,
        transferRatio: Bool = true,
        definite: DefiniteAxes = .both
    ) -> OwnSize {
        let node = nodes[index]
        let style = node.style
        let padding = style.padding.physical(node.direction)
        let paddingWidth = max(0, padding.left) + max(0, padding.right)
        let paddingHeight = max(0, padding.top) + max(0, padding.bottom)

        let minWidth = contentOnly ? 0 : style.minWidth.resolve(parent.width) ?? 0
        let minHeight = contentOnly ? 0 : style.minHeight.resolve(parent.height) ?? 0
        let maxWidth = contentOnly ? .infinity : style.maxWidth.resolve(parent.width) ?? .infinity
        let maxHeight =
            contentOnly ? .infinity : style.maxHeight.resolve(parent.height) ?? .infinity
        let styleWidth = contentOnly ? nil : style.width.resolve(parent.width)
        let styleHeight = contentOnly ? nil : style.height.resolve(parent.height)
        let specifiedWidth = styleWidth.map { clamp($0, minWidth, maxWidth, paddingWidth) }
        let specifiedHeight = styleHeight.map { clamp($0, minHeight, maxHeight, paddingHeight) }
        var width = known.width ?? specifiedWidth
        var height = known.height ?? specifiedHeight
        var definiteWidth = known.width.map { definite.width ? $0 : nil } ?? specifiedWidth
        var definiteHeight = known.height.map { definite.height ? $0 : nil } ?? specifiedHeight
        if transferRatio, let ratio = style.aspectRatio, ratio > 0 {
            if let base = width, height == nil {
                height = clamp(base / ratio, minHeight, maxHeight, paddingHeight)
                definiteHeight = definiteWidth.map {
                    clamp($0 / ratio, minHeight, maxHeight, paddingHeight)
                }
            } else if let base = height, width == nil {
                width = clamp(base * ratio, minWidth, maxWidth, paddingWidth)
                definiteWidth = definiteHeight.map {
                    clamp($0 * ratio, minWidth, maxWidth, paddingWidth)
                }
            }
        }

        return OwnSize(
            width: width,
            height: height,
            definiteWidth: definiteWidth,
            definiteHeight: definiteHeight,
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
    var definiteWidth: Double?
    var definiteHeight: Double?
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