//
//  File.swift
//  
//
//  Created by Arthur Guiot on 4/26/21.
//

import Foundation
/// Subclass this class to create your own stream processor.
///
/// `Streamable` is the class that defines the shared behavior that is common to all data processors. Make sure to define the returned type of object when subclassing `Streamable`. In this example, we'll create a very basic data processor that receives data from the socket and convert it as a plain `String`:

/// ```swift
/// class StringStreamProcessor: Streamable<String> {
///    // Override the encode method
///    override func encode(value: String) throws -> Data {
///        return value.data(using: .utf8)!
///    }
///    // Override the decode method
///    override func decode(message: Data) throws -> String {
///        return String(data: message, encoding: .utf8) ?? "None"
///    }
/// }
/// ```
///
open class Streamable<Value> {
    public init() {}
    
    open func encode(value: Value) throws -> Data {
        throw GravityError.EncodeError
    }
    
    open func decode(message: Data) throws -> Value {
        throw GravityError.DecodeError
    }
}
/// Pre-made JSON object decoder for `GravityStream`
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
