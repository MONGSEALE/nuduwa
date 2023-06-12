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
    
    @Published var reviews: [Review] = []
    @Published var rating: CGFloat = 0.5
    
    @Published var meetingsWithMemeberOfReview: [Meeting] = []
    
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
    
    /// 멤버리뷰하기
    func createReview(memberUID:String?, meetingID:String?, reviewText: String, progress: CGFloat) {
        print("createReview")
        guard let currentUID, let memberUID, let meetingID else{return}
        print("memberUID:\(memberUID)")
        print("meetingID:\(meetingID)")
        Task{
            do{
                let review = Review(meetingID: meetingID, memberUID: currentUID, reviewText: reviewText, rating: Int(progress*10))
                let reviewListRef = db.collection(strUsers).document(memberUID).collection(strReviewList)
                try await reviewListRef.addDocument(data: review.firestoreData)
                let meetingListRef = db.collection(strUsers).document(currentUID).collection(strMeetingList)
                let query = meetingListRef
                    .whereField("meetingID", isEqualTo: meetingID)
                    .whereField("nonReviewMembers", arrayContains: memberUID)
                let snapshot = try? await query.getDocuments()
                let doc = snapshot?.documents.first
                try await doc?.reference.updateData(MeetingList.createReview(memberUID))
            }catch{
                print("오류!createReview")
            }
        }
    }
    
    /// 리뷰가져오기
    func fetchReview(_ userUID: String?) {
        guard let userUID else{return}
        Task{
            let ref = db.collection(strUsers).document(userUID).collection(strReviewList)
            let snapshot = try? await ref.getDocuments()
            guard let docs = snapshot?.documents else{return}
            
            var reviews = docs.compactMap{ doc -> Review? in
                doc.data(as: Review.self)
            }
            guard reviews.count != 0 else{return}
            let rating = CGFloat(reviews.map{$0.rating}.reduce(0,+) / reviews.count) / 10
            
            // 동시에 여러개 비동기작업 수행 - 동시에 수행 할 필요 없으면 withTaskGroup 안 써도 됨
            let updateReviews = await withTaskGroup(of: Review?.self) { group in
                for review in reviews {
                    group.addTask {
                        // 각각의 리뷰쓴 UID에서 Name과 Image를 가져온다
                        let user = try? await self.getUser(review.memberUID)
                        var updateReview = review
                        updateReview.memberName = user?.userName
                        updateReview.memberImage = user?.userImage
                        return updateReview
                    }
                }
                var updateReviews: [Review] = []
                for await result in group {
                    if let result {
                        updateReviews.append(result)
                    }
                }
                return updateReviews
            }
            
            await MainActor.run{
                self.reviews = updateReviews
                self.rating = rating
                print("rating:\(updateReviews.map{$0.rating}.reduce(0,+)),\(rating)")
            }
        }
    }
    
    /// 프로필에서 리뷰 클릭시 수행할 함수
    ///  사용자가 상대방에게 쓸 수 있는 리뷰를 보여줌(여러 모임에서 만났을 경우 다 보여줌)
    func fetchReviewList(_ userUID: String?){
        guard let currentUID, let userUID else {return}
        Task{
            let meetingListRef = db.collection(strUsers).document(currentUID).collection(strMeetingList)
            let query = meetingListRef.whereField("nonReviewMembers", arrayContains: userUID)
            
            let snapshot = try? await query.getDocuments()
            
            guard let docs = snapshot?.documents else{return}
            let meetingList = docs.compactMap{ doc -> MeetingList? in
                doc.data(as: MeetingList.self)
            }
            print("미팅리뷰리스트:\(meetingList)")
            
            let meetings = await withTaskGroup(of: Meeting?.self) { group in
                for list in meetingList {
                    group.addTask {
                        let meetingRef = self.db.collection(self.strMeetings).document(list.meetingID)
                        let doc = try? await meetingRef.getDocument()
                        return doc?.data(as: Meeting.self)
                    }
                }
                var meetings: [Meeting] = []
                for await result in group {
                    if let result {
                        meetings.append(result)
                    }
                }
                return meetings
            }
            
            await MainActor.run{
                meetingsWithMemeberOfReview = meetings
                print("리뷰미팅:\(meetingsWithMemeberOfReview)")
            }
        }
    }
    
    /// 작성한 리뷰 가져오기
    func fetchCreateReview(_ userUID: String?) {
        guard let userUID else{return}
        Task{
            do{
                let ref = db.collectionGroup(strReviewList)
                let query = ref.whereField("memberUID", isEqualTo: userUID)
                let snapshot = try await query.getDocuments()
                let reviews = snapshot.documents.compactMap{ doc -> Review? in
                    doc.data(as: Review.self)
                }
                await MainActor.run{
                    self.reviews = reviews
                }
            }catch{
                print("오류fetchCreateReview:\(error.localizedDescription)")
                
            }
        }
    }
}
