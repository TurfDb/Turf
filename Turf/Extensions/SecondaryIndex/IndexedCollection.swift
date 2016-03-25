/**
 Exposes property querying methods on `ReadCollection`s of collections that conform.

 Example
 ```swift
    class FriendsCollection: Collection, IndexedCollection {
         let index: SecondaryIndex<FriendsCollection, IndexedProperties>
         let indexed = IndexedProperties()
 
         let associatedExtensions: [Extension]

         init() {
             index = SecondaryIndex(collectionName: name, properties: indexed)
             associatedExtensions = [index]
         }
 
         func setUp(transaction: ReadWriteTransaction) {
             transaction.registerCollection(self)
             transaction.registerExtension(index)
         }

         struct IndexedProperties: Turf.IndexedProperties {
             let isOnline = IndexedProperty<FriendsCollection, Bool>(name: "isOnline") { return $0.isOnline }
             let name = IndexedProperty<FriendsCollection, String>(name: "name") { return $0.name }

             var allProperties: [CollectionProperty] {
                 return [isOnline, name]
             }
         }
    }
    
    connection.readTransaction { transaction in
        let friendsCollection = transaction.readOnly(collections.Friends)
        for onlineFriend in friendsCollection.findWhere(friendsCollection.indexed.isOnline.equals(true)) {
            print(onlineFriend)
        }
    }
 ```
 */
public protocol IndexedCollection: Collection, ExtendedCollection {
    associatedtype IndexProperties: IndexedProperties

    var index: SecondaryIndex<Self, IndexProperties> { get }
    var indexed: IndexProperties { get }
}
