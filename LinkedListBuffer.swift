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


internal struct LinkedListHeader {
    let capacity : Int
    var count : Int = 0
    var next : Int = -1
    let bitmap : UnsafeBitMap
    
    init(capacity: Int, bitmap: UnsafeBitMap) {
        self.capacity = capacity
        self.bitmap = bitmap
    }
}

internal struct LinkedListNode<Element> {
    let element: Element
    var next: Int
}

class LinkedListBuffer<Element> : ManagedBuffer<LinkedListHeader, UInt> {
    final class func create(minimumCapacity: Int) -> LinkedListBuffer<Element> {
        let bitmapSize = UnsafeBitMap.sizeInWords(forSizeInBits: minimumCapacity)
        let bitmapCapacity = bitmapSize * type(of: bitmapSize).bitSize()
        let capacity = (MemoryLayout<LinkedListNode<Element>>.stride * bitmapCapacity + bitmapSize).round(with: MemoryLayout<UInt>.alignment) / MemoryLayout<UInt>.stride
        let p = self.create(minimumCapacity: capacity) { buffer in
            let bitmap = buffer.withUnsafeMutablePointerToElements({ UnsafeBitMap(storage: $0.advanced(by: buffer.capacity - bitmapSize), bitCount: bitmapCapacity)
            })
            bitmap.initializeToZero()
            return LinkedListHeader(capacity: bitmap.bitCount, bitmap: bitmap)
        }
        return unsafeDowncast(p, to: self)
    }
    
    final func hasNode(at position: Int) -> Bool {
        return position >= 0 && position < header.capacity && header.bitmap[position]
    }
    
    final func node(at position: Int) -> LinkedListNode<Element> {
        precondition(position >= 0 && position < header.capacity)
        precondition(header.bitmap[position])
        
        let cap = header.capacity
        return withUnsafeMutablePointerToElements{
            $0.withMemoryRebound(to: LinkedListNode<Element>.self, capacity: cap, { $0[position] })
        }
    }
    
    @discardableResult
    final func insert(_ element: Element, afterNodeAt position: Int?) -> Int {
        guard let position = position else {
            return insert(element)
        }

        return withUnsafeMutablePointers { hptr, eptr in
            let hole = hptr.pointee.bitmap.findHole()
            assert(hole != -1, "Failed to find a hole in a buffer")
            hptr.pointee.bitmap[hole] = true
            eptr.withMemoryRebound(to: LinkedListNode<Element>.self, capacity: hptr.pointee.capacity, { eptr in
                let oldHead = eptr[position].next
                let newNode = LinkedListNode(element: element, next: hasNode(at: oldHead) ? oldHead : -1)
                eptr.advanced(by: hole).initialize(to: newNode)
                eptr[position].next = hole
            })
            hptr.pointee.count += 1
            return hole
        }
    }
    
    @discardableResult
    final func insert(_ element: Element) -> Int {
        return withUnsafeMutablePointers { hptr, eptr in
            let hole = hptr.pointee.bitmap.findHole()
            assert(hole != -1, "Failed to find a hole in a buffer")
            let oldHead = hptr.pointee.next
            let newNode = LinkedListNode(element: element, next: hasNode(at: oldHead) ? oldHead : -1)
            hptr.pointee.bitmap[hole] = true
            eptr.withMemoryRebound(to: LinkedListNode<Element>.self, capacity: hptr.pointee.capacity, { $0.advanced(by: hole).initialize(to: newNode) })
            hptr.pointee.next = hole
            hptr.pointee.count += 1
            return hole
        }
    }
    
    final func remove(nodeAt position: Int) {
        withUnsafeMutablePointers { hptr, eptr in
            let hole = eptr.withMemoryRebound(to: LinkedListNode<Element>.self, capacity: hptr.pointee.capacity, { eptr -> Int in
                let next = eptr[position].next
                if hasNode(at: next) {
                    eptr.advanced(by: position).moveAssign(from: eptr.advanced(by: next), count: 1)
                    return next
                } else {
                    eptr.advanced(by: position).deinitialize()
                    return position
                }
            })
            hptr.pointee.bitmap[hole] = false
            hptr.pointee.count -= 1
        }
    }
}
