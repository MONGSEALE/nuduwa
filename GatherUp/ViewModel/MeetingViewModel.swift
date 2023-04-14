//
//  MeetingViewModel.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/04/05.
//

import SwiftUI
import Firebase

class MeetingViewModel: ObservableObject {
    @Published var meetings: [Meeting] = []
    
    @Published var meeting: Meeting?
    
    //@Published var paginationDoc: QueryDocumentSnapshot?
    
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
    
    /// Firestore에 있는 모임 데이터 가져오기
    func fetchMeetings(passedMeeting: Bool)async{
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
            print(fetchedMeetings)
            await MainActor.run(body: {
//                for meeting in fetchedMeetings {
//                    if meeting.hostUID == uid {
//                        fetchedMeetings.insert(meeting, at: 0)
//                    }else{
//                        meetings.append(meeting)
//                    }
//                }
                meetings = fetchedMeetings
                isFetching = false
            })
        }catch{
            print("fetchMeetings 에러!")
        }
    }
    
    
    /// 실시간 모임 추가시 meetings 배열에 데이터 추가
    func addMeetingsListner(){
        print("addListner")
        guard let uid = Auth.auth().currentUser?.uid else{return}
        Firestore.firestore().collection("Meetings")
        //                .whereField("members", arrayContains: uid)
            .addSnapshotListener { (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {
                    print("No documents")
                    return
                }
                self.meetings = documents.compactMap{ documents -> Meeting? in
                    try? documents.data(as: Meeting.self)
                }
            }
    }
    
    
    
    // 리스너 제거
    func removeListner(){
        if let docListner{
            docListner.remove()
            self.docListner = nil
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
}

