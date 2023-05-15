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
    var listeners: [String : ListenerRegistration] = [:]
    /// 콜렉션 이름
    /// Users 콜렉션
    let strUsers = "Users"
    let strChatters = "DMList"
    let strJoinMeetings = "JoinMeetings"
    /// Meetings 콜렉션
    let strMeetings = "Meetings"
    let strMembers = "Members"
    let strMessage = "Message"
    /// DMPeople 콜렉션
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
    enum SomeError: Error {
        case miss
        case error
    }
    
    deinit {
        removeListeners()
    }
    /// 리스너 제거(리소스 확보, 단 자주 켰다껐다하면 리소스 더 들어감)
    func removeListeners() {
        if !listeners.isEmpty {
            for (_, listener) in listeners {
                listener.remove()
            }
            listeners.removeAll()
        }
    }

    // 유저 이름과 이미지만 가져오기
    func fetchUserData(_ userUID: String?) {
        print("fetchUserData")
        Task{
            do{
                let userData = try await getUserData(userUID)
                self.user = User.convertUserData(userData)
            }catch{
                handleErrorTask(error)
            }
        }
    }
    func getUserData(_ userUID: String?) async throws -> UserData {
        print("getUserData")
        do{
            guard let userUID = userUID else{throw SomeError.miss}
            let doc = db.collection(strUsers).document(userUID)
            let userData: UserData? = try await doc.getDocument(as: UserData.self)
            guard let userData = userData else{throw SomeError.miss}
            return userData
        }catch{
            throw error
        }
    }

    /// 유저 데이터 한번 가져오기
    func fetchUser(_ userUID: String?) {
        print("fetchUser")
        Task{
            do{
                let user = try await getUser(userUID)
                self.user = user
            }catch{
                await handleError(error)
            }
        }
    }
    func getUser(_ userUID: String?) async throws -> User {
        print("getUserData")
        do{
            guard let userUID = userUID else{throw SomeError.miss}
            let doc = db.collection(strUsers).document(userUID)
            let user: User? = try await doc.getDocument(as: User.self)
            guard let user = user else{throw SomeError.miss}
            return user
        }catch{
            throw error
        }
    }

    /// 유저 데이터 실시간 가져오기
    func userListener(_ userUID: String) {
        print("userListener")
        Task{
            let doc = db.collection(strUsers).document(userUID)
            let listener = doc.addSnapshotListener { snapshot, error in
                if let error = error{
                    self.handleErrorTask(error)
                    return
                }
                guard let document = snapshot else{print("No Users");return}
                self.user = try? document.data(as: User.self)
            }
            listeners[doc.path] = listener
        }
    }
    
    /// 에러처리
    func handleError(_ error: Error, isShowError: Bool = false) async {
        print("에러: \(error.localizedDescription)")
        await MainActor.run {
            if isShowError {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
    func handleErrorTask(_ error: Error, isShowError: Bool = false) {
        print("에러: \(error.localizedDescription)")
        if isShowError {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
}


/*
func fetchUserData(_ userUID: String)async throws -> UserData {
        print("fetchUserData:\(userUID)")
        do {
            let document = try await db.collection(strUsers).document(userUID).getDocument()
            let name = document.data()?["userName"] as? String ?? ""
            let imageUrl = document.data()?["userImage"] as? String ?? ""
            let image = URL(string: imageUrl)
            return UserData(userName: name, userImage: image!)
        } catch {
            print("에러 fetchUserData: \(error)")
            return UserData(userName: "name", userImage: URL(string:"image"))
        }
    }
func getDocument<T: FirestoreConvertible>(docRef: DocumentReference) async throws -> T? {        
        do {
            let document = try await docRef.getDocument()
            return document.data(as: T.self)
        } catch {
            throw error
        }
    }
    func getDocuments<T: FirestoreConvertible>(colRef: CollectionReference) async throws -> [T] { 
        do {
            let querySnapshot = try await colRef.getDocuments()
            guard let querySnapshot = querySnapshot else{throw}

            return documents.compactMap { document -> T? in
                document.data(as: T.self)
            }
        } catch {
            throw error
        }
    }
func collectionListener<T: FirestoreConvertible>(colRef: CollectionReference, completion: @escaping ([T]?, Error?) -> Void) -> ListenerRegistration {
        return colRef.addSnapshotListener { querySnapshot, error in
            if let error = error {
                completion(nil, error)
                return
            }   
            
            guard let documents = querySnapshot?.documents else {
                completion([], nil)
                return
            }
            
            let items = documents.compactMap { document -> T? in
                document.data(as: T.self)
            }
            
            completion(items, nil)
        }
    }
    func membersListener(meetingID: String) {
        let colRef = db.collection(strMeetings).document(meetingID).collection(strMembers)
        
        let registration = collectionListener(colRef) { (members: [Member]?, error) in
            if let error = error {
                handleError(error)
                return
            }
            
            guard let members = members else {
                // Handle empty members data
                return
            }
            
            // Process members data
            // ...
        }
        
        // Store the ListenerRegistration if needed to remove the listener later
        // ...
    }
*/
