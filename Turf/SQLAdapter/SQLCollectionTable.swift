//
//  SQLCollectionTable.swift
//  Turf
//
//  Created by Jordan Hamill on 24/09/2015.
//  Copyright © 2015 JordanHamill. All rights reserved.
//

import Foundation
import SQLite

internal struct SQLCollectionTable<TPrimaryKey: AllowedPrimaryKeyType> {
    let T: Table
    //TODO Restrict AllowedPrimaryKeyType to a valid SQLite priamry key type (extend for UIntXs)
    let key = Expression<Int>("key")
    let data = Expression<NSData?>("data")
    let metadata = Expression<NSData?>("metadata")

    init(name: String) {
        self.T = Table(name)
    }
}
