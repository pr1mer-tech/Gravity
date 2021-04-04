//
//  File.swift
//  
//
//  Created by Arthur Guiot on 4/4/21.
//

import Foundation

/// General Fetcher type
public typealias Fetcher<T> = (_ callback: @escaping (StateResponse<T>) -> Void) -> Void

/// Fetch Data from URL
public func FetcherURL(url: URL) -> Fetcher<Data> {
    return { callback in
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                callback(StateResponse(error: error ?? URLError(.unknown)))
                return
            }
            
            callback(StateResponse(data: data, error: error))
        }
        
        task.resume()
    }
}

/// Fetch and serialize JSON from URL
public func FetcherJSON(url: URL) -> Fetcher<[String: Any]> {
    return { callback in
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                callback(StateResponse(error: error ?? URLError(.unknown)))
                return
            }
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    callback(StateResponse(error: URLError(.cannotDecodeContentData)))
                    return
                }
                callback(StateResponse(data: json, error: error))
            } catch {
                callback(StateResponse(error: error))
            }
        }
        
        task.resume()
    }
}

/// Fetch and decode JSON from URL
public func FetcherDecodeJSON<Object>(url: URL, type jsonType: Object.Type) -> Fetcher<Object> where Object: Decodable {
    return { callback in
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                callback(StateResponse(error: error ?? URLError(.unknown)))
                return
            }
            do {
                let json = try JSONDecoder().decode(jsonType, from: data)
                callback(StateResponse(data: json, error: error))
            } catch {
                callback(StateResponse(error: error))
            }
        }
        
        task.resume()
    }
}
