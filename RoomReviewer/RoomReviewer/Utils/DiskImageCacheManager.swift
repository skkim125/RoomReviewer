//
//  DiskImageCacheManager.swift
//  RoomReviewer
//
//  Created by 김상규 on 9/12/25.
//

//import Foundation
//import CryptoKit
//
//protocol DiskImageCacher {
//    func save(data: Data, key: String)
//    func load(key: String) -> Data?
//}
//
//final class CacheImageFileManager: DiskImageCacher {
//    private let fileManager = FileManager.default
//    private let cacheDirectory: URL
//    private let maxCacheSize: UInt64 = 150 * 1024 * 1024 // 150MB
//    private let cacheManagementQueue = DispatchQueue(label: "com.roomreviewer.cacheManagement", qos: .utility)
//
//    init() {
//        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
//        self.cacheDirectory = cachesDirectory.appendingPathComponent("ImageCache")
//        createDirectory()
//    }
//    
//    private func createDirectory() {
//        if !fileManager.fileExists(atPath: cacheDirectory.path) {
//            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
//        }
//    }
//
//    func save(data: Data, key: String) {
//        let fileURL = cacheDirectory.appendingPathComponent(key.sha256())
//        do {
//            try data.write(to: fileURL)
//            cacheManagementQueue.async { [weak self] in
//                self?.manageCache()
//            }
//        } catch {
//            print("Failed to write to disk cache: \(error)")
//        }
//    }
//
//    func load(key: String) -> Data? {
//        let fileURL = cacheDirectory.appendingPathComponent(key.sha256())
//        
//        if fileManager.fileExists(atPath: fileURL.path) {
//            cacheManagementQueue.async {
//                do {
//                    try self.fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: fileURL.path)
//                } catch {
//                    print("Could not update modification date for \(fileURL.path): \(error)")
//                }
//            }
//        }
//        
//        return try? Data(contentsOf: fileURL)
//    }
//    
//    private func manageCache() {
//        guard let fileURLs = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.totalFileSizeKey, .contentModificationDateKey], options: .skipsHiddenFiles) else {
//            return
//        }
//
//        var totalSize: UInt64 = 0
//        var filesWithDates: [(url: URL, date: Date, size: UInt64)] = []
//
//        for url in fileURLs {
//            do {
//                let resources = try url.resourceValues(forKeys: [.totalFileSizeKey, .contentModificationDateKey])
//                let size = UInt64(resources.totalFileSize ?? 0)
//                let modificationDate = resources.contentModificationDate ?? Date.distantPast
//                totalSize += size
//                filesWithDates.append((url, modificationDate, size))
//            } catch {
//                print("리소스 로드 에러 \(url): \(error)")
//            }
//        }
//
//        if totalSize > maxCacheSize {
//            filesWithDates.sort { $0.date < $1.date }
//
//            let targetSize = UInt64(Double(maxCacheSize) * 0.8)
//            var currentSize = totalSize
//
//            for file in filesWithDates {
//                if currentSize <= targetSize {
//                    break
//                }
//                do {
//                    try fileManager.removeItem(at: file.url)
//                    currentSize -= file.size
//                } catch {
//                    print("캐시 삭제 실패 \(file.url): \(error)")
//                }
//            }
//        }
//    }
//}
//
//extension String {
//    func sha256() -> String {
//        let data = Data(self.utf8)
//        let hashed = SHA256.hash(data: data)
//        return hashed.compactMap { String(format: "%02x", $0) }.joined()
//    }
//}
