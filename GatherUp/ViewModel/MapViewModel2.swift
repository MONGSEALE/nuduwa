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
import GeoFireUtils  //삭제해도 되면 삭제

class MapViewModel2: FirebaseViewModelwithMeetings {

//    @Published var meetings: [Meeting] = []     // 모임 배열
    private var fetchedMeetings: [String:[Meeting]] = [:]     // 서버에서 가져오는 모임 배열
    private var setMeetings: Set<Meeting> = []                // newMeeting 추가전 모임 배열(Set)
    @Published var newMeeting: Meeting?                       // 새로 추가하는 모임(서버 저장전)
                         // 모임
    @Published var bigIconMeetings: [String:[Meeting]] = [:]  // 중첩 아이콘 클릭시 나타낼 모임

    private var checkRegion: MKCoordinateRegion?
    
    @Published var isOverlap: Bool = false  // 모임 중복 생성 확인
        
    override init() {
        super.init()
        checkedOverlap()
    }

    /// 서버 모임과 새로 추가하는 모임(서버 저장전) 배열 합치기
    func combineNewMeetings(){
        print("combineNewMeetings")
        meetings = newMeeting == nil ? Array(setMeetings) : Array(setMeetings) + [newMeeting!]
    }

    /// 가까이 있는 모임들 하나로 합치고 정렬
    func mergeMeetings(latitudeDelta: Double){
        print("mergeMeetings")

        var setFetchedMeetings: Set<Meeting> = Set(fetchedMeetings.values.flatMap { $0 })
        bigIconMeetings = [:]
        let delta = latitudeDelta * 0.05   // 지도세로길이 * 0.1 이하로 가까이 있으면 중첩
        // let copySet = setFetchedMeetings  // for문용으로 복사
        
        for meeting1 in setFetchedMeetings {
            guard setFetchedMeetings.contains(meeting1) else { continue }     // 중첩돼서 지운 모임이면 continue
            let latitude = meeting1.latitude
            let longitude = meeting1.longitude
            
            var nearbyMeetings: [Meeting] = []
            for meeting2 in setFetchedMeetings.subtracting([meeting1]) {
                // delta값으로 meeting1과 meeting2가 가까이 있는지 비교
                if (latitude-delta < meeting2.latitude) &&
                    (meeting2.latitude < latitude+delta) &&
                    (longitude-delta < meeting2.longitude) &&
                        (meeting2.longitude < longitude+delta)
                {
                    nearbyMeetings.append(meeting2)  // 가까이 있으면 bigIconMeetings에 저장
                    setFetchedMeetings.remove(meeting2)  // 그리고 원래 Meetings에선 삭제
                }
            }
            // meeting1과 가까이 있는 모임 있으면 meeting1도 bigIconMeetings에 저장후 원래 Meetings에선 삭제하고 type.piled Meeting 저장
            if !nearbyMeetings.isEmpty {
                bigIconMeetings[meeting1.id!, default: []] = [meeting1] + nearbyMeetings
                let meeting = Meeting.piledMapAnnotation(id: meeting1.id!, location: meeting1.location, geoHash: meeting1.geoHash)
//                let meeting = Meeting(id: meeting1.id, title: "", description: "", place: "", numbersOfMembers: 0, latitude: meeting1.latitude, longitude: meeting1.longitude, hostUID: "", type: .piled)
                setFetchedMeetings.remove(meeting1)
                setFetchedMeetings.insert(meeting)
            }
        }
        setMeetings = setFetchedMeetings
        combineNewMeetings()
    }

