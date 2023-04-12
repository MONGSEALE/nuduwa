//
//  MapViewModel2.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/03/31.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import CoreLocation

class MapViewModel2: ObservableObject {
    @Published var meetings: [Location] = []    // Firestore에 있는 모임 장소 배열
    @Published var meetingsMap: [Location] = []     // meetings + 새로 추가하는 모임(저장전) 배열
    private var newMeeting: Location?       // 새로 추가하는 모임(저장전)
    @Published var meeting: Meeting? // 보여질 미팅
    
    // MARK: Error Properties
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    //로딩
    @Published var isLoading: Bool = false
    @Published var isFetching: Bool = true
    
    @Published var paginationDoc: QueryDocumentSnapshot?
    
    private var docListner: ListenerRegistration?
    
    @Published var isOverlap: Bool = false
    
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
            let fetchedMeetings = docs.documents.compactMap{ doc -> Meeting? in
                try? doc.data(as: Meeting.self)
            }
            
            await MainActor.run(body: {
                for meeting in fetchedMeetings{
                    meetings.append(Location(coordinate: CLLocationCoordinate2D(latitude: meeting.latitude, longitude: meeting.longitude)))
                }
                //meetingsFirestore.append(contentsOf: fetchedMeetings)
                paginationDoc = docs.documents.last
                isFetching = false
                meetingsMap = (newMeeting != nil) ? meetings + [newMeeting!] : meetings
                //meetingsMap = meetings
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
            Firestore.firestore().collection("Meetings")
                .whereField("publishedDate", isLessThan: Date())
                .addSnapshotListener({ snapshot, error in
                guard let snapshot = snapshot else{print("Error snapshot");return}
                snapshot.documentChanges.forEach { meeting in
                    switch meeting.type {
                    case .added:
                        print("추가 전")
                        if let addMeeting = try? meeting.document.data(as: Meeting.self){
                            self.meetingsMap.append(Location(coordinate: CLLocationCoordinate2D(latitude: addMeeting.latitude, longitude: addMeeting.longitude)))
                            print("추가 후")
                        }
                    case .modified:
                        print("변경")
                    case .removed:
                        if let removeMeeting = try? meeting.document.data(as: Meeting.self){
                            self.meetingsMap.removeAll{removeMeeting.longitude == $0.coordinate.longitude}
                            print("삭제")
                        }
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
    
    func cancleMeeting(){
        newMeeting = nil
        meetingsMap = meetings
    }
    
    func addMeeting(newLocation: Location){
        newMeeting = newLocation
        meetingsMap = (newMeeting != nil) ? meetings + [newMeeting!] : meetings
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
                    await fetchMeetings()
                    
                } catch {
                    await handleError(error: error)
                }
            }
        }
    
    
    
    /// 작성자 확인
    func checkedOverlap(id: String){
            let doc = Firestore.firestore().collection("Meetings").whereField("userUID", isEqualTo: id)
            doc.getDocuments(){ (query, err) in
                if let err = err {
                    print("checkedOverlap 에러: \(err)")
                } else {
                    print("중복 여부")
                    if let query = query, !query.isEmpty {
                        print("중복!: \(query.documents)")
                        self.isOverlap = false
                    } else {
                        print("중복 아님!")
                        self.isOverlap = true
                    }
                }
            }
    }
    
    func showMeeting(userId: String){
        let doc = Firestore.firestore().collection("Meetings").document(userId)
        doc.getDocument(as: Meeting.self) { result in
            switch result {
            case .success(let meet):
                self.meeting = meet
            case .failure(let err):
                print("showMeeting 에러: \(err)")
            }
        }
    }
    
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

    
    /// 에러처리
    func handleError(error: Error)async{
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        })
    }
}
