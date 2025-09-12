//
//  ImageFileManager.swift
//  RoomReviewer
//
//  Created by 김상규 on 9/11/25.
//

import UIKit
import CryptoKit

protocol ImageFileManaging {
    func saveImage(image: Data, urlString: String)
    func loadImage(urlString: String) -> UIImage?
    func deleteImage(urlString: String)
}

final class ImageFileManager: ImageFileManaging {
    private let fileManager = FileManager.default
    private let imageDirectory: URL

    init() {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        imageDirectory = documentsDirectory.appendingPathComponent("SaveImage")
        
        createDirectory()
    }

    private func createDirectory() {
        if !fileManager.fileExists(atPath: imageDirectory.path) {
            do {
                try fileManager.createDirectory(at: imageDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("디렉토리 생성 실패: \(error)")
            }
        }
    }
    
    private func fileName(for urlString: String) -> String {
        let data = Data(urlString.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    func saveImage(image: Data, urlString: String) {
        let name = fileName(for: urlString)
        let fileURL = imageDirectory.appendingPathComponent(name)
        print(fileURL.absoluteString)
        
        do {
            try image.write(to: fileURL)
        } catch {
            print("이미지 저장 실패: \(error)")
        }
    }

    func loadImage(urlString: String) -> UIImage? {
        let name = fileName(for: urlString)
        let fileURL = imageDirectory.appendingPathComponent(name)
        guard let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) else {
            return nil
        }
        return image
    }

    func deleteImage(urlString: String) {
        let name = fileName(for: urlString)
        let fileURL = imageDirectory.appendingPathComponent(name)
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(at: fileURL)
            } catch {
                print("이미지 삭제 실패: \(error)")
            }
        }
    }
}
