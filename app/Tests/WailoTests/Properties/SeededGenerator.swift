import Foundation
import CoreGraphics

struct SeededGenerator {
    private(set) var state: UInt64
    let seed: UInt64

    init(seed: UInt64) { self.seed = seed; state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    mutating func bool() -> Bool { next() & 1 == 0 }
    mutating func int(_ range: ClosedRange<Int>) -> Int {
        range.lowerBound + Int(next() % UInt64(range.count))
    }
    mutating func double(_ range: ClosedRange<Double>) -> Double {
        let unit = Double(next() >> 11) / Double(UInt64.max >> 11)
        return range.lowerBound + unit * (range.upperBound - range.lowerBound)
    }
    mutating func cg(_ range: ClosedRange<CGFloat>) -> CGFloat {
        CGFloat(double(Double(range.lowerBound)...Double(range.upperBound)))
    }
    mutating func point(_ range: ClosedRange<CGFloat> = -4_000...4_000) -> CGPoint {
        CGPoint(x: cg(range), y: cg(range))
    }
    mutating func rect(origin: ClosedRange<CGFloat> = -2_000...2_000,
                       size: ClosedRange<CGFloat> = 0.1...1_500) -> CGRect {
        CGRect(x: cg(origin), y: cg(origin), width: cg(size), height: cg(size))
    }
    mutating func ascii(maxLength: Int = 60) -> String {
        let alphabet = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -_!?.,")
        return String((0..<int(0...maxLength)).map { _ in alphabet[int(0...(alphabet.count - 1))] })
    }
}

func propertyContext(seed: UInt64, case index: Int, values: Any...) -> String {
    "seed=\(seed) case=\(index) values=\(values)"
}
