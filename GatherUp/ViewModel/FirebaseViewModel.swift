//
//  MeetingViewModel.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/04/05.
//

import SwiftUI
import Firebase

class FirebaseViewModel: ObservableObject {
    @Published var meetings: [Meeting] = []     // 모임 배열
    var fetchedMeetings: [Meeting] = []         // 서버에서 가져오는 모임 배열
    @Published var newMeeting: Meeting?         // 새로 추가하는 모임(저장전)
    @Published var meeting: Meeting?            // 모임
    
    @Published var isOverlap: Bool = false
    
    /// 에러 처리 변수
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    @Published var isLoading: Bool = false
    @Published var isFetching: Bool = true
    
    private var docListner: ListenerRegistration?
    
    //chat기능 변수
    private let db = Firestore.firestore().collection("Meetings")
    @Published var messages: [ChatMessage] = []
    //private var cancellables = Set<AnyCancellable>()
    private var listenerRegistration: ListenerRegistration?
    
//    func arrayMeetings(){
//        guard let uid = Auth.auth().currentUser?.uid else{return}
//        ForEach(meetings){ meeting in
//            meeting
//        }
//        meetings.lastIndex(of: )
//    }
    
    /// 서버 모임과 새로 추가하는 모임(서버 저장전) 배열 합치기
    func combineMeetings(){
        meetings = (newMeeting != nil) ? fetchedMeetings + [newMeeting!] : fetchedMeetings
    }
    /// Firestore에 있는 모임 데이터 가져오기
    func fetchMeetings(passedMeeting: Bool = false)async{
        do{
            print("fetchMeetings 실행")
            guard let uid:String = Auth.auth().currentUser?.uid else{return}

            var query: Query!

            query = Firestore.firestore().collection("Meetings")
            //                    .whereField("members", arrayContains: uid)
                .order(by: "meetingDate", descending: true)
            //            if passedMeeting {
            //                query = query.whereField("meetingDate", isLessThan: Date())
            //            } else {
            //                query = query.whereField("meetingDate", isGreaterThan: Date())
            //            }

            let docs = try await query.getDocuments()
            let fetchedMeetings = docs.documents.compactMap{ doc -> Meeting? in
                try? doc.data(as: Meeting.self)
            }
            print("fetchedMeetings")
            await MainActor.run(body: {
                meetings = fetchedMeetings
                isFetching = false
            })
        }catch{
            print("fetchMeetings 에러!")
        }
    }
    
    
    /// 실시간 모임 추가시 meetings 배열에 데이터 추가
    func meetingsListner(){
        print("addListner")
        guard let uid = Auth.auth().currentUser?.uid else{return}
        Firestore.firestore().collection("Meetings")
        //                .whereField("members", arrayContains: uid)
            .addSnapshotListener { (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {
                    print("No documents")
                    return
                }
                self.fetchedMeetings = documents.compactMap{ documents -> Meeting? in
                    try? documents.data(as: Meeting.self)
                }
                self.combineMeetings()
            }
    }
    
    /// 리스너 제거(리소스 확보)
    func removeListner(){
        if let docListner{
            docListner.remove()
            self.docListner = nil
        }
    }
    /// 모임 추가시(서버 저장전)
    func addMeeting(newMeeting: Meeting){
        self.newMeeting = newMeeting
        combineMeetings()
    }
    /// 모임 추가 취소 또는 모임 서버 저장했을때 newMeeting 초기화
    func cancleMeeting(){
        newMeeting = nil
        combineMeetings()
    }
    /// 새로운 모임 Firestore에 저장
    func createMeeting(meeting: Meeting){
        //isLoading = true
        //showKeyboard = false
        Task{
            do{
                /// - Firestore에 저장
                print("firebase save")
                let doc = Firestore.firestore().collection("Meetings").document()
                let _ = try doc.setData(from: meeting, completion: {error in
                    if let error = error{
                        print("Error CreateMeeting: \(error)")
                    } else {
                        print("모임 추가 완료")
                    }
                })
                //await fetchMeetings()
                
            } catch {
                //await handleError(error: error)
            }
        }
    }
    /// 작성자 중복 확인
    func checkedOverlap(id: String){
            let doc = Firestore.firestore().collection("Meetings").whereField("hostUID", isEqualTo: id)
            doc.getDocuments(){ (query, err) in
                if let err = err {
                    print("checkedOverlap 에러: \(err)")
                } else {
                    print("중복 여부")
                    if let query = query, !query.isEmpty {
                        print("중복!: \(query.documents)")
                        self.isOverlap = true
                    } else {
                        print("중복 아님!")
                        self.isOverlap = false
                    }
                }
            }
    }
    /// 모임 참가하기
    func joinMeeting(userId: String){
        let doc = Firestore.firestore().collection("Meetings").document(userId)
        doc.getDocument { (document, err) in
            if let err = err {
                print("joinMeeting 에러: \(err)")
            } else {
                guard var participants = document!["participants"] as? [String] else{print("participants오류");return}
                participants.append(Auth.auth().currentUser!.uid)
                doc.updateData(["participants" : participants])
            }
        }
    }
    
    /// - 모임 지우기
    func deleteMeeting(deletedMeeting: Meeting){
        Task{
            do{
                /// Delete Firestore Document
                guard let meetingID = deletedMeeting.id else{return}
                try await Firestore.firestore().collection("Meetings").document(meetingID).delete()
            }catch{
                print(error.localizedDescription)
            }
        }
    }
    
    /// - 모임 수정하기
    func updateMeeting(editMeeting: Meeting, title: String, description: String){
        Task{
            do{
                /// Delete Firestore Document
                guard let meetingID = editMeeting.id else{return}
                
                if title != editMeeting.title {
                    try await
                    Firestore.firestore().collection("Meetings").document(meetingID).updateData(["title": title])
                    print("title 수정")
                }
                
                if description != editMeeting.description {
                    try await
                    Firestore.firestore().collection("Meetings").document(meetingID).updateData(["description": description])
                    print("description 수정")
                }
                
                //                Firestore.firestore().collection("Meetings").document(meetingID).getDocument(as: Meeting.self) { result in
                //                    switch result {
                //                    case .success(let meet):
                //                        self.meeting = meet
                //
                //                    case .failure(let err):
                //                        print("updateMeeting에러: \(err)")
                //                    }
                //                }
                //
                //                print(meeting)
                //                await MainActor.run(body: {
                //                    meeting = meeting
                //                })
            }catch{
                print(error.localizedDescription)
            }
        }
    }
    
    ///채팅구현
    func fetchData(meetingId: String) {
        do{
            print("fetchData 시작")
            
            db.document(meetingId).collection("messages")
                .order(by: "timestamp", descending: false)
                .addSnapshotListener { (querySnapshot, error) in
                    guard let documents = querySnapshot?.documents else {
                        print("No documents")
                        return
                    }
                    self.messages = documents.compactMap { queryDocumentSnapshot -> ChatMessage? in
                        let data = queryDocumentSnapshot.data()
                        let id = queryDocumentSnapshot.documentID
                        let text = data["text"] as? String ?? ""
                        let userId = data["userId"] as? String ?? ""
                        let userName = data["userName"] as? String ?? ""
                        let timestamp = data["timestamp"] as? Timestamp ?? Timestamp()
                        
                        
                        return ChatMessage(id: id, text: text, userId: userId, userName: userName, timestamp: timestamp)
                    }
                }
        } catch{
            print("에러")
        }
        
    }
    
    func sendMessage(meetingId: String, text: String, userId: String, userName: String) {
        db.document(meetingId).collection("messages").addDocument(data: [
            "text": text,
            "userId": userId,
            "userName": userName,
            "timestamp": Timestamp()
        ])
    }
    
    /// 에러처리
    func handleError(error: Error)async{
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        })
    }
}

