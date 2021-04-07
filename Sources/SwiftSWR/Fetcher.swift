//
//  File.swift
//  
//
//  Created by Arthur Guiot on 4/4/21.
//

import Foundation

/// General Fetcher type
public class Fetcher<Fetchable, Decoded> where Fetchable: Hashable {
    /// Implement decode function to convert data to any type
    public func decode(data: Data) throws -> Decoded {
        throw SWRError.DecodeError
    }
    /// Implement fetch function to fetch from the network
    public func fetch(location: Fetchable, callback: @escaping (Data?, Error?) -> Void) throws {
        throw SWRError.FetchError
    }
}

/// Fetch and serialize JSON from URL
public class FetcherJSON: Fetcher<URL, [String: Any]> {
    public override func decode(data: Data) throws -> [String : Any] {
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        guard let dictionary = json as? [String: Any] else { throw SWRError.DecodeError }
        return dictionary
    }
    
    public override func fetch(location url: URL, callback: @escaping (Data?, Error?) -> Void) throws {
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            callback(data, error)
        }
        
        task.resume()
    }
}

/// Fetch and serialize JSON from URL
public class FetcherDecodeJSON<Object>: Fetcher<URL, Object> where Object: Decodable {
    public override func decode(data: Data) throws -> Object {
        let json = try JSONDecoder().decode(Object.self, from: data)
        return json
    }
    
    public override func fetch(location url: URL, callback: @escaping (Data?, Error?) -> Void) throws {
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            callback(data, error)
        }
        
        task.resume()
    }
}
