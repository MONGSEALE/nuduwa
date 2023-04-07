//
//  MapViewModel2.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/03/31.
//

import SwiftUI
import Firebase

class MapViewModel2: ObservableObject {
    @Published var meetings: [Location] = []    // Firestore에 있는 모임 장소 배열
    @Published var meetingsMap: [Location] = []     // meetings + 새로 추가하는 모임(저장전) 배열
    private var newMeeting: Location?       // 새로 추가하는 모임(저장전)
    
    // MARK: Error Properties
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    //로딩
    @Published var isLoading: Bool = false
    @Published var isFetching: Bool = true
    
    @Published var paginationDoc: QueryDocumentSnapshot?
    
    private var docListner: ListenerRegistration?
    
    /// Firestore에 있는 모임 데이터 가져오기
    func fetchMeetings()async{
        do{
            var query: Query!
            /// - Implementing Pagination
            /*
            if let paginationDoc{
                query = Firestore.firestore().collection("Meetings")
                    .order(by: "publishedDate", descending: true)
                    .start(afterDocument: paginationDoc)
                    .limit(to: 20)
            }
             */
            query = Firestore.firestore().collection("Meetings")
            //.whereField("id", isNotEqualTo: false)
            //.whereField("latitude", isNotEqualTo: false)
            //.whereField("longitude", isNotEqualTo: false)
            let docs = try await query.getDocuments()
            let fetchedMeetings = docs.documents.compactMap{ doc -> Location? in
                try? doc.data(as: Location.self)
            }
            
            await MainActor.run(body: {
                meetings = fetchedMeetings
                //meetingsFirestore.append(contentsOf: fetchedMeetings)
                paginationDoc = docs.documents.last
                isFetching = false
                meetingsMap = (newMeeting != nil) ? meetings + [newMeeting!] : meetings
                print("fetch수: \(fetchedMeetings.count)")
                print("모임수: \(meetings.count)")
            })
        }catch{
            print(error.localizedDescription)
        }
    }
    
    /// 실시간 모임 추가시 meetings 배열에 데이터 추가
    func addMeetingsListner(){
        if docListner == nil{
            print("addListner")
            docListner =
            Firestore.firestore().collection("Meetings").addSnapshotListener({ snapshot, error in
                guard let snapshot = snapshot else{print("Error snapshot");return}
                snapshot.documentChanges.forEach { meeting in
                    switch meeting.type {
                    case .added:
                        print("추가 전")
                        if let addMeeting = try? meeting.document.data(as: Location.self){
                            self.meetingsMap.append(addMeeting)
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
    /// Listner 삭제
    func removeListner(){
        if let docListner{
            docListner.remove()
            self.docListner = nil
        }
    }
    
    func addMeeting(la:Double, lo:Double){
        /*
        let user = Auth.auth().currentUser
        guard
            let userName: String = user?.displayName,
            let userUID: String = user?.uid
        else{return}
        let profileURL = user?.photoURL ?? URL(filePath: "")
         */
        
        let my = Auth.auth().currentUser
        
        print("위치 \(la)")
        newMeeting = Location(latitude: la, longitude: lo, userUID: my?.uid)
        meetingsMap = meetings + [newMeeting!]
        print("add : \(String(describing: newMeeting?.latitude))")
        
        // 임시 모임 데이터
        let meeting2: Meeting = Meeting(title: "모임1", description: "아무나", latitude: newMeeting!.latitude, longitude: newMeeting!.longitude, userName: my?.displayName ?? "", userUID: my?.uid ?? "", userImage: my?.photoURL ?? URL(fileURLWithPath: ""))
        
        createMeeting(meeting: meeting2)
    }
    func cancleMeeting(){
        newMeeting = nil
        meetingsMap = meetings
    }
    /// 새로운 모임 Firestore에 저장
    func createMeeting(meeting: Meeting){
        print("firebase save")
        //isLoading = true
        //showKeyboard = false
        Task{
            do{
                /// - Firestore에 저장
                let doc = Firestore.firestore().collection("Meetings").document()
                let _ = try doc.setData(from: meeting, completion: {error in
                    if let error = error{
                        print("Error CreateMeeting: \(error)")
                    } else {
                        print("모임 추가 완료")
                    }
                })
                await fetchMeetings()
            } catch {
                await handleError(error: error)
            }
        }
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
