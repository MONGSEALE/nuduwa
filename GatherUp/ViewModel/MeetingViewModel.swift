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

class MeetingViewModel: FirebaseViewModelwithMeetings {
    
    

    private var fetchedMeetings: [Meeting] = []         // 서버에서 가져오는 모임 배열
    @Published var deletedMeeting: Bool = false
    
    @Published var dicMembers: [String: Member] = [:]
    @Published var dicMembersData: [String: UserData] = [:]

    /// 찾기쉽게 members 배열을 딕셔너리로 변환
    override func convertMembers(meetingID: String){
        print("convertMembers")
        members.forEach { member in
            let uid = member.memberUID
            dicMembers[uid] = member
            
            if let memberData = dicMembersData[uid]{
                dicMembers[uid]?.memberName = memberData.userName
                dicMembers[uid]?.memberImage = memberData.userImage
            }else{
                Task{
                    await fetchMemberData(meetingID: meetingID, memberUID: uid)
                }
            }
        }
    }
    func fetchMemberData(meetingID: String, memberUID: String)async{
        do {
            let document = try await db.collection(strUsers).document(memberUID).getDocument()
            let name = document.data()?["userName"] as? String ?? ""
            let imageUrl = document.data()?["userImage"] as? String ?? ""
            let image = URL(string: imageUrl)
            self.dicMembersData[memberUID] = UserData(userName: name, userImage: image!)
            if dicMembers[memberUID] != nil{
                dicMembers[memberUID]!.memberName = name
                dicMembers[memberUID]!.memberImage = image!
            }
        } catch {
            print("에러 fetchMemberData: \(error)")
        }
    }
    
//    func fetchMembersData(meetingID: String){
//        Task{
//            if !dicMembers.isEmpty{
//                for uid in dicMembers.keys{
//                    do {
//                        let document = try await db.collection(strUsers).document(uid).getDocument()
//                        let name = document.data()?["userName"] as? String ?? ""
//                        let imageUrl = document.data()?["userImage"] as? String ?? ""
//                        let image = URL(string: imageUrl)
//                        self.dicMembersData[uid] = UserData(userName: name, userImage: image!)
////                        if dicMembers[uid] != nil{
////                            dicMembers[uid]!.memberName = name
////                            dicMembers[uid]!.memberImage = image!
////                        }
//                    } catch {
//                        print("Error getting document: \(error)")
//                    }
//                }
//            }
//        }
//    }
    
    
    
    
    /// FireStore와 meetings 배열 실시간 연동
    func meetingsListener(){
        print("meetingsListener")
        isLoading = true
        Task{
            do{
                docListener = db.collectionGroup(strMembers).whereField("memberUID", isEqualTo: currentUID as Any)
                    .addSnapshotListener { (querySnapshot, error) in
                        if let error = error {print("에러!meetingsListener:\(error)");return}
                        
                        var meetings: [Meeting] = []
                        let dispatchGroup = DispatchGroup()         // 비동기 작업 객체
                        
                        querySnapshot?.documents.forEach { document in
                            dispatchGroup.enter()                   // 비동기 시작
                            document.reference.parent.parent?.getDocument { (meetingDocument, meetingError) in
                                defer { dispatchGroup.leave();}     // 이 블록이 끝나면 비동기 끝
                                
                                if let meetingError = meetingError {print("에러!meetingsListener2:\(meetingError)");return}
                                
                                if let meetingDocument = meetingDocument, let meeting = try? meetingDocument.data(as: Meeting.self) {
                                    meetings.append(meeting)
                                }
                            }
                        }
                        dispatchGroup.notify(queue: .main) {        // 비동기 끝나면 실행
                            // 배열 정렬 host가 본인인경우 맨앞으로 그 다음에 meetingDate 날짜 순을 정렬
                            meetings.sort { (meeting1, meeting2) -> Bool in
                                if meeting1.hostUID == self.currentUID && meeting2.hostUID != self.currentUID {
                                    return true
                                } else if meeting1.hostUID != self.currentUID && meeting2.hostUID == self.currentUID {
                                    return false
                                } else {
                                    return meeting1.meetingDate < meeting2.meetingDate
                                }
                            }
                            self.isLoading = false
                            self.meetings = meetings
                        }
                    }
            }catch{
                await handleError(error)
            }
        }
        
    }
    

    
    ///모임 나가기
    func leaveMeeting(meetingID: String, memberUID: String?) {
        print("leaveMeeting")
        isLoading = true
        Task{
            do{
                guard let memberUID = memberUID else{return}
                let doc = db.collection(strMeetings).document(meetingID)

                await fetchUserAsync(userUID: memberUID)

                doc.collection(strMembers).whereField("memberUID", isEqualTo: memberUID).getDocuments { (querySnapshot, error) in
                    if let error = error {
                        print("에러: \(error)")
                        return
                    } else {
                        guard let documents = querySnapshot?.documents else { return }
                        for document in documents {
                            doc.collection(self.strMembers).document(document.documentID).delete()
                        }
                        doc.collection(self.strMessage).addDocument(data: [
                            "text": "\(self.user!.userName)님이 채팅에 나가셨습니다.",
                            "userId": "SYSTEM",
                            "userName": "SYSTEM",
                            "timestamp": Timestamp(),
                            "isSystemMessage": true
                        ])
                    }
                }
                await MainActor.run(body: {
                    isLoading = false
                })
            }catch{
                await handleError(error)
            }
        }
    }

    /// - 모임 지우기
    func deleteMeeting(meetingID: String){
        print("deleteMeeting")
        isLoading = true
        Task{
            let doc = db.collection(strMeetings).document(meetingID)
            doc.delete{ error in
                if let error = error{
                    self.firebaseError(error)
                }else{
                    doc.collection(self.strMembers).getDocuments{ querySnapshot, error in
                        if let error = error{
                            self.firebaseError(error)
                        }else{
                            for document in querySnapshot!.documents {
                                document.reference.delete()
                            }
                        }
                    }
                    doc.collection(self.strMessage).getDocuments{ querySnapshot, error in
                        if let error = error{
                            self.firebaseError(error)
                        }else{
                            for document in querySnapshot!.documents {
                                document.reference.delete()
                            }
                        }
                    }
                }
            }
            await MainActor.run(body: {
                isLoading = false
            })
        }
    }
    
    /// - 모임 수정하기
    func editMeeting(title: String, description: String, meetingDate: Date){
        print("updateMeeting:\(title)")
        isLoading = true
        Task{
            do{
                guard let meetingID = meeting.id else{return}
                
                if title != meeting.title {
                    try await
                    db.collection(strMeetings).document(meetingID).updateData(["title": title])
                    print("title 수정")
                }
                
                if description != meeting.description {
                    try await
                    db.collection(strMeetings).document(meetingID).updateData(["description": description])
                    print("description 수정")
                }
                
                if meetingDate != meeting.meetingDate {
                    try await
                    db.collection(strMeetings).document(meetingID).updateData(["meetingDate": meetingDate])
                    print("meetingDate 수정")
                }

                await MainActor.run(body: {
                    isLoading = false
                })
            }catch{
                await handleError(error)
            }
        }
    }
    

    func meetingListener(meetingID: String){
        print("meetingListener")
        isLoading = true
        docListener = db.collection(strMeetings).document(meetingID).addSnapshotListener({ snapshot, error in
            guard let snapshot = snapshot else{
                print("모임삭제")
                self.deletedMeeting = true
                self.isLoading = false
                return
            }
            guard let data = try? snapshot.data(as: Meeting.self)else{return}
            self.meeting = data
            self.isLoading = false
            print("모임수정")
        })
    }
}

