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
    private var fetchedMeetings: [String:[Meeting]] = [:]         // 서버에서 가져오는 모임 배열
    @Published var newMeeting: Meeting?         // 새로 추가하는 모임(저장전)
    @Published var meeting: Meeting?            // 모임
    @Published var bigIconMeetings: [String:[Meeting]] = [:]  // 중첩 아이콘 클릭시 나타낼 모임
    
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
    func combineMeetings(latitudeDelta: Double = 0){
        print("combineMeetings")
        var fetchedMeetingsSet: Set<Meeting> = []
        for arr in fetchedMeetings.values {
            for value in arr {
                fetchedMeetingsSet.insert(value)
            }
        }
        print("Set:\(fetchedMeetingsSet)")
        
        bigIconMeetings = [:]
        let delta = latitudeDelta * 0.1
        
        let checkSet = fetchedMeetingsSet
        for index in fetchedMeetingsSet.indices {
            if !fetchedMeetingsSet.contains(checkSet[index]) {
                continue
            }
            let meeting1 = fetchedMeetingsSet[index]
            let latitude = meeting1.latitude
            let longitude = meeting1.longitude
            
            let startIndex = fetchedMeetingsSet.index(after: index)
            let endIndex = fetchedMeetingsSet.endIndex
            
            for meeting2 in fetchedMeetingsSet[startIndex..<endIndex] {
                if (latitude-delta < meeting2.latitude) &&
                    (meeting2.latitude < latitude+delta) &&
                    (longitude-delta < meeting2.longitude) &&
                        (meeting2.longitude < longitude+delta)
                {
                    bigIconMeetings[meeting1.id!] = []
                    bigIconMeetings[meeting1.id!]!.append(meeting2)
                    fetchedMeetingsSet.remove(meeting2)
                }
            }
            print("meeting1:\(meeting1)")
            if let _ = bigIconMeetings[meeting1.id!] {
                bigIconMeetings[meeting1.id!]?.append(meeting1)
                let meeting = Meeting(id: meeting1.id, title: "", description: "", place: "", numbersOfMembers: 0, latitude: meeting1.latitude, longitude: meeting1.longitude, hostName: "", hostUID: "", type: .piled)
                fetchedMeetingsSet.remove(meeting1)
                fetchedMeetingsSet.insert(meeting)
            }
        }
        
        if let newMeeting = newMeeting {
            fetchedMeetingsSet.insert(newMeeting)
        }
        
        meetings = Array(fetchedMeetingsSet)
    }
    ///  지도 위치 체크해서 리스너 쿼리 변경
    func checkedLocation(){
        
    }
    /// FireStore와 meetings 배열 실시간 연동
    func mapMeetingsListner(center: CLLocationCoordinate2D, latitudeDelta: Double){
        print("mapMeetingsListner")
        let metersPerDegree: Double = 111_319.9 // 지구의 반지름 (m) * 2 * pi / 360
        let latitudeDeltaInMeters = latitudeDelta * metersPerDegree * 10
        print("델타: \(latitudeDelta)")
        print("거리: \(latitudeDeltaInMeters)")
        let queryBounds = GFUtils.queryBounds(forLocation: center,
                                              withRadius: latitudeDeltaInMeters)
        
        var queries: [String:Query] = [:]
        queryBounds.forEach{ bound in
            queries.updateValue(self.db.collection(self.strMeetings)
                                    .order(by: "geoHash")
                                    .start(at: [bound.startValue])
                                    .end(at: [bound.endValue]),
                                forKey: bound.startValue+bound.endValue)
        }
        
        for (key,query) in queries {
            query.addSnapshotListener { (snapshot, error) in
                self.fetchedMeetings[key] = []
                guard let documents = snapshot?.documents else {
                    print("mapMeetingsListner 에러1: \(String(describing: error))")
                    return
                }
                print("documents: \(documents)")
                self.fetchedMeetings[key] = documents.compactMap{ documents -> Meeting? in
                    try? documents.data(as: Meeting.self)
                }
                self.combineMeetings(latitudeDelta: latitudeDelta)
            }
        }
        
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
        newMeeting = Meeting(title: "", description: "", place: "", numbersOfMembers: 0, latitude: newMapAnnotation.latitude, longitude: newMapAnnotation.longitude, hostName: "", hostUID: "", type: .new)
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
                    doc.whereField("memberUID", isEqualTo: user.uid).getDocuments { (snapshot, error) in
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

