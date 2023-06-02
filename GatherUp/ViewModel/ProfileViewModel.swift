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
    @Published var meetingCount: Int = 0
    
    @Published var blockList: [Block] = []
    
    @Published var isBlock: Bool = false
    
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
    func textFunc(introduction:String?,interests:[[Interests]]) {
        guard let currentUID = currentUID else{
            return
        }
        var textArr: [String] = []
        for group in interests {
            for interest in group {
                textArr.append(interest.interestText)
            }
        }
        let docs = db.collection(strUsers).document(currentUID)
        docs.updateData(User.firestoreUpdate(introduction: introduction, interests: textArr))

    }
    
    /// 모임 데이터 가져오기
    func fetchMeetingCount(_ userUID: String?){
        print("fetchMeetingCount")
        guard let userUID else{return}
        Task{
            do{
                let query = db.collection(strMeetings).whereField("hostUID", isEqualTo: userUID)
                let snapshot = try await query.getDocuments()

                let meetings = snapshot.documents.compactMap{ documents -> Meeting? in
                    documents.data(as: Meeting.self)
                }
                meetingCount = meetings.count

            }catch{
                print("에러fetchMeetings")
            }

        }
    }

    /// 차단하기
    func blockUser(_ userUID: String?) {
        print("blockUser")
        guard let currentUID,
              let userUID else{return}
        Task{
            do{
                let block = Block(userUID)
                let ref = db.collection(strUsers).document(currentUID).collection(strBlockList)
                try await ref.addDocument(data: block.firestoreData)
            }catch{
                print("에러!blockUser")
            }
        }
        
    }
    /// 차단한 유저 확인
    func fetchBlockUser(_ userUID: String?) {
        guard let currentUID,
              let userUID else{return}
        Task{
            let col = self.db.collection(self.strUsers).document(currentUID).collection(self.strBlockList)
            let query = col.whereField("blockUID", isEqualTo: userUID)
            let snapshot = try? await query.getDocuments()
            if snapshot?.documents.first != nil {
                await MainActor.run{
                    isBlock = true
                }
            }
        }
    }
    /// 차단한 유저 전부 보기
    func fetchBlockList() {
        guard let currentUID else{return}
        Task{
            let col = self.db.collection(self.strUsers).document(currentUID).collection(self.strBlockList)
            let snapshot = try? await col.getDocuments()
            guard let documents = snapshot?.documents else{return}
            await MainActor.run{
                blockList = documents.compactMap{ document -> Block? in
                    document.data(as: Block.self)
                }
            }
        }
    }
    /// 차단해제
    func unBlockUser(_ blockID: String?) {
        print("blockUser")
        guard let currentUID,
              let blockID else{return}
        
        let ref = db.collection(strUsers).document(currentUID).collection(strBlockList).document(blockID)
        ref.delete()
    }
}
