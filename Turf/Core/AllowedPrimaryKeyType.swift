//
//  AllowedPrimaryKeyType.swift
//  Turf
//
//  Created by Jordan Hamill on 20/09/2015.
//  Copyright © 2015 JordanHamill. All rights reserved.
//

import Foundation

public protocol AllowedPrimaryKeyType { }

extension Int: AllowedPrimaryKeyType { }
extension Int8: AllowedPrimaryKeyType { }
extension Int16: AllowedPrimaryKeyType { }
extension Int32: AllowedPrimaryKeyType { }
extension Int64: AllowedPrimaryKeyType { }

extension UInt: AllowedPrimaryKeyType { }
extension UInt8: AllowedPrimaryKeyType { }
extension UInt16: AllowedPrimaryKeyType { }
extension UInt32: AllowedPrimaryKeyType { }
extension UInt64: AllowedPrimaryKeyType { }

extension String: AllowedPrimaryKeyType { }
