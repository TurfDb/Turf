import Foundation

///
/// Represents a `value` and the `transaction` from which it was read.
/// - warning: It is a fatal error to retain `transaction`. You can however use `value` as you wish.
///
public struct TransactionalValue<Value, Collections: CollectionsContainer> {
    public unowned let transaction: ReadTransaction<Collections>
    public let value: Value
}
