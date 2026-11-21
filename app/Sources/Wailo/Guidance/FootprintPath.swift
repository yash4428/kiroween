import Foundation
import CoreGraphics

enum FootprintSide: String, Equatable, Sendable {
    case left
    case right
}

struct FootprintMark: Equatable, Sendable {
    let position: CGPoint
    let rotation: CGFloat
    let side: FootprintSide

    static func == (lhs: FootprintMark, rhs: FootprintMark) -> Bool {
        lhs.position.x == rhs.position.x &&
            lhs.position.y == rhs.position.y &&
            lhs.rotation == rhs.rotation &&
            lhs.side == rhs.side
    }
}

enum FootprintPath {
    /// Produces deterministic, approximately arc-length-spaced marks along a curved path.
    static func marks(from start: CGPoint, to target: CGRect, spacing: CGFloat = 34) -> [FootprintMark] {
        guard start.isFinite, target.isFinite else { return [] }
        let target = target.standardized
        let end = CGPoint(x: target.midX, y: target.midY)
        guard end.isFinite else { return [] }

        let dx = end.x - start.x
        let dy = end.y - start.y
        let directLength = hypot(dx, dy)
        if directLength <= .ulpOfOne {
            return [FootprintMark(position: end, rotation: 0, side: .left)]
        }

        let safeSpacing = spacing.isFinite && spacing > 0 ? spacing : 34
        let normal = CGPoint(x: -dy / directLength, y: dx / directLength)
        let bend = min(80, directLength * 0.18)
        let control = CGPoint(x: (start.x + end.x) / 2 + normal.x * bend,
                              y: (start.y + end.y) / 2 + normal.y * bend)

        // A dense deterministic polyline gives stable arc-length sampling without iterative solvers.
        let subdivisions = max(24, min(512, Int(ceil(directLength / 4))))
        var points = [start]
        var cumulative = [CGFloat.zero]
        var length: CGFloat = 0
        for index in 1...subdivisions {
            let t = CGFloat(index) / CGFloat(subdivisions)
            let point = quadratic(start, control, end, t: t)
            length += hypot(point.x - points.last!.x, point.y - points.last!.y)
            points.append(point)
            cumulative.append(length)
        }

        let count = max(1, Int(ceil(length / safeSpacing)))
        var result: [FootprintMark] = []
        for index in 1...count {
            let requested = min(CGFloat(index) * safeSpacing, length)
            let point = interpolate(distance: requested, points: points, cumulative: cumulative)
            let priorDistance = max(0, requested - min(2, safeSpacing / 4))
            let prior = interpolate(distance: priorDistance, points: points, cumulative: cumulative)
            let angle = atan2(point.y - prior.y, point.x - prior.x)
            result.append(FootprintMark(position: point,
                                        rotation: angle.isFinite ? angle : 0,
                                        side: index.isMultiple(of: 2) ? .right : .left))
        }

        let finalAngle = atan2(end.y - control.y, end.x - control.x)
        if let last = result.last, hypot(last.position.x - end.x, last.position.y - end.y) < 0.001 {
            result[result.count - 1] = FootprintMark(position: end,
                                                      rotation: finalAngle.isFinite ? finalAngle : 0,
                                                      side: last.side)
        } else {
            let nextSide: FootprintSide = result.count.isMultiple(of: 2) ? .left : .right
            result.append(FootprintMark(position: end,
                                        rotation: finalAngle.isFinite ? finalAngle : 0,
                                        side: nextSide))
        }
        return result
    }

    private static func quadratic(_ start: CGPoint, _ control: CGPoint, _ end: CGPoint, t: CGFloat) -> CGPoint {
        let inverse = 1 - t
        return CGPoint(x: inverse * inverse * start.x + 2 * inverse * t * control.x + t * t * end.x,
                       y: inverse * inverse * start.y + 2 * inverse * t * control.y + t * t * end.y)
    }

    private static func interpolate(distance: CGFloat, points: [CGPoint], cumulative: [CGFloat]) -> CGPoint {
        guard let upper = cumulative.firstIndex(where: { $0 >= distance }) else { return points.last! }
        guard upper > 0 else { return points[0] }
        let lower = upper - 1
        let segment = cumulative[upper] - cumulative[lower]
        guard segment > 0 else { return points[upper] }
        let t = (distance - cumulative[lower]) / segment
        return CGPoint(x: points[lower].x + (points[upper].x - points[lower].x) * t,
                       y: points[lower].y + (points[upper].y - points[lower].y) * t)
    }
}

private extension CGPoint {
    var isFinite: Bool { x.isFinite && y.isFinite }
}

private extension CGRect {
    var isFinite: Bool { origin.x.isFinite && origin.y.isFinite && width.isFinite && height.isFinite }
}
