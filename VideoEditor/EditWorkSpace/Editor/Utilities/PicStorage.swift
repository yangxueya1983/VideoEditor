//
//  PicStorage.swift
//  VideoEditor
//
//  Created by NancyYang on 2024-12-08.
//
import Foundation
import UIKit
import SDWebImage
import CryptoKit

class PicStorage {
    static var shared = PicStorage()
    private var fileManager: FileManager = .default
    private var storagePath: URL {
        return URL.documentsDirectory.appending(path: "VideoEditorAssets")
    }
    
    func containsDataForKey(key: String) -> Bool{
        let url = cachePathForKey(key: key)
        let exists = fileManager.fileExists(atPath: url.path())
        return exists;
    }
    func cacheKeyForURL(url: URL) -> String {
        var finalKey = PicStorage.md5Hash(for: url.absoluteString)
        let ext = url.pathExtension
        if !ext.isEmpty {
            finalKey = finalKey + ".\(ext)"
        }
        return finalKey
    }
    func cachePathForKey(key: String) -> URL {
        let path = storagePath.appending(path: key)
        return path
    }
    
    func save(image: UIImage, key: String) throws -> URL {
        if let data = image.jpegData(compressionQuality: 1.0) {
            let url = try save(data: data, key: key)
            return url
        } else {
            throw errorWithDes(description: "Image jpegData is nil")
        }
    }
    
    //MARK: Image
    func imageForKey(key: String) throws -> UIImage {
        let data = try retrieve(key: key)
        if let image = UIImage(data: data) {
            return image
        }
        throw errorWithDes(description: "Image inited with data is nil")
    }
    
    //MARK: data
    func save(data: Data, key: String) throws -> URL {
        try fileManager.createDirectory(at: storagePath, withIntermediateDirectories: true, attributes: nil)
        
        let path = cachePathForKey(key: key)
        
        if !fileManager.fileExists(atPath: path.path()) {
            try data.write(to: path)
        }
        return path
    }
    
    private func retrieve(key: String) throws -> Data {
        let path = storagePath.appending(path: key)
        
        guard let data = try? Data(contentsOf: path) else {
            throw errorWithDes(description: "No data found for key: \(key)")
        }
        
        return data
    }
    
    private func errorWithDes(description: String) -> NSError {
        NSError(domain: "PicStorage", code: 0, userInfo: [NSLocalizedDescriptionKey : description])
    }
    
    
    static func md5Hash(for string: String) -> String {
        // Convert the input string to data
        let inputData = Data(string.utf8)
        
        // Compute the MD5 digest
        let digest = Insecure.MD5.hash(data: inputData)
        
        // Convert the digest to a hexadecimal string
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}