    ///  지도 위치 체크해서 리스너 쿼리 변경
    func checkedLocation(region: MKCoordinateRegion) {
        print("checkedLocation")
        if let checkRegion = checkRegion {
            let changedLatitude = abs(checkRegion.span.latitudeDelta - region.span.latitudeDelta) > region.span.latitudeDelta / 3
            let changedLongitude = abs(checkRegion.span.longitudeDelta - region.span.longitudeDelta) > region.span.longitudeDelta / 3
            let movedLatitude = abs(checkRegion.center.latitude - region.center.latitude) > region.span.latitudeDelta
            let movedLongitude = abs(checkRegion.center.longitude - region.center.longitude) > region.span.longitudeDelta
            
            if changedLatitude || changedLongitude || movedLatitude || movedLongitude  {
                mapMeetingsListener(region: region)
            }
        }
    }
    /// FireStore와 meetings 배열 실시간 연동
    func mapMeetingsListener(region: MKCoordinateRegion){
        print("mapMeetingsListener")
        Task{
            do{
                checkRegion = region

                let metersPerDegree: Double = 111_319.9 // 지구의 반지름 (m) * 2 * pi / 360
                let latitudeDeltaInMeters = region.span.latitudeDelta * metersPerDegree * 4
                
                let queryBounds = GFUtils.queryBounds(forLocation: region.center,
                                                    withRadius: latitudeDeltaInMeters)
                
                var queries: [String:Query] = [:]
                queryBounds.forEach{ bound in
                    queries[bound.startValue + bound.endValue] = self.db
                        .collection(self.strMeetings)
                        .order(by: "geoHash")
                        .start(at: [bound.startValue])
                        .end(at: [bound.endValue])
                }

                // 리스너 제거
                let removedKeys = fetchedMeetings.keys.filter { !queries.keys.contains($0) }
                for key in removedKeys {
                    listeners[key]?.remove()
                    listeners.removeValue(forKey: key)
                    fetchedMeetings.removeValue(forKey: key)
                }
                // let filteredMeetings = fetchedMeetings.filter { !queries.keys.contains($0.key) }
                // fetchedMeetings = filteredMeetings
                
                for (key,query) in queries {
                    let listener = query.addSnapshotListener { (querySnapshot, error) in
                        self.fetchedMeetings[key] = []
                        guard let documents = querySnapshot?.documents else {
                            print("mapMeetingsListener 에러1: \(String(describing: error))")
                            return
                        }
                        print("documents: \(documents)")
                        self.fetchedMeetings[key] = documents.compactMap{ documents -> Meeting? in
                            try? documents.data(as: Meeting.self)
                        }
                        self.mergeMeetings(latitudeDelta: region.span.latitudeDelta)
                    }
                    listeners[query.description] = listener
                    print("쿼리:\(query.description)")
                }
            }catch{
                await handleError(error)
            }
        }
    }

    /// 모임 추가시(서버 저장전)
    func addMapAnnotation(newMapAnnotation: CLLocationCoordinate2D){
        print("addMapAnnotation")
        // newMeeting = Meeting(title: "", description: "", place: "", numbersOfMembers: 0, latitude: newMapAnnotation.latitude, longitude: newMapAnnotation.longitude, hostUID: "", type: .new)
        newMeeting = Meeting.createMapAnnotation(newMapAnnotation)
        combineNewMeetings()
    }
    /// 모임 추가 취소 또는 모임 서버 저장했을때 newMeeting 초기화
    func deleteMapAnnotation(){
        print("deleteMapAnnotation")
        newMeeting = nil
        combineNewMeetings()
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
                // await fetchCurrentUserAsync()
                // var meeting = meeting
                // guard let currentUID = currentUID else{return}
                // meeting.hostUID = currentUID
                
                // let location = CLLocationCoordinate2D(latitude: meeting.latitude, longitude: meeting.longitude)
                // let geoHash = GFUtils.geoHash(forLocation: meeting.location)
                // geoHash 구조체에 넣을수 있나??
                // meeting.geoHash = geoHash
                
                let document = try await db.collection(strMeetings).addDocument(data: meeting.firestoreData)
                let meetingID = document.documentID
                self.joinMeeting(meetingID: meetingID)
                
                isLoading = false
                
            } catch {
                await handleError(error)
            }
        }
    }
    override func joinMeeting(meetingID: String, numbersOfMembers: Int = 0){
        print("joinMeeting")
        isLoading = true
        Task{
            do{
                guard let currentUID = currentUID else{return}
                let userData = try await getUserData(currentUID)

//                let member = Member(memberUID: currentUID)
//                let joinMeeting = JoinMeeting(meetingID: meetingID, isHost: true)

                let text = "\(userData.userName)님이 채팅에 참가하셨습니다."
                // let message = ChatMessage(
                //     text: "\(userData.userName)님이 채팅에 참가하셨습니다.",
                //     userUID: "SYSTEM",
                //     timestamp: Timestamp(),
                //     isSystemMessage: true
                // )

                let meetingsDoc = db.collection(strMeetings).document(meetingID)
                let joinMeetingsCol = db.collection(strUsers).document(currentUID).collection(strJoinMeetings)
                
                try await meetingsDoc.collection(strMembers).addDocument(data: Member.member(currentUID))

                try await joinMeetingsCol.addDocument(data: JoinMeeting.host(meetingID))
                
                try await meetingsDoc.collection(self.strMessage).addDocument(data: Message.systemMessage(text))
                
                isLoading = false
            } catch {
                handleErrorTask(error)
            }
        }
    }
    /// 작성자 중복 확인
    func checkedOverlap(){
        print("checkedOverlap")
        
        Task{
            do{
                let doc = db.collection(strMeetings).whereField("hostUID", isEqualTo: currentUID)
                let query = try? await doc.getDocuments()
                
                if let query = query, !query.isEmpty {
                    await MainActor.run{
                        self.isOverlap = true
                        print("작성자 중복!")
                    }
                } else {
                    await MainActor.run{
                        self.isOverlap = false
                        print("작성자 중복!")
                    }
                }
                
            }catch{
                await handleError(error)
            }
        }
        
    }
    
    
}

