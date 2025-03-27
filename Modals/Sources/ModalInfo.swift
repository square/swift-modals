import Foundation

/// ``ModalInfo`` stores heterogeneous key value pairs while maintaining strong-typing.
///
/// Users may add to a known ``ModalInfo`` type by registering their own ``ModalInfoKey``.
///
/// ```swift
/// struct ModalElevation: ModalInfoKey {
///     typealias Value = MyElevationEnum
/// }
/// ```
///
/// - SeeAlso: `ViewEnvironment`
public struct ModalInfo {
    /// Create an empty ``ModalInfo`` for a given domain.
    public static func empty() -> ModalInfo {
        .init()
    }

    private var storage: [ObjectIdentifier: Any]

    /// Private empty initializer to make the `empty` environment explicit.
    public init() {
        storage = [:]
    }

    /// Get or set for the given `ModalInfoKey`.
    public subscript<Key: ModalInfoKey>(
        key: Key.Type
    ) -> Key.Value? {
        get {
            storage[ObjectIdentifier(key)] as? Key.Value
        }
        set {
            storage[ObjectIdentifier(key)] = newValue
        }
    }

    /// Update the value for a given key.
    public func setting<Key: ModalInfoKey>(
        key: Key.Type,
        value: Key.Value
    ) -> Self {
        var newInfo = self
        newInfo[key] = value
        return newInfo
    }

    public func setting(
        uniqueKey key: (some UniqueModalInfoKey).Type
    ) -> Self {
        setting(key: key, value: ())
    }

    public func contains(
        _ key: (some ModalInfoKey).Type
    ) -> Bool {
        storage.keys.contains(ObjectIdentifier(key))
    }
}

/// A type used to store values that share a domain.
public protocol ModalInfoKey {

    /// The type of value stored at the key.
    associatedtype Value
}

/// ``UniqueModalInfoKey`` describes a key that is expected to be unique and therefore needs
/// no user-defined valued.
public protocol UniqueModalInfoKey: ModalInfoKey where Value == Void {}
