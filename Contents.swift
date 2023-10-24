struct StaticArray<Element> {
  private var storage: Storage
}

// MARK: - StaticArray.Storage

extension StaticArray {
  private final class Storage {
    let count: Int
    let elements: UnsafeMutablePointer<Element>

    convenience init(from other: Storage) {
      self.init(unsafeUninitializedCapacity: other.count) { buffer, count in
        let otherBuffer = UnsafeMutableBufferPointer(start: other.elements, count: other.count)

        (_, count) = buffer.initialize(from: otherBuffer)
      }
    }

    init(unsafeUninitializedCapacity: Int,
         initializingWith initializer: (_ buffer: inout UnsafeMutableBufferPointer<Element>,
                                        _ initializedCount: inout Int) throws -> Void) rethrows
    {
      if unsafeUninitializedCapacity < 0 {
        fatalError("Can't construct StaticArray with count < 0")
      }

      self.elements = UnsafeMutablePointer<Element>.allocate(capacity: unsafeUninitializedCapacity)

      var count = unsafeUninitializedCapacity
      var buffer = UnsafeMutableBufferPointer(start: self.elements, count: count)

      try initializer(&buffer, &count)

      self.count = count
    }

    deinit {
      self.elements.deinitialize(count: self.count)
      self.elements.deallocate()
    }
  }
}

// MARK: - Initialization

extension StaticArray {
  init(repeating: Element, count: Int) {
    self.init(unsafeUninitializedCapacity: count) { buffer, _ in
      buffer.initialize(repeating: repeating)
    }
  }

  init(
    unsafeUninitializedCapacity: Int,
    initializingWith initializer: (_ buffer: inout UnsafeMutableBufferPointer<Element>,
                                   _ initializedCount: inout Int) throws -> Void
  ) rethrows {
    self.storage = try Storage(
      unsafeUninitializedCapacity: unsafeUninitializedCapacity,
      initializingWith: initializer
    )
  }
}

// MARK: - Collection

extension StaticArray: Collection {
  var startIndex: Int {
    return 0
  }

  var endIndex: Int {
    return self.storage.count
  }

  func index(after i: Int) -> Int {
    return i + 1
  }

  subscript(_ index: Int) -> Element {
    get {
      guard self.indices.contains(index) else {
        fatalError("Index out of range")
      }

      return self.storage.elements[index]
    }

    set(element) {
      guard self.indices.contains(index) else {
        fatalError("Index out of range")
      }

      if !isKnownUniquelyReferenced(&self.storage) {
        self.storage = Storage(from: self.storage)
      }

      self.storage.elements[index] = element
    }
  }
}

// MARK: - Equatable

extension StaticArray: Equatable where Element: Equatable {
  static func == (lhs: Self, rhs: Self) -> Bool {
    return lhs.elementsEqual(rhs)
  }
}

// MARK: - Operators

extension StaticArray {
  static func + (lhs: Self, rhs: Self) -> Self {
    return Self(unsafeUninitializedCapacity: lhs.count + rhs.count) { buffer, _ in
      for index in 0..<lhs.count {
        buffer[index] = lhs[index]
      }

      for index in 0..<rhs.count {
        buffer[lhs.count + index] = rhs[index]
      }
    }
  }
}

let lhs = StaticArray(repeating: "", count: 3)
let rhs = StaticArray(repeating: "", count: 3)
let actual = lhs + rhs
let expected = StaticArray(repeating: "", count: 6)

expected == actual
