//
//  DataCache.swift
//  
//
//  Created by Arthur Guiot on 08/04/2023.
//

import Foundation
import Combine

public protocol DataCache<Object>: ObservableObject {
    associatedtype Object: RemoteData
    
    var cache: URLCache { get }
    var objectWillChange: ObservableObjectPublisher { get }
    
    func fetch(using request: URLRequest) async throws -> Data
    
    func urlRequests(for request: RemoteRequest<Object.ID>) -> [URLRequest]
}

extension DataCache {
    public var logger: Logger {
        return Logger()
    }
    
    public func pull(for request: RemoteRequest<Object.ID>) -> [Object.ObjectData] {
        let urlRequests = urlRequests(for: request)
        return urlRequests.compactMap { req in
            guard let data = cache.cachedResponse(for: req)?.data else {
                Task.detached {
                    do {
                        let fetchedData = try await self.fetch(using: req)
                        await MainActor.run {
                            self.cache.storeCachedResponse(CachedURLResponse(response: URLResponse(), data: fetchedData), for: req)
                            self.objectWillChange.send()
                        }
                    } catch {
                        self.logger.log(error)
                    }
                }
                return nil
            }
            return Object.object(from: data)
        }
    }
    
    public func pullSingle(for id: Object.ID) -> Object.ObjectData? {
        return pull(for: .id(id)).first
    }
    
    public func removeAllData() {
        cache.removeAllCachedResponses()
        objectWillChange.send()
    }
}

public enum DataCacheError: Error {
    case urlRequestCreationFailed
}

public extension DataCache {
    func fetch(using request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw DataCacheError.urlRequestCreationFailed
        }
        return data
    }
}
