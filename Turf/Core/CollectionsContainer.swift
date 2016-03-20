/**
 Example
 ```swift
 class Collections: CollectionsContainer {
     let Friends = FriendsCollection()
     let Posts = PostsCollection()

     func setUpCollections(transaction: ReadWriteTransaction) throws {
         try Friends.setUp(transaction)
         try Posts.setUp(transaction)
     }
 }
 
let collections = Collections()
let db = try? Database(path: "sample.sqlite", collections: collections)
 ```
 */
public protocol CollectionsContainer {
    /**
     Called when initializing a `Database`
     - parameter transaction: Can be used to register new collections and extensions
     */
    func setUpCollections(transaction transaction: ReadWriteTransaction)
}
