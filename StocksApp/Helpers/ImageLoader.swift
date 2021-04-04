//
//  ImageLoader.swift
//  StocksApp
//
//  Created by Anton Makeev on 01.04.2021.
//

import Foundation
import UIKit.UIImage
import Combine

public class ImageLoader {
    typealias ImageCache = Cache<URL,UIImage>
    
    public static let shared = ImageLoader()
    private var cache = ImageCache(maximumEntryCount: 505)
    private let saveName: String?
    
    init(saveWithName name: String? = nil) {
        self.saveName = name
        if let name = name {
            do {
                cache = try cache.loadFromDisk(named: name)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func loadImage(from url: URL) -> AnyPublisher<UIImage?, Never> {
        if let image = cache[url] {
            return Just(image).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { (data, response) in UIImage(data: data) }
            .catch { error in Just(nil) }
            .handleEvents( receiveOutput: { [weak self] image in
                guard let image = image else { return }
                self?.cache[url] = image
                if let name = self?.saveName {
                    try? self?.cache.saveToDisk(withName: name)
                }
            })
            .subscribe(on: DispatchQueue.global())
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
}

extension Cache where Key == URL, Value == UIImage {
    
    func saveToDisk(
        withName name: String,
        using fileManager: FileManager = .default
    ) throws {
        let folderURLs = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )

        let urlCache = Cache<URL, URL>()
        // TODO: Продумать как удалять изображения при удалении из кэша
        for key in self.keys {
            if let image = self[key] {
                if let jpeg = image.jpegData(compressionQuality: 0.8) {
                    let imageName = UUID().uuidString
                    let fileURL = folderURLs[0].appendingPathComponent(imageName + ".jpeg")
                    do {
                        try jpeg.write(to: fileURL)
                        urlCache[key] = fileURL
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
        }
        try urlCache.saveToDisk(withName: name)
    }
    
    func loadFromDisk(named name: String, using fileManager: FileManager = .default) throws -> Cache<Key, Value> {
        let folderURLs = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )
        let fileURL = folderURLs[0].appendingPathComponent(name + ".cache")
        let data = try Data(contentsOf: fileURL)
        let cache = try JSONDecoder().decode(Cache<URL, URL>.self, from: data)
        let imageCache = Cache<URL, UIImage>()
        for key in cache.keys {
            if let image = UIImage(contentsOfFile: cache[key]!.path) {
                imageCache[key] = image
            }
        }
        return imageCache
    }
}
