////
////  MapViewModel2.swift
////  GatherUp
////
////  Created by DaelimCI00007 on 2023/03/31.
////
//
//import SwiftUI
//import Firebase
//
//class MapViewModel2: ObservableObject {
//    var meetings: [Meeting] = []    // Firestore에 있는 모임 장소 배열
//    @Published var meetingsMap: [Meeting] = []     // meetings + 새로 추가하는 모임(저장전) 배열
//    @Published var newMeeting: Meeting?       // 새로 추가하는 모임(저장전)
//    @Published var meeting: Meeting? // 보여질 미팅
//    
//    // MARK: Error Properties
//    @Published var showError: Bool = false
//    @Published var errorMessage: String = ""
//    
//    //로딩
//    @Published var isLoading: Bool = false
//    @Published var isFetching: Bool = true
////
////    @Published var paginationDoc: QueryDocumentSnapshot?
//    
//    private var docListner: ListenerRegistration?
//    
//    @Published var isOverlap: Bool = false
//    
//    /// Firestore에 있는 모임 데이터 가져오기
//    func fetchMeetings()async{
//        do{
//            var query: Query!
//            query = Firestore.firestore().collection("Meetings")
//            //.whereField("id", isNotEqualTo: false)
//            //.whereField("latitude", isNotEqualTo: false)
//            //.whereField("longitude", isNotEqualTo: false)
//            let docs = try await query.getDocuments()
//            let fetchedMeetings = docs.documents.compactMap{ doc -> Meeting? in
//                try? doc.data(as: Meeting.self)
//            }
//            
//            await MainActor.run(body: {
////                for meeting in fetchedMeetings{
////                    meetings.append(Meeting(coordinate: CLLocationCoordinate2D(latitude: meeting.latitude, longitude: meeting.longitude)))
////                }
//                //meetingsFirestore.append(contentsOf: fetchedMeetings)
////                paginationDoc = docs.documents.last
//                meetings = fetchedMeetings
//                isFetching = false
//                meetingsMap = (newMeeting != nil) ? meetings + [newMeeting!] : meetings
//                //meetingsMap = meetings
//                print("fetch수: \(fetchedMeetings.count)")
//                print("모임수: \(meetings.count)")
//            })
//        }catch{
//            print(error.localizedDescription)
//        }
//    }
//    func addMeetingsListner(){
//        print("addListner")
//        guard let uid = Auth.auth().currentUser?.uid else{return}
//        Firestore.firestore().collection("Meetings")
//        //                .whereField("members", arrayContains: uid)
//            .addSnapshotListener { (querySnapshot, error) in
//                guard let documents = querySnapshot?.documents else {
//                    print("No documents")
//                    return
//                }
//                self.meetings = documents.compactMap{ documents -> Meeting? in
//                    try? documents.data(as: Meeting.self)
//                    
//                }
//            }
//    }
////    func addMeetingsListner(){
////        print("addListner")
////        Firestore.firestore().collection("Meetings")
////            .addSnapshotListener { (querySnapshot, error) in
////                guard let documents = querySnapshot?.documents else {
////                print("No documents")
////                return
////            }
////            self.meetings = documents.compactMap{ documents -> Meeting? in
////                try? documents.data(as: Meeting.self)
////            }
////        }
//////                guard let querySnapshot = querySnapshot else{print("에러! Listner");return}
//////                querySnapshot.documentChanges.forEach { meeting in
//////                    if (meeting.type == .added) || (meeting.type == .removed) {
//////                        self.meetings = querySnapshot.documents.compactMap{ documents -> Meeting? in
//////                            try? documents.data(as: Meeting.self)
//////                        }
//////                    }
//////                }
//////            }
//////        meetingsMap = (newMeeting != nil) ? meetings + [newMeeting!] : meetings
////    }
//    /// Listner 삭제
//    func removeListner(){
//        if let docListner{
//            docListner.remove()
//            self.docListner = nil
//        }
//    }
//    
//    func cancleMeeting(){
//        newMeeting = nil
//        meetingsMap = meetings
//    }
//    
//    func addMeeting(newMeeting: Meeting){
//        self.newMeeting = newMeeting
//        meetingsMap = (self.newMeeting != nil) ? meetings + [self.newMeeting!] : meetings
//    }
//    /// 새로운 모임 Firestore에 저장
//    func createMeeting(meeting: Meeting){
//            
//            //isLoading = true
//            //showKeyboard = false
//            Task{
//                do{
//                    /// - Firestore에 저장
//                    print("firebase save")
//                    let doc = Firestore.firestore().collection("Meetings").document()
//                    let _ = try doc.setData(from: meeting, completion: {error in
//                        if let error = error{
//                            print("Error CreateMeeting: \(error)")
//                        } else {
//                            print("모임 추가 완료")
//                        }
//                    })
//                    await fetchMeetings()
//                    
//                } catch {
//                    await handleError(error: error)
//                }
//            }
//        }
//    
//    
//    
//    /// 작성자 확인
//    func checkedOverlap(id: String){
//            let doc = Firestore.firestore().collection("Meetings").whereField("hostUID", isEqualTo: id)
//            doc.getDocuments(){ (query, err) in
//                if let err = err {
//                    print("checkedOverlap 에러: \(err)")
//                } else {
//                    print("중복 여부")
//                    if let query = query, !query.isEmpty {
//                        print("중복!: \(query.documents)")
//                        self.isOverlap = true
//                    } else {
//                        print("중복 아님!")
//                        self.isOverlap = false
//                    }
//                }
//            }
//    }
//    
//    func showMeeting(meetingId: String){
//        let doc = Firestore.firestore().collection("Meetings").document(meetingId)
//        doc.getDocument(as: Meeting.self) { result in
//            switch result {
//            case .success(let meeting):
//                self.meeting = meeting
//            case .failure(let err):
//                print("showMeeting 에러: \(err)")
//            }
//        }
//    }
//    
//    func joinMeeting(userId: String){
//        let doc = Firestore.firestore().collection("Meetings").document(userId)
//        doc.getDocument { (document, err) in
//            if let err = err {
//                print("joinMeeting 에러: \(err)")
//            } else {
//                guard var participants = document!["participants"] as? [String] else{print("participants오류");return}
//                participants.append(Auth.auth().currentUser!.uid)
//                doc.updateData(["participants" : participants])
//            }
//        }
//    }
//
//    
//    /// 에러처리
//    func handleError(error: Error)async{
//        await MainActor.run(body: {
//            errorMessage = error.localizedDescription
//            showError.toggle()
//            isLoading = false
//        })
//    }
//}
