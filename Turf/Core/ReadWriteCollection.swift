//
//  ReadWriteCollection.swift
//  Turf
//
//  Created by Jordan Hamill on 20/09/2015.
//  Copyright © 2015 JordanHamill. All rights reserved.
//

import Foundation
import Milk

public class ReadWriteCollection<TPrimaryKey: AllowedPrimaryKeyType> {
    public let name: String

    private let readWriteTransaction: ReadWriteTransaction

    public init(name: String, readWriteTransaction: ReadWriteTransaction) {
        self.name = name
        self.readWriteTransaction = readWriteTransaction
    }

    public func numberOfKeys() -> UInt {
        return 0
    }

    public func allKeys() -> [TPrimaryKey] {
        return []
    }

    // MARK: Object + Metadata

    public func valueForKey<T: Serializable>(primaryKey: TPrimaryKey) -> T? {
        return nil
    }

    public func metadataForKey<M: Serializable>(primaryKey: String) -> M? {
        return nil
    }

    public func valueAndMetadataForKey<T: Serializable, M: Serializable>(primaryKey: String) -> (T?, M?) {
        return (nil, nil)
    }

    public func setValue<T: Serializable>(value: T, forKey primaryKey: TPrimaryKey) {

    }

    public func setMetadata<M: Serializable>(metadata: M, forKey primaryKey: TPrimaryKey) {

    }

    public func setValue<T: Serializable, M: Serializable>(value: T, metadata: M, forKey primaryKey: String) {
        
    }
}
