//
//  ProfileViewModel.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/04/05.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import _PhotosUI_SwiftUI

class ProfileViewModel: FirebaseViewModel {
    
    @Published var userProfilePicData: Data?
    
    // MARK: Logging User Out
    func logOutUser() {
        Task{
            do{
                try Auth.auth().signOut()
                GIDSignIn.sharedInstance.signOut()
            }catch{
                await handleError(error)
            }
        }
    }
    
    // MARK: Deleting User Entire Account
    func deleteAccount() {
        isLoading = true
        Task{
            do{
                // Step 1: First Deleting Profile Image From Storage
                let reference = Storage.storage().reference().child(strProfile_Images).child(currentUID())
                try await reference.delete()
                // Step 2 : Deleting Firestore User Document
                try await Firestore.firestore().collection(strUsers).document(currentUID()).delete()
                // Final Step: Deleting Auth Account and Setting Log Status to False
                try await Auth.auth().currentUser?.delete()
                isLoading = false
            } catch {
                await handleError(error)
            }
        }
    }
    
    func updateUser(userName: String = "", userImage: Data = Data()){
        print("updateUser")
        Task{
            do{
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                if userName != "" {
                    try await
                    db.collection(strUsers).document(currentUID()).updateData(["userName": userName])
                    print("userName 수정")
                    changeRequest?.displayName = userName
                    try await changeRequest?.commitChanges()
                }
                if userImage != Data() {
                    let storageRef = Storage.storage().reference().child("Profile_Images").child(currentUID())
                    storageRef.putData(userImage)

                    let downloadURL = try await storageRef.downloadURL()

                    try await db.collection(strUsers).document(currentUID()).updateData(["userImage": downloadURL.absoluteString])
                    print("userImage 수정")
                }
            }catch{
                await handleError(error)
            }
        }
    }

    func imageChaged(photoItem: PhotosPickerItem) {
        print("imageChaged")
        Task{
            do{
                guard let imageData = try await photoItem.loadTransferable(type: Data.self) else{
                    print("에러 imageData")
                    return
                }
                updateUser(userImage: imageData)
            }catch{
                await handleError(error)
            }
        }
    }
}
