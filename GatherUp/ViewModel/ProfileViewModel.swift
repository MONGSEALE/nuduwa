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
    
    // 로그아웃
    func logOutUser() {
        Task{
            do{
                // Firebase 로그아웃
                try Auth.auth().signOut()
                // 구글 로그아웃
                GIDSignIn.sharedInstance.signOut()
            }catch{
                await handleError(error)
            }
        }
    }
    
    // 계정 삭제
    func deleteAccount() {
        isLoading = true
        Task{
            do{
                guard let currentUID = currentUID else{return}
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
        
        Task{
            do{
                guard let currentUID = currentUID else{return}
                
                if let userName = userName {
//                    try await db.collection(strUsers).document(currentUID).updateData(["userName": userName])
                    db.collection(strUsers).document(currentUID).updateData(["userName": userName]){ err in
                        guard let err = err else{return}
                        print("수정에러:\(err.localizedDescription)")
                    }
                    print("userName 수정")
                } else {
                    print("엘스")
                }
                if let userImage = userImage {
//                    isAnotherLoading["userImage"] = true
//                    let maxFileSize: Int = 100_000 // 최대 파일 크기 (예: 0.1MB)
//                    var compressionQuality: CGFloat = 1.0 // 초기 압축 품질
//
//                    print("1")
//
//                    guard let image = try await userImage.loadTransferable(type: Data.self) else{return}
//                    var jpegImage: UIImage?
//                    var imageData: Data?
//                    print("2")
//                    if let uiImage = UIImage(data: image) {
//                        jpegImage = uiImage
//                    } else if let pngData = UIImage(data: image)?.pngData() {
//                        if let uiImage = UIImage(data: pngData) {
//                            jpegImage = uiImage
//                        }
//                    } else {
//                        isAnotherLoading["userImage"] = false
//                        check()
//                        return
//                    }
//                    print("3")
//                    if let jpegData = jpegImage?.jpegData(compressionQuality: compressionQuality), jpegData.count > maxFileSize {
//                        imageData = jpegData
//                        while imageData!.count > maxFileSize && compressionQuality > 0.1 {
//                            compressionQuality -= 0.1
//                            imageData = jpegImage?.jpegData(compressionQuality: compressionQuality)
//                        }
//                    } else {
//                        isAnotherLoading["userImage"] = false
//                        check()
//                        return
//                    }
                    print("4")
                    // Firebase Storage에 이미지 업로드를 위해 해당 이미지 데이터를 사용합니다.
                    guard let imageData = try await userImage.loadTransferable(type: Data.self) else{
                         print("에러 imageData")
                         return
                     }
                        let storageRef = Storage.storage().reference().child("Profile_Images").child(currentUID)

                        storageRef.putData(imageData)
                        let downloadURL = try await storageRef.downloadURL()
                        
                        try await db.collection(strUsers).document(currentUID).updateData(["userImage": downloadURL.absoluteString])
                    print("5")
                }
            }catch{
                await handleError(error)
            }
        }
    }
    func textFunc(introduction:String?,interests:[String]) {
        guard let currentUID = currentUID else{
            return
        }
        Task{
            do{
//                var textArr: [String] = []
//                for group in interests {
//                    for interest in group {
//                        textArr.append(interest.interestText)
//                    }
//                }
                let docs = db.collection(strUsers).document(currentUID)
                docs.updateData(User.firestoreUpdate(introduction: introduction, interests: interests))
            }
            catch{
                print("수정오류")
            }
        }
    }

    
}
