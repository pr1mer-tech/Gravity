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
    
    var cacheDirectoryName: String { get }
    var objectWillChange: ObservableObjectPublisher { get }
    
    func fetch(using request: URLRequest) async throws -> Data
    
    func urlRequests(for request: RemoteRequest<Object.ID>) -> [URLRequest]
}

extension DataCache {
    public var cacheDirectory: URL {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let directoryURL = urls[0].appendingPathComponent(cacheDirectoryName)
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        }
        return directoryURL
    }
    
    public var logger: Logger {
        return Logger()
    }
    
    private func cachedData(for request: URLRequest) -> Data? {
        guard let url = request.url, let fileName = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
            return nil
        }
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        return try? Data(contentsOf: fileURL)
    }
    
    private func storeCachedData(_ data: Data, for request: URLRequest) {
        guard let url = request.url, let fileName = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
            return
        }
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL)
        } catch {
            logger.log(error)
        }
    }
    
    public func pull(for request: RemoteRequest<Object.ID>) -> [Object.ObjectData] {
        let urlRequests = urlRequests(for: request)
        var objects: [Object.ObjectData] = []
        
        for req in urlRequests {
            if let data = cachedData(for: req) {
                let object = Object.object(from: data)
                objects.append(object)
            } else {
                Task.detached {
                    do {
                        let fetchedData = try await self.fetch(using: req)
                        self.storeCachedData(fetchedData, for: req)
                        await MainActor.run {
                            self.objectWillChange.send()
                        }
                    } catch {
                        self.logger.log(error)
                    }
                }
            }
        }
        
        return objects
    }
    
    public func pullSingle(for id: Object.ID) -> Object.ObjectData? {
        return pull(for: .id(id)).first
    }
    
    public func removeAllData() {
        try? FileManager.default.removeItem(at: cacheDirectory)
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
