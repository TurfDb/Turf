//
//  TypedReadWriteCollection.swift
//  Turf
//
//  Created by Jordan Hamill on 20/09/2015.
//  Copyright © 2015 JordanHamill. All rights reserved.
//

import Foundation
import Milk

extension Serializer {
    init() {
        
    }
}

public class TypedReadWriteCollection<TPrimaryKey: AllowedPrimaryKeyType, TValue: Serializable, TMetadata: Serializable, TSerializer: Serializer>: Collection {
    public let name: String

    private let readWriteTransaction: ReadWriteTransaction
    private let serializer: TSerializer.Type

    public init(name: String, readWriteTransaction: ReadWriteTransaction, serializer: TSerializer.Type) {
        self.name = name
        self.readWriteTransaction = readWriteTransaction
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

    public func metadataForKey(primaryKey: String) -> TMetadata? {
        return nil
    }

    public func valueAndMetadataForKey(primaryKey: String) -> (TValue?, TMetadata?) {
        return (nil, nil)
    }

    public func setValue(value: TValue, forKey primaryKey: TPrimaryKey) {
        let _ = value.serialize(serializer.init())
    }

    public func setMetadata(metadata: TMetadata, forKey primaryKey: TPrimaryKey) {

    }

    public func setValue(value: TValue, metadata: TMetadata, forKey primaryKey: String) {

    }
}
