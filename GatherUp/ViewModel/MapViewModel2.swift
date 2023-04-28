//
//  MeetingSetSheetViewModel.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/04/27.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import CoreLocation
import GeoFireUtils

class MapViewModel2: ObservableObject {

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
    
    @Published var members: [Members] = []
    
    private var docListner: ListenerRegistration?
    
    private let db = Firestore.firestore()
    private let strMeetings = "Meetings"        // Firestore에 저장된 콜렉션 이름
    private let strMembers = "Members"          // Firestore에 저장된 콜렉션 이름
    private let strMessage = "Message"          // Firestore에 저장된 콜렉션 이름
    @Published var messages: [ChatMessage] = []
    
    /// 서버 모임과 새로 추가하는 모임(서버 저장전) 배열 합치기
    func combineMeetings(){
        meetings = (newMeeting != nil) ? fetchedMeetings + [newMeeting!] : fetchedMeetings
    }

    /// FireStore와 meetings 배열 실시간 연동
    func mapMeetingsListner(center: CLLocationCoordinate2D){
        print("mapMeetingsListner")
        let radiusInM: Double = 50 * 1000
        let queryBounds = GFUtils.queryBounds(forLocation: center,
                                              withRadius: radiusInM)
        let queries = queryBounds.map { bound -> Query in
            return db.collection(strMeetings)
                .order(by: "geoHash")
                .start(at: [bound.startValue])
                .end(at: [bound.endValue])
        }
        var meetings: [Meeting] = []
        let dispatchGroup = DispatchGroup()
        for query in queries {
            dispatchGroup.enter()
            query.addSnapshotListener { (snapshot, error) in
                defer { dispatchGroup.leave() } 
                guard let documents = snapshot?.documents else {
                    print("No documents")
                    return
                }
                
                meetings.append(contentsOf: documents.compactMap{ documents -> Meeting? in
                    try? documents.data(as: Meeting.self)
                })
            }
        }
        dispatchGroup.notify(queue: .main) {        // 비동기 끝나면 실행
            self.fetchedMeetings = meetings
            self.combineMeetings()
        }
        
        
//        let doc = db.collection(strMeetings)
//        docListner = doc.addSnapshotListener { (snapshot, error) in
//            guard let documents = snapshot?.documents else {
//                print("No documents")
//                return
//            }
//            self.fetchedMeetings = documents.compactMap{ documents -> Meeting? in
//                try? documents.data(as: Meeting.self)
//            }
//            self.combineMeetings()
//        }
        
    }
    
    /// 리스너 제거(리소스 확보)
    func removeListner(){
        print("removeListner")
        if let docListner{
            docListner.remove()
            self.docListner = nil
        }
    }
    /// 모임 추가시(서버 저장전)
    func addMapAnnotation(newMapAnnotation: CLLocationCoordinate2D){
        print("addMapAnnotation")
        newMeeting = Meeting(title: "", description: "", place: "", numbersOfMembers: 0, latitude: newMapAnnotation.latitude, longitude: newMapAnnotation.longitude, hostName: "", hostUID: "")
        combineMeetings()
    }
    /// 모임 추가 취소 또는 모임 서버 저장했을때 newMeeting 초기화
    func deleteMapAnnotation(){
        print("deleteMapAnnotation")
        newMeeting = nil
        combineMeetings()
    }
    /// 새로운 모임 Firestore에 저장
    func createMeeting(meeting: Meeting){
        print("createMeeting")
        isLoading = true
        //showKeyboard = false
        Task{
            do{
                /// - Firestore에 저장
                print("firebase save")
                guard let user = Auth.auth().currentUser else{return}
                var meeting = meeting
                meeting.hostUID = user.uid
                meeting.hostName = user.displayName ?? ""
                meeting.hostImage = user.photoURL 
                
                let location = CLLocationCoordinate2D(latitude: meeting.latitude, longitude: meeting.longitude)
                let geoHash = GFUtils.geoHash(forLocation: location)
                meeting.geoHash = geoHash
                
                let document = try db.collection(strMeetings).addDocument(from: meeting)
                let meetingId = document.documentID
                print("Meeting ID: \(meetingId)")
                joinMeeting(meetingId: meetingId, numbersOfMembers: meeting.numbersOfMembers)
                await MainActor.run(body: {
                    isLoading = false
                })
            } catch {
                await handleError(error: error)
            }
        }
    }
    /// 작성자 중복 확인
    func checkedOverlap(){
        print("checkedOverlap")
        guard let id = Auth.auth().currentUser?.uid else{self.isOverlap = true;return}
        
        let doc = db.collection(strMeetings).whereField("hostUID", isEqualTo: id)
        doc.getDocuments(){ (query, err) in
            if let err = err {
                print("checkedOverlap 에러: \(err)")
            } else {
                print("중복 여부")
                if let query = query, !query.isEmpty {
                    self.isOverlap = true
                } else {
                    self.isOverlap = false
                }
            }
            
        }
    }
    
    /// 모임 참가하기
    func joinMeeting(meetingId: String, numbersOfMembers: Int){
        print("joinMeeting")
        Task{
            do{
                guard let user = Auth.auth().currentUser else{return}
                let member = Members(memberUID: user.uid, memberName: user.displayName!, memberImage: user.photoURL)
                let doc = db.collection(strMeetings).document(meetingId).collection(strMembers)
                
                let _ = try doc.document().setData(from: member, completion: {error in
                    if let error = error{
                        print("Error CreateMeeting: \(error)")
                    }
                })
                db.collection(strMeetings).document(meetingId).collection(strMembers).getDocuments { (querySnapshot, error) in
                    guard let documents = querySnapshot?.documents else {return}
                    documents.forEach{document in
                        self.members = documents.compactMap{ documents -> Members? in
                            try? documents.data(as: Members.self)
                        }
                    }
                }
                /// 만약 오류로 최대인원을 넘겼을 경우 삭제
                if members.count > numbersOfMembers {
                    print("최대인원초과로 삭제")
                    doc.whereField("memberId", isEqualTo: user.uid).getDocuments { (snapshot, error) in
                        if let error = error {
                            print("에러: \(error)")
                        } else {
                            guard let documents = snapshot?.documents else { return }
                            for document in documents {
                                doc.document(document.documentID).delete()
                            }
                        }
                    }
                } else {
                    print("모임참가 완료")
                }
            } catch {
                await handleError(error: error)
                //isLoading = false
            }
        }
    }
    

    /// 모임맴버 가져오기
    func membersListener(meetingId: String){
        docListner = db.collection(strMeetings).document(meetingId).collection(strMembers)
            .addSnapshotListener { (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {return}
                documents.forEach{document in
                    self.members = documents.compactMap{ documents -> Members? in
                        try? documents.data(as: Members.self)
                    }
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

