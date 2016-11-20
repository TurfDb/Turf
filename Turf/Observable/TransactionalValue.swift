import Foundation

///
/// Represents a `value` and the `transaction` from which it was read.
/// - warning: It is a fatal error to retain `transaction`. You can however use `value` as you wish.
///
public struct TransactionalValue<Value, Collections: CollectionsContainer> {
    public unowned let transaction: ReadTransaction<Collections>
    public let value: Value
}

extension TransactionalValue where Value: Sequence {
    public func map<Mapped>(_ map: (Value) -> Mapped) -> TransactionalValue<Mapped, Collections> {
        return TransactionalValue<Mapped, Collections>(transaction: transaction, value: map(value))
    }

    public func map<MappedElement>(_ map: (Value.Iterator.Element) -> MappedElement) -> TransactionalValue<[MappedElement], Collections> {
        let mappedValues = value.map(map)
        return TransactionalValue<[MappedElement], Collections>(transaction: transaction, value: mappedValues)
    }
}
