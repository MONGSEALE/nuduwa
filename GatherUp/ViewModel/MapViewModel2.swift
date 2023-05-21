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
    private var filteredMeetings: [Meeting] = []                // newMeeting 추가전 모임 배열
    @Published var newMeeting: Meeting?                       // 새로 추가하는 모임(서버 저장전)
    @Published var bigIconMeetings: [String:[Meeting]] = [:]  // 중첩 아이콘 클릭시 나타낼 모임

    @Published var category: Meeting.Category? = nil

    private var checkRegion: MKCoordinateRegion?    // 쿼리 리셋기준 위치
    
    @Published var isOverlap: Bool = false  // 모임 중복 생성 확인
    
    // 쓰로틀링용 변수
    private var lastMergeMeetingsThrottleTime: DispatchTime = .now()
    private var lastCheckedLocationThrottleTime: DispatchTime = .now()
    private let throttleInterval: TimeInterval = 0.2
        
    override init() {
        super.init()
        checkedOverlap()
    }

    // throttleInterval 초동안 여러번 호출되면 1번만 실행
    private func mergeMeetingsThrottled(latitudeDelta: Double) {
        let currentTime = DispatchTime.now()
        let elapsedTime = currentTime.uptimeNanoseconds - lastThrottleTime.uptimeNanoseconds

        // 일정 시간(throttleInterval) 이상 경과한 경우에만 함수 실행
        if elapsedTime >= UInt64(throttleInterval * 1_000_000_000) {
            lastMergeMeetingsThrottleTime = currentTime
            mergeMeetings(latitudeDelta: latitudeDelta)
        }
    }
    // throttleInterval 초동안 여러번 호출되면 1번만 실행
    private func checkedLocationThrottled(region: MKCoordinateRegion) {
        let currentTime = DispatchTime.now()
        let elapsedTime = currentTime.uptimeNanoseconds - lastThrottleTime.uptimeNanoseconds

        // 일정 시간(throttleInterval) 이상 경과한 경우에만 함수 실행
        if elapsedTime >= UInt64(throttleInterval * 1_000_000_000) {
            lastCheckedLocationThrottleTime = currentTime
            checkedLocation(region: region)
        }
    }

    /// 서버 모임과 새로 추가하는 모임(서버 저장전) 배열 합치기
    private func combineNewMeetings(){
        print("combineNewMeetings")

        if let newMeeting {
            meetings = [newMeeting] + filteredMeetings
        } else {
            meetings = filteredMeetings
        }
    }

    /// 가까이 있는 모임들 하나로 합치고 정렬
    private func mergeMeetings(latitudeDelta: Double){
        print("mergeMeetings")
        
        let delta = latitudeDelta * 0.05   // 지도세로길이 * 0.1 이하로 가까이 있으면 중첩
        // fetchedMeetings에서 혹시 모를 중복값 제거하고 1차원 배열로 변경
        var mergedMeetings = Array(Set(fetchedMeetings.values
            .flatMap { $0 }
            .filter { $0.category == category }
        ))
        var piledMeetings: [String:[Meeting]] = [:]   // bigIconMeetings에 넣을 값
        var removedMeetings: [Meeting] = []   // 제거할 임시 모임배열

        mergedMeetings.forEach { meeting1, index in
            guard removedMeetings.contains(meeting1) else { continue } // 중첩돼서 지운 모임이면 continue
            let latitude = meeting1.latitude
            let longitude = meeting1.longitude

            for j in index+1 ..< mergedMeetings.count {
                let meeting2 = mergedMeetings[j]
                // delta값으로 meeting1과 meeting2가 가까이 있는지 비교
                if abs(latitude - meeting2.latitude) < delta &&
                abs(longitude - meeting2.longitude) < delta {

                    piledMeetings[meeting1.id!, default: []].append(meeting2)  // 가까이 있으면 piledMeetings에 저장
                    removedMeetings.append(meeting2)  // 삭제할 요소를 따로 저장
                }
            }
            // meeting1과 가까이 있는 모임 있으면 meeting1도 piledMeetings에 저장후 타입값 변경
            if piledMeetings[meeting1.id!] != nil {
                piledMeetings[meeting1.id!].insert(meeting1, at: 0)
                meeting1.type = .piled
            }
        }

        // 삭제할 요소를 한꺼번에 배열에서 제거
        mergedMeetings.removeAll(where: { removedMeetings.contains($0) })
    
        filteredMeetings = mergedMeetings
        bigIconMeetings = piledMeetings
        combineNewMeetings()
        /*
        for meeting1 in setFetchedMeetings {
            guard setFetchedMeetings.contains(meeting1) else { continue }     // 중첩돼서 지운 모임이면 continue
            let latitude = meeting1.latitude
            let longitude = meeting1.longitude
            
            var nearbyMeetings: [Meeting] = []
            for meeting2 in setFetchedMeetings.subtracting([meeting1]) {
                // delta값으로 meeting1과 meeting2가 가까이 있는지 비교
                if abs(latitude - meeting2.latitude) < delta && 
                   abs(longitude - meeting2.longitude) < delta {

                    nearbyMeetings.append(meeting2)  // 가까이 있으면 bigIconMeetings에 저장
                    setFetchedMeetings.remove(meeting2)  // 그리고 원래 Meetings에선 삭제
                }
            }
            // meeting1과 가까이 있는 모임 있으면 meeting1도 bigIconMeetings에 저장후 원래 Meetings에선 삭제하고 type.piled Meeting 저장
            if !nearbyMeetings.isEmpty {
                bigIconMeetings[meeting1.id!, default: []] = [meeting1] + nearbyMeetings
                let meeting = Meeting.piledMapAnnotation(meeting: meeting1)

                setFetchedMeetings.remove(meeting1)
                setFetchedMeetings.insert(meeting)
            }
        }
        */
    }

    ///  지도 위치 체크해서 리스너 쿼리 변경
    func checkedLocation(region: MKCoordinateRegion) {
        print("checkedLocation, 현재 리스너갯수: \(listeners.count)")
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
                let latitudeDeltaInMeters = region.span.latitudeDelta * metersPerDegree * 3
                // region.center에서 latitudeDeltaInMeters범위만큼 해당하는 geoHash값 저장
                let queryBounds = GFUtils.queryBounds(forLocation: region.center,
                                                    withRadius: latitudeDeltaInMeters)
                // queryBounds를 사용해 Firestore 쿼리 만들기
                var queries: [String:Query] = [:]
                queryBounds.forEach{ bound in
                    queries[bound.startValue + bound.endValue] = self.db
                        .collection(self.strMeetings)
                        .order(by: "geoHash")
                        .start(at: [bound.startValue])
                        .end(at: [bound.endValue])
                }

                // 안쓰는 리스너 제거
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
                        self.fetchedMeetings[key] = documents.compactMap{ documents -> Meeting? in
                            documents.data(as: Meeting.self)
                        }
                        self.mergeMeetingsThrottled(latitudeDelta: region.span.latitudeDelta)
                    }
                    listeners[key] = listener
                }
                
            }catch{
                await handleError(error)
            }
        }
    }

    /// 모임 추가시(서버 저장전)
    func addMapAnnotation(newMapAnnotation: CLLocationCoordinate2D){
        print("addMapAnnotation")
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
                var meeting = meeting
                guard let currentUID = currentUID else{return}
                meeting.hostUID = currentUID
                let document = try await db.collection(strMeetings).addDocument(data: meeting.firestoreData)
                let meetingID = document.documentID
                self.joinMeeting(meetingID: meetingID, numbersOfMembers: 0)
                
                isLoading = false
                
            } catch {
                await handleError(error)
            }
        }
    }
    
    /// 작성자 중복 확인
    func checkedOverlap(){
        print("checkedOverlap")
        
        Task{
            do{
                guard let currentUID = currentUID else{return}
                let doc = db.collection(strUsers).document(currentUID).collection(strJoinMeetings)
                    .whereField("hostUID", isEqualTo: currentUID)
                    .whereField("isEnd", isEqualTo: false)
                let query = try await doc.getDocuments()
                
                if !query.isEmpty {
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

    /// 모임 category로 필터
    func filterMeetingsByCategory(category: Meeting.Category?, latitudeDelta: Double) {
        self.category = category
        mergeMeetings(latitudeDelta: latitudeDelta)
    }
    
    
}

