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
    private let cache = ImageCache()
    
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
            })
            .subscribe(on: DispatchQueue.global())
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
}
