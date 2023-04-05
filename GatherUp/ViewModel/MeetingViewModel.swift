//
//  MeetingViewModel.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/04/05.
//

import SwiftUI
import Firebase

class MeetingViewModel: ObservableObject {
    @Published var meetingsFirestore: [Meeting] = []
    
    @Published var paginationDoc: QueryDocumentSnapshot?
    
    @Published var isFetching: Bool = true
    
    /// Firestore에 있는 모임 데이터 가져오기
    func fetchMeetings()async{
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
                //.whereField("meetingDate", isGreaterThan: Date())
            let docs = try await query.getDocuments()
            let fetchedMeetings = docs.documents.compactMap{ doc -> Meeting? in
                try? doc.data(as: Meeting.self)
            }
            await MainActor.run(body: {
                //meetings = fetchedMeetings
                meetingsFirestore.append(contentsOf: fetchedMeetings)
                paginationDoc = docs.documents.last
                isFetching = false
            })
        }catch{
            print(error.localizedDescription)
        }
    }
    
}

