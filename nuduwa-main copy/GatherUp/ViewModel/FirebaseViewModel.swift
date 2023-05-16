//
//  FirebaseViewModel.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/05/09.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

class FirebaseViewModel: ObservableObject {
    /// Firestore용 변수
    let db = Firestore.firestore()
    var docListener: ListenerRegistration?
    /// 콜렉션 이름
    let strUsers = "Users"
    let strMeetings = "Meetings"
    let strMembers = "Members"
    let strMessage = "Message"
    let strChatters = "Chatters"
    let strDMPeople = "DMPeople"
    let strDM = "DM"
    
    /// Firestorage용 변수
    let strProfile_Images = "Profile_Images"

    /// 에러 처리 변수
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    /// 데이터 가져오는 동안 로딩뷰 보여줄 변수
    @Published var isLoading: Bool = false

    @Published var currentUser: User?
    @Published var user: User?

    var currentUID: String? {
       return Auth.auth().currentUser?.uid
    }
    
    deinit {
        removeListener()
    }
    /// 리스너 제거(리소스 확보, 단 자주 켰다껐다하면 리소스 더 들어감)
    func removeListener(){
        if let docListener{
            docListener.remove()
            self.docListener = nil
        }
    }

    /// 유저 데이터 실시간 가져오기
    func userListener(userUID: String) {
        print("userListener")
        Task{
            let doc = db.collection(strUsers).document(userUID)
            docListener = doc.addSnapshotListener { snapshot, error in
                if let error = error{
                    self.firebaseError(error)
                    return
                }
                guard let document = snapshot else{print("No Users");return}
                self.user = try? document.data(as: User.self)
            }
        }
    }
    func currentUserListener() {
        print("userListener")
        isLoading = true
        Task{
            guard let currentUID = currentUID else{return}
            let doc = db.collection(strUsers).document(currentUID)
            docListener = doc.addSnapshotListener { snapshot, error in
                if let error = error{
                    self.firebaseError(error)
                    return
                }
                guard let document = snapshot else{print("No Users");return}
                self.currentUser = try? document.data(as: User.self)
                self.isLoading = false
            }
        }
    }
    
    /// 유저 데이터 한번 가져오기
    func fetchUser(userUID: String?){
        print("fetchUser")
        Task{
            do{
                guard let userUID = userUID else{return}
                let user = try await db.collection(strUsers).document(userUID).getDocument(as: User.self)

                await MainActor.run(body: {
                    self.user = user
                })
            }catch{
                await handleError(error)
            }
        }
    }
    func fetchCurrentUser(){
        print("fetchUser")
        Task{
            do{
                guard let currentUID = currentUID else{return}
                let user = try await db.collection(strUsers).document(currentUID).getDocument(as: User.self)

                await MainActor.run(body: {
                    self.currentUser = user
                })
            }catch{
                await handleError(error)
            }
        }
    }
    
    func fetchUserAsync(userUID: String)async{
        print("fetchUserAsync")
        do{
            let user = try await db.collection(strUsers).document(userUID).getDocument(as: User.self)

            await MainActor.run(body: {
                self.user = user
            })
        }catch{
            await handleError(error)
        }
    }
    func fetchCurrentUserAsync()async{
        print("fetchUserAsync")
        do{
            guard let currentUID = currentUID else{return}
            let user = try await db.collection(strUsers).document(currentUID).getDocument(as: User.self)

            await MainActor.run(body: {
                self.currentUser = user
            })
        }catch{
            await handleError(error)
        }
    }
    
    /// 에러처리
    func handleError(_ error: Error)async{
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        })
    }
    func firebaseError(_ error: Error){
        print(error.localizedDescription)
        isLoading = false
    }
}
