//
//  DataCache.swift
//  
//
//  Created by Arthur Guiot on 08/04/2023.
//

import Foundation
import Combine

public class DataCache<Object>: ObservableObject where Object: RemoteRepresentable {
    public let logger = Logger()
    private let cache: URLCache
    
    public init(cache: URLCache = .shared) {
        self.cache = cache
    }
    
    public func push(_ data: [Data], for request: RemoteRequest<Object.ID>) {
        let urlRequests = urlRequests(for: request)
        if urlRequests.count != data.count {
            logger.log(DataCacheError.urlRequestCreationFailed)
            return
        }
        
        for (index, urlRequest) in urlRequests.enumerated() {
            let response = HTTPURLResponse(url: urlRequest.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let cachedResponse = CachedURLResponse(response: response, data: data[index])
            cache.storeCachedResponse(cachedResponse, for: urlRequest)
        }
        
        objectWillChange.send()
    }
    
    public func pull(for request: RemoteRequest<Object.ID>) -> [Data?] {
        let urlRequests = urlRequests(for: request)
        return urlRequests.map { cache.cachedResponse(for: $0)?.data }
    }
    
    public func pop(for request: RemoteRequest<Object.ID>) {
        let urlRequests = urlRequests(for: request)
        urlRequests.forEach { cache.removeCachedResponse(for: $0) }
        objectWillChange.send()
    }
    
    public func pushSingle(_ data: Data, for id: Object.ID) {
        push([data], for: .id(id))
    }
    
    public func pullSingle(for id: Object.ID) -> Data? {
        return pull(for: .id(id)).first ?? nil
    }
    
    public func popSingle(for id: Object.ID) {
        pop(for: .id(id))
    }
    
    public func removeAllData() {
        cache.removeAllCachedResponses()
        objectWillChange.send()
    }
    
    func urlRequests(for request: RemoteRequest<Object.ID>) -> [URLRequest] {
        // Implement your URLRequest creation logic based on the RemoteRequest
        // For example:
        // let urls = ["https://your-api.com/data/\(request.rawValue)/image1", "https://your-api.com/data/\(request.rawValue)/image2"]
        // return urls.map { URLRequest(url: URL(string: $0)!) }
        return []
    }
}

public enum DataCacheError: Error {
    case urlRequestCreationFailed
}
