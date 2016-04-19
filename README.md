# Turf

Turf is a document store database built entirely in Swift using SQLite.

Built from the ground up to take advantage of Swift's type system, it has full support for persisting any `struct`, `class`, `enum` or even `tuple`.

Turf makes heavy use of generics and Swift 2's protocol constraints to provide a very safe API for reading, writing and query collections.

[![Build Status](https://travis-ci.org/TurfDb/Turf.svg?branch=master)](https://travis-ci.org/TurfDb/Turf)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![MIT License](https://img.shields.io/cocoapods/l/BrightFutures.svg)](LICENSE)

# Features

- 100% support for Swift value types (`struct`, `enum`, `tuple`).
- Type safe collections.
- Non-invasive approach to persisting any model - no subclasses, no protocols.
- Multiple connection support.
- Object caching - Skip deserializing objects if they have previously been deserialized on the same connection
- Thread safety. Turf is safe even across multiple connections. Only one connection can write to the database at any given time yet you can read from multiple threads at the same time!
- Secondary indexing. Index any persisted or computed properties of your models for fast querying.
- Strongly typed queries - No more strings and `NSPredicate`s
- Reactive - Observe changes to any collection with the ability to filter down and watch a specific row change.
- Migrations framework built in. Your requirements change, so rather than forcing you to devise your own migration framework, Turf already has one.


You can play with Turf in [these Playgrounds](https://github.com/TurfDb/Playgrounds).

# Quick Example

```swift

// Set up a collection to persist a tuple
final class PeopleCollection: Collection {
    typealias Value = (name: String, age: UInt)

    let name = "People"
    let schemaVersion: UInt64 = 1
    let valueCacheSize: Int? = nil

    func setUp<Collections: CollectionsContainer>(using transaction: ReadWriteTransaction<Collections>) throws {
        try transaction.registerCollection(self)
    }

    func serializeValue(value: Value) -> NSData {
        let dict = [
            "name": value.name,
            "age": value.age
        ]

        return try! NSJSONSerialization.dataWithJSONObject(dict, options: [])
    }

    func deserializeValue(data: NSData) -> Value? {
        let dict = try! NSJSONSerialization.JSONObjectWithData(data, options: [])
        return (name: dict["name"] as! String, age: dict["age"] as! UInt)
    }
}

// List our available collections

final class Collections: CollectionsContainer {
	let people = PeopleCollection()

	func setUpCollections<Collections: CollectionsContainer>(using transaction: ReadWriteTransaction<Collections>) throws {
		try people.setUp(using: transaction)
	}
}

// Open a database connection

let collections = Collections()
let database = try Database(path: "test.sqlite", collections: collections)
let connection = try database.newConnection()

// Write a person to the people collection

try connection.readWriteTransaction { transaction, collections in
    transaction.readWrite(collections.people)
        .setValue(("Kelsey", 30), forKey: "kelsey")
}

// Read a person back

try connection.readWriteTransaction { transaction, collections in
    let kelsey = transaction.readOnly(collections.people)
        .valueForKey("kelsey")
    print(kelsey)
}

```

# Installation

**Requirements:** Swift 2.2

## Carthage

1. Add the following to your `Cartfile`
> github "TurfDb/Turf"

2. Run `carthage update`

## CocoaPods

*Coming soon*

# Usage

*Coming soon*

# License

Turf is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
