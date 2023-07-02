//
//  FirebaseImageLoader.swift
//  GatherUp
//
//  Created by DongHyeokHwang on 2023/06/28.
//

import Foundation
import SwiftUI
import PhotosUI
import FirebaseStorage

class FirebaseImageLoader: ObservableObject {
    @Published var image: UIImage?
    private var urlString: String
    
    init(imageUrl: String) {
        self.urlString = imageUrl
        self.load()
    }
    
    func load() {
        if let url = URL(string: urlString) {
                 let task = URLSession.shared.dataTask(with: url) { data, _, _ in
                     guard let data = data else {
                         print("Failed to download image from \(self.urlString)")  // 디버그 메시지 추가
                         return
                     }
                     DispatchQueue.main.async {
                         self.image = UIImage(data: data)
                     }
                 }
                 task.resume()
             } else {
                 print("Invalid URL: \(self.urlString)")  // 디버그 메시지 추가
             }
    }
}

