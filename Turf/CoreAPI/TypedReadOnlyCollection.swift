//
//  TypedReadOnlyCollection.swift
//  Turf
//
//  Created by Jordan Hamill on 20/09/2015.
//  Copyright © 2015 JordanHamill. All rights reserved.
//

import Foundation
import Milk

public class TypedReadOnlyCollection<TPrimaryKey: AllowedPrimaryKeyType, TValue: Serializable, TMetadata: Serializable, TSerializer: Serializer>: Collection {
    public let name: String

    private let readTransaction: ReadTransaction
    private let serializerType: TSerializer.Type

    public init(name: String, readTransaction: ReadTransaction, serializer: TSerializer.Type) {
        self.name = name
        self.readTransaction = readTransaction
        self.serializerType = serializer
    }

    public func numberOfKeys() -> UInt {
        return readTransaction.connection.databaseAdapter.numberOfKeysInCollectionNamed(name)
    }

    public func allKeys() -> [TPrimaryKey] {
        return readTransaction.connection.databaseAdapter.keysInCollectionNamed(name)
    }

    // MARK: Object + Metadata

    public func valueForKey(primaryKey: TPrimaryKey) -> TValue? {
        if let data = readTransaction.connection.databaseAdapter.valueDataForKey(primaryKey, inCollectionNamed: name),
            let serializer = try! serializerType.init(data: data) {

            return TValue.deserialize(serializer)
        } else {
            return nil
        }
    }

    public func metadataForKey(primaryKey: String) -> TMetadata? {
        if let data = readTransaction.connection.databaseAdapter.valueDataForKey(primaryKey, inCollectionNamed: name),
            let serializer = try! serializerType.init(data: data) {

            return TMetadata.deserialize(serializer)
        } else {
            return nil
        }
    }

    public func valueAndMetadataForKey(primaryKey: String) -> (TValue?, TMetadata?) {
        let datas = readTransaction.connection.databaseAdapter.valueDataAndMetadataDataForKey(primaryKey, inCollectionNamed: name)

        if let valueData = datas.0, let metadataData = datas.1 {
            if let valueSerializer = try! serializerType.init(data: valueData),
                let metadataSerializer = try! serializerType.init(data: metadataData) {
                return (TValue.deserialize(valueSerializer), TMetadata.deserialize(metadataSerializer))
            }

        } else if let valueData = datas.0 {
            if let valueSerializer = try! serializerType.init(data: valueData) {
                return (TValue.deserialize(valueSerializer), nil)
            }
        } else if let metadataData = datas.1 {
            if let metadataSerializer = try! serializerType.init(data: metadataData) {
                return (nil, TMetadata.deserialize(metadataSerializer))
            }
        }

        return (nil, nil)
    }
}
