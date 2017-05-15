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

/// A single linked list.
///
/// You use a list instead of an array when you need to efficiently insert
/// or remove elements from middle of the collection.
public struct LinkedList<Element>: Collection {
    private var buffer: LinkedListBuffer<Element>
    
    public init() {
        self.buffer = .create(minimumCapacity: 32)
    }
    
    public mutating func insert(_ element: Element) {
        let newCount = count + 1
        if requestUniqueMutableBackingBuffer(minimumCapacity: newCount) != nil {
            self.buffer.insert(element)
        } else {
            var position: Int?
            let buffer: LinkedListBuffer<Element> = .create(minimumCapacity: newCount)
            for e in self {
                position = buffer.insert(e, afterNodeAt: position)
            }
            buffer.insert(element, afterNodeAt: position)
            self.buffer = buffer
        }
    }
    
    public mutating func insert(_ element: Element, afterElementAt index: Int) {
        let newCount = count + 1
        if requestUniqueMutableBackingBuffer(minimumCapacity: count + 1) != nil {
            self.buffer.insert(element, afterNodeAt: index)
        } else {
            var position: Int?
            let buffer: LinkedListBuffer<Element> = .create(minimumCapacity: newCount)
            for i in indices {
                position = buffer.insert(self[i], afterNodeAt: position)
                if index == i {
                    position = buffer.insert(element, afterNodeAt: position)
                }
            }
            self.buffer = buffer
        }
    }
    
    public mutating func remove(at index: Int) -> Element {
        let result = self[index]
        if requestUniqueMutableBackingBuffer(minimumCapacity: count) != nil {
            self.buffer.remove(nodeAt: index)
        } else {
            var position: Int?
            let buffer: LinkedListBuffer<Element> = .create(minimumCapacity: count)
            for i in indices {
                if index != i {
                    position = buffer.insert(self[i], afterNodeAt: position)
                }
            }
            self.buffer = buffer
        }
        return result
    }
    
    public var startIndex: Int {
        let head = self.buffer.header.next
        return self.buffer.hasNode(at: head) ? head : endIndex
    }
    
    public var endIndex: Int {
        return -1
    }
    
    public var capacity: Int {
        return self.buffer.header.capacity
    }
    
    public var count: Int {
        return self.buffer.header.count
    }
    
    public subscript(position: Int) -> Element {
        precondition(self.buffer.hasNode(at: position))
        
        return self.buffer.node(at: position).element
    }
    
    public func index(after i: Int) -> Int {
        precondition(self.buffer.hasNode(at: i))
        
        let next = self.buffer.node(at: i).next
        return self.buffer.hasNode(at: next) ? next : endIndex
    }
    
    private mutating func requestUniqueMutableBackingBuffer(minimumCapacity: Int) -> LinkedListBuffer<Element>? {
        if _fastPath(isKnownUniquelyReferenced(&self.buffer) && capacity >= minimumCapacity) {
            return self.buffer
        }
        return nil
    }
}
