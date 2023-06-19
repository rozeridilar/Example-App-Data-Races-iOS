//
//  ImageItem+TestHelpers.swift
//  
//
//  Created by Rozeri Dilar on 19.06.2023.
//

import UIKit
@testable import Example_Data_Races_In_Image_Loading

func anImageItem(
    image: UIImage = UIImage(systemName: "photo") ?? UIImage(),
    url: URL = URL(string: "https://image.tmdb.org/t/p/w154/gOnmaxHo0412UVr1QM5Nekv1xPi.jpg")!
) -> ImageItem {
    
    return ImageItem(image: image, url: url)
}
