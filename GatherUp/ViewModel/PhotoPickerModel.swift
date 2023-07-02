//
//  PhotoPickerModel.swift
//  GatherUp
//
//  Created by DongHyeokHwang on 2023/06/27.
//

import Foundation
import SwiftUI
import PhotosUI
import FirebaseStorage
import FirebaseAuth



class PhotoPickerModel: ObservableObject{
    @Published private var selectedImage: [UIImage] = []
    @Published var meetingID: String? = nil
    @Published var imageSelections: [PhotosPickerItem] = []{
        didSet{
            Task { await setImage(from: imageSelections) }
        }
    }
    @StateObject var chatViewModel = ChatViewModel()

    
    
    @MainActor
    private func setImage(from selections:[PhotosPickerItem]) async {
        var images:[UIImage] = []
        var currentUID: String? {
           return Auth.auth().currentUser?.uid
        }
          for selection in selections{
              if let data = try? await selection.loadTransferable(type: Data.self),
                 let uiImage = UIImage(data:data) {
                  images.append(uiImage)
              }
          }
                   selectedImage = images
        let storageRef = Storage.storage().reference()
        for (index, image) in selectedImage.enumerated() {
            // jpegData function called for individual image
            if let imageData = image.jpegData(compressionQuality:0.8) {
                // Create a child reference within the "MeetingChat_Images" folder
                let imageRef = storageRef.child("MeetingChat_Images/\(currentUID ?? "")_\(index)")

                
                // Upload the image to Firebase Storage
                // Please note this is a placeholder code and the actual upload process will be a bit different
                let uploadTask = imageRef.putData(imageData, metadata: nil) { metadata, error in
                    if error == nil && metadata != nil{
                        print("Image uploaded successfully")
                    }
                }
                
                uploadTask.observe(.success) { snapshot in
                    // Upload completed successfully
                    imageRef.downloadURL { (url, error) in
                        guard let downloadURL = url else {
                            // Uh-oh, an error occurred!
                            return
                        }
                        // Now we can use downloadURL
                        self.chatViewModel.sendImage(meetingID:self.meetingID ?? "", imageUrl: downloadURL.absoluteString)
                    }
                }
                
            }
        }
        
       // chatViewModel.sendImage(meetingID:"FPWokAAXRCnuJEPWqtsb", imageUrl:"MeetingChat_Images/\(currentUID ?? "")" )
        
      }
}






