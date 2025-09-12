//
//  DiskImageCacheManager.swift
//  RoomReviewer
//
//  Created by 김상규 on 9/12/25.
//

import Foundation
import CryptoKit

protocol DiskImageCacher {
    func save(data: Data, key: String)
    func load(key: String) -> Data?
}

final class CacheImageFileManager: DiskImageCacher {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    init() {
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheDirectory = cachesDirectory.appendingPathComponent("ImageCache")
        createDirectory()
    }
    
    private func createDirectory() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
        }
    }

    func save(data: Data, key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key.sha256())
        try? data.write(to: fileURL)
    }

    func load(key: String) -> Data? {
        let fileURL = cacheDirectory.appendingPathComponent(key.sha256())
        return try? Data(contentsOf: fileURL)
    }
}

extension String {
    func sha256() -> String {
        let data = Data(self.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
