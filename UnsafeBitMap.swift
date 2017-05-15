// MIT License
//
// Copyright (c) 2017 Alexey Komnin
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

/// A wrapper around a bitmap storage with room for at least `bitCount` bits.
public struct UnsafeBitMap {
    public let values: UnsafeMutablePointer<UInt>
    
    public let bitCount: Int
    
    public static func wordIndex(_ i: Int) -> Int {
        // Note: We perform the operation on UInts to get faster unsigned math
        // (shifts).
        return Int(bitPattern: UInt(bitPattern: i) / UInt(UInt.bitSize()))
    }
    
    public static func bitIndex(_ i: Int) -> UInt {
        // Note: We perform the operation on UInts to get faster unsigned math
        // (shifts).
        return UInt(bitPattern: i) % UInt(UInt.bitSize())
    }
    
    public static func sizeInWords(forSizeInBits bitCount: Int) -> Int {
        return (bitCount + Int.bitSize() - 1) / Int.bitSize()
    }
    
    public init(storage: UnsafeMutablePointer<UInt>, bitCount: Int) {
        self.bitCount = bitCount
        self.values = storage
    }
    
    public var numberOfWords: Int {
        return UnsafeBitMap.sizeInWords(forSizeInBits: bitCount)
    }
    
    public func initializeToZero() {
        values.initialize(to: 0, count: numberOfWords)
    }
    
    public subscript(i: Int) -> Bool {
        get {
            _sanityCheck(i < Int(bitCount) && i >= 0, "index out of bounds")
            let word = values[UnsafeBitMap.wordIndex(i)]
            let bit = word & (1 << UnsafeBitMap.bitIndex(i))
            return bit != 0
        }
        nonmutating set {
            _sanityCheck(i < Int(bitCount) && i >= 0, "index out of bounds")
            let wordIdx = UnsafeBitMap.wordIndex(i)
            let bitMask = 1 << UnsafeBitMap.bitIndex(i)
            if newValue {
                values[wordIdx] = values[wordIdx] | bitMask
            } else {
                values[wordIdx] = values[wordIdx] & ~bitMask
            }
        }
    }
    
    public func findHole() -> Int {
        func findWardIdx() -> Int? {
            for wordIdx in 0..<self.numberOfWords {
                if values[wordIdx] != UInt.max {
                    return wordIdx
                }
            }
            return nil
        }
        guard let wordIdx = findWardIdx() else { return -1 }
        let word = values[wordIdx]
        for i in 0..<UInt.bitSize() {
            let bit = word & UInt(1 << i)
            if bit == 0 {
                return i
            }
        }
        return -1
    }
}

