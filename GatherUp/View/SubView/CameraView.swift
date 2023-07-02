//
//  CameraView.swift
//  GatherUp
//
//  Created by DongHyeokHwang on 2023/07/01.
//

import SwiftUI
import UIKit
import FirebaseStorage
import FirebaseAuth

struct CameraView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var image: UIImage?
    

    
    func makeUIViewController(context: UIViewControllerRepresentableContext<CameraView>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<CameraView>) {

    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView
        
        var currentUID: String? {
           return Auth.auth().currentUser?.uid
        }

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.isPresented = false
        }
        
        private func saveAndSendImage(_ image: UIImage) {
              let storageRef = Storage.storage().reference()
              if let imageData = image.jpegData(compressionQuality:0.8) {
                  let imageRef = storageRef.child("MeetingChat_Images/\(currentUID ?? "")_0")

                  let uploadTask = imageRef.putData(imageData, metadata: nil) { metadata, error in
                      if error == nil && metadata != nil {
                          print("Image uploaded successfully")
                      }
                  }

                  uploadTask.observe(.success) { snapshot in
                      imageRef.downloadURL { (url, error) in
                          guard let downloadURL = url else {
                              // Uh-oh, an error occurred!
                              return
                          }
                          // Here you need a reference to your ChatViewModel.
                          // You might want to add it to your CameraView and pass it here.
                          let chatViewModel = ChatViewModel()
                          chatViewModel.sendImage(meetingID:"FPWokAAXRCnuJEPWqtsb", imageUrl: downloadURL.absoluteString)
                      }
                  }
              }
          }
        
    }
}
