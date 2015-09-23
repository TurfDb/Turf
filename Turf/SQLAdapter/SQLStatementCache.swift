//
//  SQLStatementCache.swift
//  Turf
//
//  Created by Jordan Hamill on 23/09/2015.
//  Copyright © 2015 JordanHamill. All rights reserved.
//

import Foundation
import SQLite

class SQLStatementCache {
    private let cache: Cache<Statement>

    init() {
        cache = Cache(capacity: 10)
    }

    func query(key key: String, @autoclosure query: () -> Statement) -> Statement {
        if let preparedStatement = cache[key] {
            return preparedStatement
        } else {
            let statement = query()
            cache[key] = statement
            return statement
        }
    }
}
