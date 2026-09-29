
extension Solver {
    mutating func layoutAbsoluteChildren(
        _ index: Int,
        size: LayoutSize,
        origin: LayoutPoint,
        own: OwnSize,
        axes: ContainerAxes,
        innerMain: Double,
        innerCross: Double
    ) throws {
        let node = nodes[index]
        let containingBlock = OptionalSize(width: size.width, height: size.height)

        for child in node.children where nodes[child].style.position == .absolute {
            let childNode = nodes[child]
            let style = childNode.style
            let childOwn = ownSize(child, known: OptionalSize(), parent: containingBlock)
            let margin = style.margin.physical(childNode.direction)
            let margins = Physical(
                top: margin.top.points,
                left: margin.left.points,
                bottom: margin.bottom.points,
                right: margin.right.points
            )
            let insets = style.insets.physical(childNode.direction)

            var width = childOwn.width
            if width == nil, let left = insets.left, let right = insets.right {
                width = clamp(
                    size.width - left - right - margins.left - margins.right,
                    childOwn.minWidth,
                    childOwn.maxWidth,
                    childOwn.paddingWidth
                )
            }

            var height = childOwn.height
            if height == nil, let top = insets.top, let bottom = insets.bottom {
                height = clamp(
                    size.height - top - bottom - margins.top - margins.bottom,
                    childOwn.minHeight,
                    childOwn.maxHeight,
                    childOwn.paddingHeight
                )
            }

            if let ratio = style.aspectRatio, ratio > 0 {
                if let definite = width, height == nil {
                    height = clamp(
                        definite / ratio,
                        childOwn.minHeight,
                        childOwn.maxHeight,
                        childOwn.paddingHeight
                    )
                } else if let definite = height, width == nil {
                    width = clamp(
                        definite * ratio,
                        childOwn.minWidth,
                        childOwn.maxWidth,
                        childOwn.paddingWidth
                    )
                }
            }

            if width == nil || height == nil {
                let availableWidth =
                    size.width - (insets.left ?? 0) - (insets.right ?? 0) - margins.left
                    - margins.right
                let availableHeight =
                    size.height - (insets.top ?? 0) - (insets.bottom ?? 0) - margins.top
                    - margins.bottom
                let measured = try compute(
                    child,
                    known: OptionalSize(width: width, height: height),
                    parent: containingBlock,
                    available: AvailableSize(
                        width: .definite(max(0, availableWidth)),
                        height: .definite(max(0, availableHeight))
                    ),
                    mode: .size
                )
                width = width ?? measured.width
                height = height ?? measured.height
            }

            let childSize = LayoutSize(width: width ?? 0, height: height ?? 0)
            let staticPosition = absoluteStaticPosition(
                child,
                size: childSize,
                margins: margins,
                container: node.style,
                own: own,
                axes: axes,
                innerMain: innerMain,
                innerCross: innerCross
            )

            let x: Double
            if let left = insets.left {
                x = left + margins.left
            } else if let right = insets.right {
                x = size.width - right - margins.right - childSize.width
            } else {
                x = staticPosition.x
            }

            let y: Double
            if let top = insets.top {
                y = top + margins.top
            } else if let bottom = insets.bottom {
                y = size.height - bottom - margins.bottom - childSize.height
            } else {
                y = staticPosition.y
            }

            let frame = LayoutRect(
                origin: LayoutPoint(x: origin.x + x, y: origin.y + y),
                size: childSize
            )
            frames[child] = frame
            _ = try compute(
                child,
                known: OptionalSize(width: childSize.width, height: childSize.height),
                parent: containingBlock,
                available: AvailableSize(
                    width: .definite(childSize.width),
                    height: .definite(childSize.height)
                ),
                mode: .layout(frame.origin)
            )
        }
    }

    private func absoluteStaticPosition(
        _ child: Int,
        size: LayoutSize,
        margins: Physical<Double>,
        container: FlexStyle,
        own: OwnSize,
        axes: ContainerAxes,
        innerMain: Double,
        innerCross: Double
    ) -> LayoutPoint {
        let childMain = axes.main(size)
        let childCross = axes.cross(size)
        let marginMainStart = axes.mainStart(margins)
        let marginCrossStart = axes.crossStart(margins)
        let freeMain = innerMain - childMain - marginMainStart - axes.mainEnd(margins)
        let freeCross = innerCross - childCross - marginCrossStart - axes.crossEnd(margins)

        let mainOffset = distribute(
            justifyDistribution(container.justifyContent),
            free: freeMain,
            count: 1,
            gap: 0,
            startIsFlexEnd: container.direction.isReverse
        ).offset
        let alignment: AlignItems =
            switch nodes[child].style.alignSelf {
            case .auto: container.alignItems
            case .stretch: .stretch
            case .start: .start
            case .end: .end
            case .center: .center
            case .baseline: .baseline
            }
        let crossOffset: Double =
            switch alignment {
            case .end: freeCross
            case .center: freeCross / 2
            case .stretch, .start, .baseline: 0
            }

        let mainLogical = mainOffset + marginMainStart
        let crossLogical = crossOffset + marginCrossStart
        let main = axes.reversedMain ? innerMain - mainLogical - childMain : mainLogical
        let cross = axes.reversedCross ? innerCross - crossLogical - childCross : crossLogical
        return LayoutPoint(
            x: own.padding.left + (axes.isRow ? main : cross),
            y: own.padding.top + (axes.isRow ? cross : main)
        )
    }
}
