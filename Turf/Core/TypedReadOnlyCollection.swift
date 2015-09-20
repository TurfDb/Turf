//
//  TypedReadOnlyCollection.swift
//  Turf
//
//  Created by Jordan Hamill on 20/09/2015.
//  Copyright © 2015 JordanHamill. All rights reserved.
//

import Foundation
import Milk

public class TypedReadOnlyCollection<TPrimaryKey: AllowedPrimaryKeyType, TValue: Serializable, TMetadata, TSerializer: Serializer>: Collection {
    public let name: String

    private let readTransaction: ReadTransaction
    private let serializer: TSerializer.Type

    public init(name: String, readTransaction: ReadTransaction, serializer: TSerializer.Type) {
        self.name = name
        self.readTransaction = readTransaction
        self.serializer = serializer
    }

    public func numberOfKeys() -> UInt {
        return 0
    }

    public func allKeys() -> [TPrimaryKey] {
        return []
    }

    // MARK: Object + Metadata

    public func valueForKey(primaryKey: TPrimaryKey) -> TValue? {
        let data = NSData()
        return TValue.deserialize(try! serializer.fromData(data)!)
    }

    public func metadataForKey(primaryKey: String) -> TValue? {
        return nil
    }

    public func valueAndMetadataForKey(primaryKey: String) -> (TValue?, TMetadata?) {
        return (nil, nil)
    }
}
