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

// Firebase와 연결하는 ViewModel 클래스가 상속하는 부모 클래스
// 모든 컬렉션 이름이 변수로 저장되어있다
// 리스너들 저장용 변수가 있고 클래스가 종료될때 리스너 제거함수를 실행한다
// 오류 처리용 함수도 있다
// User 정보 저장하는 변수와 서버에서 가져오는 함수가 있다.
// FirestoreConvertible.swift에서 Firestore로 가져오는 방식 extension으로 확장
// 201530118 손장혁

class FirebaseViewModel: ObservableObject {
    /// Firestore용 변수
    let db = Firestore.firestore()
    /// 리스너 딕셔너리 [경로:리스너]
    var listeners: [String : ListenerRegistration] = [:]
    /// 콜렉션 이름
    /// Users 콜렉션
    let strUsers = "Users"
    let strDMList = "DMList"
    let strMeetingList = "MeetingsList"
    let strBlockList = "BlockList"
    let strReviewList = "ReviewList"
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
    /// 뷰에서 유저정보 필요할때 쓰는 변수
    @Published var user: User?
    /// 로그인한 유저아이디 - 로그아웃하면 nil
    var currentUID: String? {
       return Auth.auth().currentUser?.uid
    }
    /// 에러처리용 enum 일단은 임시용
    enum SomeError: Error {
        case missCurrentUID
        case missSomething
        case error
    }
    /// 클래스 종료시 리스너 제거
    deinit {
        removeListeners()
    }
    /// 리스너 제거(리소스 확보, 단 자주 켰다껐다하면 리소스 더 들어감 - Firebase 공식문서에 따르면 30초기준으로 껐다킬거면 끄지말것)
    func removeListeners() {
        if !listeners.isEmpty {
            for (_, listener) in listeners {
                // 리스너 끄는 함수
                listener.remove()
            }
            listeners.removeAll()
        }
    }

    /// 유저 데이터 클래스 변수 user에 저장하기 - User 구조체보면 알겠지만 모든정보를 가져오진 않음
    func fetchUser(_ userUID: String?, getAllData: Bool = false) {
        print("fetchUser:\(userUID ?? "uidNon")")
        Task{
            do{
//                let user = !getAllData ? try await getUser(userUID) : try await getUserAllData(userUID) // 오류로 주석 처리
                let user = try await getUser(userUID)
                // 비동기 함수에서 View에 확실히 적용하기 - Task{}는 비동기임
                await MainActor.run{
                    self.user = user
                }
            }catch{
                await handleError(error)
            }
        }
    }
    /// 유저 데이터 가져와서 리턴하기 - View에서 쓰는 함수는 아니고 ViewModel에서 필요할때 사용, View는 위 fetchUser 함수 쓸것
    func getUser(_ userUID: String?) async throws -> User? {
        print("getUser:\(userUID)")
        do{
            // currentUID를 nil처리 안하고 바로 쓸 수 있게 String? 타입으로 받음 - 여기서 nil처리
            guard let userUID = userUID else{throw SomeError.missCurrentUID}
            // Firestore 경로
            let docRef = db.collection(strUsers).document(userUID)
            // 경로로 가져오기 - 비동기함수라서 await 씀
            let user = try await docRef.getDocument(as: User.self)
            
            return user
        }catch{
            print("getUser에러")
            throw error
        }
    }
    // 모든 user정보 가져오는 함수로 짰는데 오류나서 주석처리
    /*
  func getUserAllData(_ userUID: String?) async throws -> User? {
      print("getUserAllData")
      do{
          guard let userUID = userUID else{throw SomeError.missCurrentUID}
          let doc = db.collection(strUsers).document(userUID)
          let user = try await doc.getDocument(as: User.getAllData.self)
          return user
      }catch{
          throw error
      }
  }
  // FirestoreConvertible을 준수하는 모든 구조체에서 쓸 수 있게 만들었는데 1줄짜리라 더 번거러워서 삭제 예정
   func getDocData<T:FirestoreConvertible>(doc: DocumentReference) async throws -> T {
       print("getDocData")
       do{
           return try await doc.getDocument(as: T.self)
       }catch{
           throw error
       }
   }
   */

    /// 유저 데이터 실시간 가져와서 클래스 변수 user에 저장
    func userListener(_ userUID: String?) {
        print("userListener")
        guard let userUID = userUID else{return}
        
        let docRef = db.collection(strUsers).document(userUID)
        // 경로로 리스너 호출 - 리스너는 await으로 비동기처리가 안돼서 클로저로 비동기처리(중괄호 안에 있는 코드는 addSnapshotListener가 다 끝난다음에 실행), 더 좋은 방법은 combine 프레임워크 사용하는것
        let listener = docRef.addSnapshotListener { snapshot, error in
            if let error = error {return}
            // 에러가 안나고 정상적으로 작동했는데 서버에 데이터가 없을때 else문 실행
            guard let document = snapshot else{print("No Users");return}
            self.user = document.data(as: User.self)
            print("유저\(String(describing: self.user))")
        }
        listeners[docRef.path] = listener
    }
    
    /// 에러처리 - 아직 형식만 만듬
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
