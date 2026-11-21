import Foundation
import CoreGraphics

/// Pure conversions between the coordinate systems used by Wailo.
enum CoordinateSpace {
    static func primaryHeight(screenFrames: [CGRect]) -> CGFloat {
        guard let height = screenFrames.first(where: { $0.origin == .zero })?.height else {
            preconditionFailure("Coordinate conversion requires a zero-origin primary display")
        }
        return height
    }

    static func axToCocoa(_ point: CGPoint, screenFrames: [CGRect]) -> CGPoint {
        CGPoint(x: point.x, y: primaryHeight(screenFrames: screenFrames) - point.y)
    }

    static func cocoaToAX(_ point: CGPoint, screenFrames: [CGRect]) -> CGPoint {
        axToCocoa(point, screenFrames: screenFrames)
    }

    static func axToCocoa(_ rect: CGRect, screenFrames: [CGRect]) -> CGRect {
        let height = primaryHeight(screenFrames: screenFrames)
        let standardized = rect.standardized
        return CGRect(x: standardized.minX,
                      y: height - standardized.maxY,
                      width: standardized.width,
                      height: standardized.height)
    }

    static func cocoaToAX(_ rect: CGRect, screenFrames: [CGRect]) -> CGRect {
        axToCocoa(rect, screenFrames: screenFrames)
    }

    static func globalToLocal(_ point: CGPoint, screenFrame: CGRect) -> CGPoint {
        CGPoint(x: point.x - screenFrame.minX, y: point.y - screenFrame.minY)
    }

    static func localToGlobal(_ point: CGPoint, screenFrame: CGRect) -> CGPoint {
        CGPoint(x: point.x + screenFrame.minX, y: point.y + screenFrame.minY)
    }

    static func globalToLocal(_ rect: CGRect, screenFrame: CGRect) -> CGRect {
        CGRect(origin: globalToLocal(rect.origin, screenFrame: screenFrame), size: rect.size)
    }

    static func localToGlobal(_ rect: CGRect, screenFrame: CGRect) -> CGRect {
        CGRect(origin: localToGlobal(rect.origin, screenFrame: screenFrame), size: rect.size)
    }

    /// Selects a containing display, or the display nearest to the point when it is off-screen.
    static func screenIndex(containing point: CGPoint, screenFrames: [CGRect]) -> Int {
        guard point.isFinite, !screenFrames.isEmpty else { return 0 }
        if let contained = screenFrames.firstIndex(where: { $0.closedContains(point) }) {
            return contained
        }

        return screenFrames.indices.min { lhs, rhs in
            squaredDistance(from: point, to: screenFrames[lhs]) <
                squaredDistance(from: point, to: screenFrames[rhs])
        } ?? 0
    }

    /// Converts a backend 0...1000, top-left-origin bbox into global Cocoa coordinates.
    static func bbox1000ToCocoa<T: BinaryFloatingPoint>(
        _ bbox: [T],
        screenFrame: CGRect
    ) -> CGRect? {
        guard bbox.count == 4, screenFrame.isFinite, screenFrame.width >= 0, screenFrame.height >= 0 else {
            return nil
        }
        let values = bbox.map(Double.init)
        guard values.allSatisfy(\.isFinite),
              values.allSatisfy({ (0...1000).contains($0) }),
              values[0] <= values[2], values[1] <= values[3] else {
            return nil
        }

        let xMin = screenFrame.minX + CGFloat(values[0] / 1000) * screenFrame.width
        let xMax = screenFrame.minX + CGFloat(values[2] / 1000) * screenFrame.width
        let cocoaTop = screenFrame.maxY - CGFloat(values[1] / 1000) * screenFrame.height
        let cocoaBottom = screenFrame.maxY - CGFloat(values[3] / 1000) * screenFrame.height
        let left = min(max(xMin, screenFrame.minX), screenFrame.maxX)
        let right = min(max(xMax, screenFrame.minX), screenFrame.maxX)
        let bottom = min(max(cocoaBottom, screenFrame.minY), screenFrame.maxY)
        let top = min(max(cocoaTop, screenFrame.minY), screenFrame.maxY)
        return CGRect(x: left, y: bottom, width: right - left, height: top - bottom)
    }

    static func bbox1000ToCocoa<T: BinaryFloatingPoint>(_ bbox: [T], screen: CGRect) -> CGRect? {
        bbox1000ToCocoa(bbox, screenFrame: screen)
    }

    private static func squaredDistance(from point: CGPoint, to rect: CGRect) -> CGFloat {
        let dx = max(rect.minX - point.x, 0, point.x - rect.maxX)
        let dy = max(rect.minY - point.y, 0, point.y - rect.maxY)
        return dx * dx + dy * dy
    }
}

private extension CGPoint {
    var isFinite: Bool { x.isFinite && y.isFinite }
}

private extension CGRect {
    var isFinite: Bool {
        origin.x.isFinite && origin.y.isFinite && width.isFinite && height.isFinite
    }

    func closedContains(_ point: CGPoint) -> Bool {
        point.x >= minX && point.x <= maxX && point.y >= minY && point.y <= maxY
    }
}
