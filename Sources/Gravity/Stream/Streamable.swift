//
//  File.swift
//  
//
//  Created by Arthur Guiot on 4/26/21.
//

import Foundation

open class Streamable<Value> {
    public func encode(value: Value) throws -> Data {
        throw GravityError.EncodeError
    }
    
    public func decode(message: Data) throws -> Value {
        throw GravityError.DecodeError
    }
}

public class JSONStreamProcessor<Object>: Streamable<Object> where Object: Codable {
    public override func encode(value: Object) throws -> Data {
        let data = try JSONEncoder().encode(value)
        return data
    }
    
    public override func decode(message: Data) throws -> Object {
        let json = try JSONDecoder().decode(Object.self, from: message)
        return json
    }
}
