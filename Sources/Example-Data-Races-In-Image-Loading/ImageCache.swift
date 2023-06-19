//
//  ImageCache.swift
//  Example-Data-Races-In-Image-Loading
//
//  Created by Rozeri Dilar on 19.06.2023.
//

import UIKit

public class ImageCache {
    private let urlSession: URLSession
    private let cachedImages = NSCache<NSURL, UIImage>()
    private var loadingResponses = [NSURL: [(ImageItem, UIImage?) -> Swift.Void]]()
    private var runningRequests = [NSURL: URLSessionDataTask]()

    private let syncQueue = DispatchQueue(label: "Queue to sync mutation")

    public final func image(url: NSURL) -> UIImage? {
        syncQueue.sync {
            return cachedImages.object(forKey: url)
        }
    }

    public init(session: URLSession = URLSession.shared,
                totalCostLimit: Int = 100 * 1024 * 1024) {
        self.urlSession = session
        cachedImages.totalCostLimit = totalCostLimit
    }

    public final func load(
        url: NSURL,
        item: ImageItem,
        queue: DispatchQueue = .main,
        completion: @escaping (ImageItem, UIImage?) -> Swift.Void
    ) {

        if let cachedImage = image(url: url) {
            queue.async { [weak self] in
                guard self != nil else { return }

                completion(item, cachedImage)
            }
            return
        }

        syncQueue.sync {
            if self.loadingResponses[url] != nil {
                self.loadingResponses[url]?.append(completion)
                return
            } else {
                self.loadingResponses[url] = [completion]
            }
        }

        let task = urlSession.dataTask(with: url as URL) { [weak self] data, _, error in

            guard let self = self,
                  let responseData = data,
                  let image = UIImage(data: responseData),
                  let blocks = self.loadingResponses[url],
                  error == nil
            else {
                queue.async { [weak self] in
                    guard self != nil else { return }

                    completion(item, nil)
                }
                return
            }

            self.syncQueue.sync {
                self.cachedImages.setObject(image, forKey: url, cost: responseData.count)
            }

            for block in blocks {
                queue.async { [weak self] in
                    guard self != nil else { return }

                    block(item, image)
                }
                return
            }
        }

        task.resume()

        syncQueue.sync {
            self.runningRequests[url] = task
        }
    }

    public func cancelLoad(_ url: NSURL) {
        syncQueue.sync {
            self.runningRequests[url]?.cancel()
            self.runningRequests.removeValue(forKey: url)
        }
    }
}
