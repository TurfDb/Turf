# Turf

Turf is a document store database built entirely in Swift using SQLite.

Built from the ground up to take advantage of Swift's type system, it has full support for persisting any `struct`, `class`, `enum` or even `tuple`.

Turf makes heavy use of generics and Swift 2's protocol constraints to provide a very safe API for reading, writing and query collections.



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

# Example

*Coming soon*

# Installation

**Requirements:** Swift 2.2

## Carthage

1. Add the following to your `Cartfile`
> github "TurfDb/Turf"

2. Run `cartage update`

## CocoaPods

*Coming soon*

# Usage

*Coming soon*

# License

Turf is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
