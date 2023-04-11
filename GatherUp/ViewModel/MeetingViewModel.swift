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
    
    @Published var paginationDoc: QueryDocumentSnapshot?
    
    @Published var isFetching: Bool = true
    
    private var docListner: ListenerRegistration?
    
    /// Firestore에 있는 모임 데이터 가져오기
    func fetchMeetings(passMeeting: Bool)async{
        do{
            var query: Query!
            /// - Implementing Pagination
            if let paginationDoc{
                query = Firestore.firestore().collection("Meetings")
                    .order(by: "meetingDate", descending: true)
                    .start(afterDocument: paginationDoc)
                    .limit(to: 20)
            }else{
                query = Firestore.firestore().collection("Meetings")
                    .order(by: "meetingDate", descending: true)
                    .limit(to: 20)
            }
            
            guard let uid:String = Auth.auth().currentUser?.uid else{return}
            query = query
                .whereField("userUID", isEqualTo:uid)
            if passMeeting {
                query = query.whereField("meetingDate", isLessThan: Date())
            } else {
                //query = query.whereField("meetingDate", isGreaterThan: Date())
            }
                
            let docs = try await query.getDocuments()
            let fetchedMeetings = docs.documents.compactMap{ doc -> Meeting? in
                try? doc.data(as: Meeting.self)
            }
            await MainActor.run(body: {
                //meetings = fetchedMeetings
                meetings.append(contentsOf: fetchedMeetings)
                print("Meeting탭 모임추가됨")
                paginationDoc = docs.documents.last
                isFetching = false
            })
        }catch{
            print("에러: \(error.localizedDescription)")
        }
    }
    
    /*
    /// 실시간 모임 추가시 meetings 배열에 데이터 추가
    func addMeetingsListner(){
        if docListner == nil{
            print("addListner")
            guard let uid = Auth.auth().currentUser?.uid else{return}
            docListner = Firestore.firestore().collection("Meetings")
                .whereField("userUID", isEqualTo:uid)
                .addSnapshotListener({ snapshot, error in
                guard let snapshot = snapshot else{print("Error snapshot");return}
                snapshot.documentChanges.forEach { meeting in
                    switch meeting.type {
                    case .added:
                        print("추가 전")
                        if let addMeeting = try? meeting.document.data(as: Meeting.self){
                            self.meetings.append(addMeeting)
                            print("추가 후")
                        }
                    case .modified:
                        print("변경")
                    case .removed:
                        print("삭제")
                    }
                
                    
                }
            })
        print("갯수: \(self.meetings.count)")
        }
    }
     */
    
    
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
}

