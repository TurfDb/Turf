/**
 Collection of indexed properties

 - note: TODO constrain `allProperties` further when Swift supports cyclic protocol definitions
    
    Example
    ```swift
     struct IndexedProperties: Turf.IndexedProperties {
         let isOnline = IndexedProperty<FriendsCollection, Bool>(name: "isOnline") { return $0.isOnline }
         let name = IndexedProperty<FriendsCollection, String>(name: "name") { return $0.name }

         var allProperties: [CollectionProperty] {
             return [isOnline, name]
         }
     }
    ```
 */
public protocol IndexedProperties {
    /// All indexed properties 
    /// - warning: Do not mutate this after registering a SecondaryIndex extension
    var allProperties: [TypeErasedIndexedProperty] { get }
}
