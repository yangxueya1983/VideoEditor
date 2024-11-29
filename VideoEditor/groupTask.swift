//
//  Untitled.swift
//  VideoEditor
//
//  Created by NancyYang on 2024-11-22.
//
import SwiftUI

struct ImageResult {
    let url: URL
    let image: UIImage?
    let error: Error?
}

func downloadImages(imageURLs: [URL])  async -> [ImageResult] {

    return await withTaskGroup(of: (Int, ImageResult).self) { group in
        var results: [ImageResult] = Array(repeating: ImageResult(url: URL(fileURLWithPath: ""), image: nil, error: nil), count: imageURLs.count)
        
        for (index, url) in imageURLs.enumerated() {
            group.addTask {
                let filename = "\(index).jpeg"
                let (image, error) = await downloadSingleImage(url: url, fileName: filename)
                return (index, ImageResult(url: url, image: image, error: error))
            }
        }
        
        for await (idx,t) in group {
            results[idx] = t
        }
        return results
    }
}


func downloadSingleImage(url: URL, fileName: String = UUID().uuidString) async -> (UIImage?, Error?) {
    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            return (nil, NSError(domain: "ImageDownloadError", code: 0, userInfo: nil))
        }
        let fileURL = URL.temporaryDirectory.appendingPathComponent(fileName)
        print(fileURL)
        try? data.write(to: fileURL)
        return (image, nil)
    } catch {
        return (nil, error)
    }
}
