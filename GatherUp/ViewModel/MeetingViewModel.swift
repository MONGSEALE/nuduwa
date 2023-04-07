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
                paginationDoc = docs.documents.last
                isFetching = false
            })
        }catch{
            print("에러: \(error.localizedDescription)")
        }
    }
    
    /// 실시간 모임 추가시 meetings 배열에 데이터 추가
    func addMeetingsListner(){
        if docListner == nil{
            print("addListner")
            guard let uid:String = Auth.auth().currentUser?.uid else{return}
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
    func removeListner(){
        if let docListner{
            docListner.remove()
            self.docListner = nil
        }
    }
    
}

