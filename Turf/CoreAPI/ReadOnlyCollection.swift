//
//  ReadOnlyCollection.swift
//  Turf
//
//  Created by Jordan Hamill on 20/09/2015.
//  Copyright © 2015 JordanHamill. All rights reserved.
//

import Foundation
import Milk

public class ReadOnlyCollection<TPrimaryKey: AllowedPrimaryKeyType> {
    public let name: String

    private let readTransaction: ReadTransaction

    public init(name: String, readTransaction: ReadTransaction) {
        self.name = name
        self.readTransaction = readTransaction
    }

    public func numberOfKeys() -> UInt {
        return 0
    }

    public func allKeys() -> [TPrimaryKey] {
        return []
    }

    // MARK: Object + Metadata

    public func valueForKey<T: Serializable>(primaryKey: TPrimaryKey) -> T? {
        //TODO Serializer: singular or block based with key for hetrogenous collections?
        return nil
    }

    public func metadataForKey<M: Serializable>(primaryKey: String) -> M? {
        return nil
    }

    public func valueAndMetadataForKey<T: Serializable, M: Serializable>(primaryKey: String) -> (T?, M?) {
        return (nil, nil)
    }
}
