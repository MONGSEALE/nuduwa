//
//  FirebaseListenerViewModel.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/04/04.
//

import SwiftUI
import Firebase


class FirebaseViewModel: ObservableObject {
    @Published var meetings: [Meeting] = []
    @Published var meetingsFull: [Meeting] = []
    //@State private var docListner: ListenerRegistration?
    @Published var paginationDoc: QueryDocumentSnapshot?
    @Published var isFetching: Bool = true
    
    // MARK: Error Properties
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    //로딩
    @Published var isLoading: Bool = false
    
    private var newMeeting: Meeting?
    
    /// 실시간 모임 추가시 meetings 배열에 데이터 추가
    func addMeetingsListner(){
        //if docListner == nil{
            print("addListner")
            Firestore.firestore().collection("Meetings").addSnapshotListener({ snapshot, error in
                guard let snapshot = snapshot else{return}
                snapshot.documentChanges.forEach { meeting in
                    //print("추가항목: \(meeting.document.data())")
                    if let addMeeting = try? meeting.document.data(as: Meeting.self){
                        self.meetings.append(contentsOf: [addMeeting])
                        print("갯수: \(self.meetings.count)")
                    }
                }
            })
        //}
    }
    
    /// Firestore에 있는 모임 데이터 가져오기
    func fetchMeetings()async{
        do{
            var query: Query!
            /// - Implementing Pagination
            if let paginationDoc{
                query = Firestore.firestore().collection("Meetings")
                    .order(by: "publishedDate", descending: true)
                    .start(afterDocument: paginationDoc)
                    .limit(to: 20)
            }else{
                query = Firestore.firestore().collection("Meetings")
                    .order(by: "publishedDate", descending: true)
                    .limit(to: 20)
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
                meetingsFull = (newMeeting != nil) ? meetings + [newMeeting!] : meetings
            })
        }catch{
            print(error.localizedDescription)
        }
    }
    
    func addMeeting(la:Double, lo:Double){
        let user = Auth.auth().currentUser
        guard
            let userName: String = user?.displayName,
            let userUID: String = user?.uid
        else{return}
        let profileURL = user?.photoURL ?? URL(filePath: "")
        print("위치 \(la)")
        newMeeting = Meeting(name: "모임1", description: "아무나", latitude: la, longitude: lo, userName: userName, userUID: userUID, userImage: profileURL)
        
        meetingsFull = meetings + [newMeeting!]
        print("add : \(String(describing: newMeeting?.latitude))")
        
        createMeeting(meeting: newMeeting!)
    }
    func cancleMeeting(){
        newMeeting = nil
        meetingsFull = meetings
    }
    
    /// 새로운 모임 Firestore에 저장
    func createMeeting(meeting: Meeting){
        print("firebase save")
        //isLoading = true
        //showKeyboard = false
        Task{
            do{
                /// - Writing Document to Firebase Firestore
                let doc = Firestore.firestore().collection("Meetings").document()
                let _ = try doc.setData(from: meeting, completion: {error in
                    if error == nil{
                        /// Post Successfully Stored at Firebase
                        print(error as Any)
                    }
                })
                
            } catch {
                await handleError(error: error)
            }
        }
        addMeetingsListner() // 나중에 삭제
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

