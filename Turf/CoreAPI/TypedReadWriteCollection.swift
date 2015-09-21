//
//  TypedReadWriteCollection.swift
//  Turf
//
//  Created by Jordan Hamill on 20/09/2015.
//  Copyright © 2015 JordanHamill. All rights reserved.
//

import Foundation
import Milk

public class TypedReadWriteCollection<TPrimaryKey: AllowedPrimaryKeyType, TValue: Serializable, TMetadata: Serializable, TSerializer: Serializer>: Collection {
    public let name: String

    private let transaction: ReadWriteTransaction
    private let serializerType: TSerializer.Type

    public init(name: String, readWriteTransaction: ReadWriteTransaction, serializer: TSerializer.Type) {
        self.name = name
        self.transaction = readWriteTransaction
        self.serializerType = serializer
    }

    public func numberOfKeys() -> UInt {
        return transaction.connection.databaseAdapter.numberOfKeysInCollectionNamed(name)
    }

    public func allKeys() -> [TPrimaryKey] {
        return transaction.connection.databaseAdapter.keysInCollectionNamed(name)
    }

    // MARK: Object + Metadata

    public func valueForKey(primaryKey: TPrimaryKey) -> TValue? {
        if let data = transaction.connection.databaseAdapter.valueDataForKey(primaryKey, inCollectionNamed: name),
            let serializer = try! serializerType.init(data: data) {

                return TValue.deserialize(serializer)
        } else {
            return nil
        }
    }

    public func metadataForKey(primaryKey: String) -> TMetadata? {
        if let data = transaction.connection.databaseAdapter.valueDataForKey(primaryKey, inCollectionNamed: name),
            let serializer = try! serializerType.init(data: data) {

                return TMetadata.deserialize(serializer)
        } else {
            return nil
        }
    }

    public func valueAndMetadataForKey(primaryKey: String) -> (TValue?, TMetadata?) {
        let datas = transaction.connection.databaseAdapter.valueDataAndMetadataDataForKey(primaryKey, inCollectionNamed: name)

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

    public func setValue(value: TValue, forKey primaryKey: TPrimaryKey) {
        let serializer = serializerType.init()
        value.serialize(serializer)
        let data = try! serializer.toData()
        transaction.connection.databaseAdapter.setValueData(data, forKey: primaryKey, inCollectionNamed: name)
    }

    public func setMetadata(metadata: TMetadata, forKey primaryKey: TPrimaryKey) {
        let serializer = serializerType.init()
        metadata.serialize(serializer)
        let data = try! serializer.toData()
        transaction.connection.databaseAdapter.setMetadataData(data, forKey: primaryKey, inCollectionNamed: name)
    }

    public func setValue(value: TValue, metadata: TMetadata, forKey primaryKey: String) {
        let valueSerializer = serializerType.init()
        let metadataSerializer = serializerType.init()

        value.serialize(valueSerializer)
        metadata.serialize(metadataSerializer)

        let valueData = try! valueSerializer.toData()
        let metadataData = try! metadataSerializer.toData()

        transaction.connection.databaseAdapter.setValueData(valueData, metadata: metadataData, forKey: primaryKey, inCollectionNamed: name)
    }

    public func removeAllValues() {
        transaction.connection.databaseAdapter.removeAllRowsInCollectionNamed(name)
    }

    public func removeValuesForKeys(keys: [TPrimaryKey]) {
        for key in keys {
            transaction.connection.databaseAdapter.removeRowWithKey(key, inCollectionNamed: name)
        }
    }
}
