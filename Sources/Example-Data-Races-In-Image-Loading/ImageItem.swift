//
//  File.swift
//  Example-Data-Races-In-Image-Loading
//
//  Created by Rozeri Dilar on 19.06.2023.
//

import UIKit

public class ImageItem: Hashable {
  private let identifier = UUID()
  public var image: UIImage
  public let url: URL

  public func hash(into hasher: inout Hasher) {
    hasher.combine(identifier)
  }

  public static func == (lhs: ImageItem, rhs: ImageItem) -> Bool {
    return lhs.identifier == rhs.identifier
  }

  public init(image: UIImage, url: URL) {
    self.image = image
    self.url = url
  }
}
