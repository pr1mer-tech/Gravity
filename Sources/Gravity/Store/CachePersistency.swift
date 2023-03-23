//
//  CachePersistency.swift
//  
//
//  Created by Arthur Guiot on 22/03/2023.
//

import Foundation

protocol CacheDecodable: Codable {
    init(referenceID: String)
    var reference: String { get }
    static func cacheURL(for reference: String) -> URL
}

extension CacheDecodable {
    init(reference: String) throws {
        // Check if file exists
        let fileManager = FileManager.default
        let url = Self.cacheURL(for: reference)
        
        if fileManager.fileExists(atPath: url.path) {
            // File exists
            let data = try Data(contentsOf: url)
            self = try JSONDecoder().decode(Self.self, from: data)
        } else {
            self.init(referenceID: reference)
        }
    }
}
extension Cache: CacheDecodable {
    convenience init(referenceID: String) {
        self.init(reference: referenceID, dateProvider: Date.init, entryLifetime: 12 * 60 * 60, maximumEntryCount: 50)
    }
    
    static func cacheURL(for reference: String) -> URL {
        let folderURLs = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )
        
        return folderURLs[0].appendingPathComponent(reference + ".cache")
    }
    
    var cacheURL: URL {
        Cache.cacheURL(for: reference)
    }
    
    func saveToDisk() throws {
        let data = try JSONEncoder().encode(self)
        try data.write(to: cacheURL)
    }
}
