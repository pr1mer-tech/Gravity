//
//  File.swift
//  
//
//  Created by Arthur Guiot on 4/26/21.
//

import Foundation

public class Streamable<Value> {
    public func encode(value: Value) throws -> Data {
        throw GravityError.EncodeError
    }
    
    public func decode(message: Data) throws -> Value {
        throw GravityError.DecodeError
    }
}
