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
                let reference = Storage.storage().reference().child(strProfile_Images).child(currentUID)
                try await reference.delete()
                // Step 2 : Deleting Firestore User Document
                try await Firestore.firestore().collection(strUsers).document(currentUID).delete()
                // Final Step: Deleting Auth Account and Setting Log Status to False
                try await Auth.auth().currentUser?.delete()
                isLoading = false
            } catch {
                await handleError(error)
            }
        }
    }
    
    func editUser(userName: String?, userImage: PhotosPickerItem?){
        print("updateUser")
        isLoading = true
        Task{
            do{
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                
                let dispatchGroup = DispatchGroup() // DispatchGroup 생성
                
                if let userName = userName {
                    dispatchGroup.enter() // DispatchGroup에 진입
                    db.collection(strUsers).document(currentUID).updateData(["userName": userName]){ _ in
                        changeRequest?.displayName = userName
                        changeRequest?.commitChanges()
                        print("userName 수정")
                        dispatchGroup.leave() // DispatchGroup에서 나옴
                    }
                }
                if let userImage = userImage {
                    guard let imageData = try await userImage.loadTransferable(type: Data.self) else{
                        print("에러 imageData")
                        return
                    }
                    let storageRef = Storage.storage().reference().child("Profile_Images").child(currentUID)
                    storageRef.putData(imageData)
                    
                    let downloadURL = try await storageRef.downloadURL()
                    
                    dispatchGroup.enter() // DispatchGroup에 진입
                    db.collection(strUsers).document(currentUID).updateData(["userImage": downloadURL.absoluteString]){ _ in
                        print("userImage 수정")
                        dispatchGroup.leave() // DispatchGroup에서 나옴
                    }
                }
                dispatchGroup.notify(queue: .main) { // DispatchGroup에 속한 모든 작업이 끝났을 때 호출됨
                    self.isLoading = false
                }
            }catch{
                await handleError(error)
            }
            
        }
    }

//    func imageChaged(photoItem: PhotosPickerItem) {
//        print("imageChaged")
//        Task{
//            do{
//                guard let imageData = try await photoItem.loadTransferable(type: Data.self) else{
//                    print("에러 imageData")
//                    return
//                }
//                editUser(userImage: imageData)
//            }catch{
//                await handleError(error)
//            }
//        }
//    }
}
