//
//  MeetingViewModel.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/04/05.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

class MeetingViewModel: ObservableObject {
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
    
    //chat기능 변수
    private let db = Firestore.firestore()
    private let strMeetings = "Meetings"        // Firestore에 저장된 콜렉션 이름
    private let strMembers = "Members"          // Firestore에 저장된 콜렉션 이름
    private let strMessage = "Message"          // Firestore에 저장된 콜렉션 이름
    @Published var messages: [ChatMessage] = []
    @Published  var lastMessageId: String = ""
    private var listenerRegistration: ListenerRegistration?
    
    /// 서버 모임과 새로 추가하는 모임(서버 저장전) 배열 합치기
    func combineMeetings(){
        meetings = (newMeeting != nil) ? fetchedMeetings + [newMeeting!] : fetchedMeetings
    }
    
    /// FireStore와 meetings 배열 실시간 연동
    func meetingsListner(isPassed: Bool = false){
        guard let uid = Auth.auth().currentUser?.uid else{return}
        docListner = db.collectionGroup(strMembers).whereField("memberUID", isEqualTo: uid)
            .addSnapshotListener { (querySnapshot, error) in
                if let error = error {print("에러!meetingsListner:\(error)");return}
                print("listen")
                
                var meetings: [Meeting] = []
                let dispatchGroup = DispatchGroup()         // 비동기 작업 객체
                
                querySnapshot?.documents.forEach { document in
                    dispatchGroup.enter()                   // 비동기 시작
                    document.reference.parent.parent?.getDocument { (meetingDocument, meetingError) in
                        defer { dispatchGroup.leave();}     // 이 블록이 끝나면 비동기 끝
                        
                        if let meetingError = meetingError {print("에러!meetingsListner2:\(meetingError)");return}
                        
                        if let meetingDocument = meetingDocument, let meeting = try? meetingDocument.data(as: Meeting.self) {
                            meetings.append(meeting)
                        }
                    }
                }
                dispatchGroup.notify(queue: .main) {        // 비동기 끝나면 실행
                    guard let uid = Auth.auth().currentUser?.uid else{return}
                    // 배열 정렬 host가 본인인경우 맨앞으로 그 다음에 meetingDate 날짜 순을 정렬
                    meetings.sort { (meeting1, meeting2) -> Bool in
                        if meeting1.hostUID == uid && meeting2.hostUID != uid {
                            return true
                        } else if meeting1.hostUID != uid && meeting2.hostUID == uid {
                            return false
                        } else {
                            return meeting1.meetingDate < meeting2.meetingDate
                        }
                    }
                    self.isFetching = false
                    self.meetings = meetings
                }
            }
        
    }
    
    /// 리스너 제거(리소스 확보)
    func removeListner(){
        if let docListner{
            docListner.remove()
            self.docListner = nil
        }
    }
    /// 모임 추가시(서버 저장전)
    func addMeeting(newMeeting: Meeting){
        self.newMeeting = newMeeting
        combineMeetings()
    }
    /// 모임 추가 취소 또는 모임 서버 저장했을때 newMeeting 초기화
    func cancleMeeting(){
        newMeeting = nil
        combineMeetings()
    }
    /// 새로운 모임 Firestore에 저장
    func createMeeting(meeting: Meeting){
        //showKeyboard = false
        Task{
            do{
                /// - Firestore에 저장
                print("firebase save")
                let document = try db.collection(strMeetings).addDocument(from: meeting)
                let meetingId = document.documentID
                print("Meeting ID: \(meetingId)")
                joinMeeting(meetingId: meetingId)
            } catch {
                await handleError(error: error)
            }
        }
    }
    /// 작성자 중복 확인
    func checkedOverlap(id: String?){
        if id==nil {
            print("아이디가 NULL임")
            self.isOverlap = true
            return
        }else{
            let doc = db.collection(strMeetings).whereField("hostUID", isEqualTo: id!)
            doc.getDocuments(){ (query, err) in
                if let err = err {
                    print("checkedOverlap 에러: \(err)")
                } else {
                    print("중복 여부")
                    if let query = query, !query.isEmpty {
                        print("중복!: \(query.documents)")
                        self.isOverlap = true
                    } else {
                        print("중복 아님!")
                        self.isOverlap = false
                    }
                }
            }
        }
    }
    
    /// 모임 참가하기
    func joinMeeting(meetingId: String){
        print("joinMeeting")
        Task{
            do{
                guard let user = Auth.auth().currentUser else{return}
                let member = Members(memberUID: user.uid, memberName: user.displayName!, memberImage: user.photoURL)
                let doc = db.collection(strMeetings).document(meetingId).collection(strMembers).document()
//                let doc = db.document(meetingId).collection("members").document()
                let _ = try doc.setData(from: member, completion: {error in
                    if let error = error{
                        print("Error CreateMeeting: \(error)")
                    } else {
                        print("모임 추가 완료")
                    }
                })
            } catch {
                await handleError(error: error)
                //isLoading = false
            }
        }
    }
    
    ///모임 나가기
    func leaveMeeting(meetingId: String) {
        guard let currentUser = Auth.auth().currentUser else { return }
        let doc = db.collection(strMeetings).document(meetingId).collection(strMembers)

        doc.whereField("memberUID", isEqualTo: currentUser.uid).getDocuments { (snapshot, error) in
            if let error = error {
                print("에러: \(error)")
            } else {
                guard let documents = snapshot?.documents else { return }
                for document in documents {
                    doc.document(document.documentID).delete()
                }
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
    

    /// - 모임 지우기
    func deleteMeeting(deletedMeeting: Meeting){
        Task{
            do{
                /// Delete Firestore Document
                guard let meetingID = deletedMeeting.id else{return}
                try await db.collection(strMeetings).document(meetingID).delete()
            }catch{
                print(error.localizedDescription)
            }
        }
    }
    
    /// - 모임 수정하기
    func updateMeeting(editMeeting: Meeting, title: String, description: String, meetingDate: Date){
        Task{
            do{
                /// Delete Firestore Document
                guard let meetingID = editMeeting.id else{return}
                
                if title != editMeeting.title {
                    try await
                    db.collection(strMeetings).document(meetingID).updateData(["title": title])
                    print("title 수정")
                }
                
                if description != editMeeting.description {
                    try await
                    db.collection(strMeetings).document(meetingID).updateData(["description": description])
                    print("description 수정")
                }
                
                if meetingDate != editMeeting.meetingDate {
                    try await
                    db.collection(strMeetings).document(meetingID).updateData(["meetingDate": meetingDate])
                    print("meetingDate 수정")
                }
            }catch{
                print(error.localizedDescription)
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

