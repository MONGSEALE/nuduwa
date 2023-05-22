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
    

    @Published var userMeetings: [MeetingList] = []  //수정
    
    @Published var dicMembers: [String: Member] = [:]
    @Published var dicMembersData: [String: User] = [:]
    // @Published var deletedMeeting: Bool = false
    // @Published var isDelete: Bool = false

    /// 찾기쉽게 members 배열을 딕셔너리로 변환
    override func convertMembers(meetingID: String){
        print("convertMembers")
        fetchMemberData()
        var membersUID: [String] = []
        var keysToRemove: [String] = []

        for member in members{
            let uid = member.memberUID
            membersUID.append(uid)
            dicMembers[uid] = member
            
            if dicMembersData[uid] == nil {continue}

            dicMembers[uid]?.memberName = dicMembersData[uid]?.userName
            dicMembers[uid]?.memberImage = dicMembersData[uid]?.userImage
        }

        // membersUID에 없는 키를 찾아서 keysToRemove 배열에 추가
        for key in dicMembers.keys {
            if !membersUID.contains(key) {
                keysToRemove.append(key)
            }
        }

        // keysToRemove 배열에 있는 키를 dicMembers에서 제거
        for key in keysToRemove {
            dicMembers.removeValue(forKey: key)
            dicMembersData.removeValue(forKey: key)
        }
        
    }

    // 오류 생기면 Task를 for문 밖으로 빼보기
    func fetchMemberData() {
        print("fetchMemberData")
        for member in members{
            let uid = member.memberUID
            if dicMembersData[uid] != nil {continue}
            Task{
                do{
                    print("uid:\(uid)")
                    dicMembersData[uid] = try await getUser(uid)
//                    guard let memberData = dicMembersData[uid] else{return}
                    await MainActor.run{
                        dicMembers[uid]?.memberName = dicMembersData[uid]?.userName
                        dicMembers[uid]?.memberImage = dicMembersData[uid]?.userImage
                    }
                }catch{
                    print("오류!dicMembersData.UID:\(uid)")
                }
            }
        }
    }

    func sortMeeting(_ meetings: [Meeting]){
        var sortMeeings = meetings
        sortMeeings.sort { (meeting1, meeting2) -> Bool in
            if meeting1.hostUID == self.currentUID && meeting2.hostUID != self.currentUID {
                return true
            } else if meeting1.hostUID != self.currentUID && meeting2.hostUID == self.currentUID {
                return false
            } else {
                return meeting1.meetingDate < meeting2.meetingDate
            }
        }
        self.meetings = sortMeeings
    }
    
    /// FireStore와 meetings 배열 실시간 연동
    func meetingsListener(){
        print("meetingsListener")
        guard let currentUID = currentUID else{return}
        let query = db.collectionGroup(strMembers).whereField("memberUID", isEqualTo: currentUID)
        if listeners[query.description] != nil {print("리스너이미실행중");return}
        isLoading = false
        
        let listener = query.addSnapshotListener { querySnapshot, error in
            if let error = error {print("에러!meetingsListener:\(error)");return}
            
            var meetings: [Meeting] = []

            guard let querySnapshot = querySnapshot else{return}
            for diff in querySnapshot.documentChanges{
                if (diff.type == .modified) {
                    let meetingID = diff.document.reference.parent.parent?.documentID
                    guard let meetingID = meetingID else{continue}
                    self.fetchMeeting(meetingID)
                }
                if (diff.type == .removed) {
                    print("Removed city: \(diff.document.data())")
                }
            }
            
//                        guard let documents = querySnapshot.documents else{return}
            for document in querySnapshot.documents {
                if let meetingDocument = document.reference.parent.parent {
                    meetingDocument.getDocument{ meetingSnapshot, error in
                        if let meeting = meetingSnapshot!.data(as: Meeting.self) {
                            meetings.append(meeting)
                        }
                        print("모임:\(meetings)")
                        self.sortMeeting(meetings)
                        self.isLoading = false
                    }
                }
                
            }
        }
        listeners[query.description] = listener
        
    }
     /// FireStore와 meetings 배열 실시간 연동
    func userMeetingsListener(){
        print("userMeetingsListener")
        isLoading = false
        Task{
            do{
                guard let currentUID = currentUID else{return}
                let query = db.collection(strUsers).document(currentUID).collection(strMeetingList)
                    .whereField("isEnd", isEqualTo: false)
                    // .order(by: "meetingDate", descending: true)
                let listener = query.addSnapshotListener { querySnapshot, error in
                    if let error = error {print("에러!meetingsListener:\(error)");return}
                    
                    var meetings: [Meeting] = []
                    
                    guard let documents = querySnapshot?.documents else{return}
                    self.userMeetings = documents.compactMap { document -> MeetingList? in
                        document.data(as: MeetingList.self)
                    }.sorted(by: { meeting1, meeting2 in
                       if meeting1.hostUID == currentUID && meeting2.hostUID != currentUID {
                            return true // meeting1의 hostUID가 currentUID와 같을 때 meeting1을 앞으로 정렬
                        } else if meeting1.hostUID != currentUID && meeting2.hostUID == currentUID {
                            return false // meeting2의 hostUID가 currentUID와 같을 때 meeting2를 앞으로 정렬
                        } else {
                            // hostUID가 같은 경우 meetingDate 필드를 기준으로 내림차순 정렬
                            return meeting1.meetingDate > meeting2.meetingDate
                        }   
                    })                 
                }
                listeners[query.description] = listener
            }catch{
                await handleError(error)
            }
        }
    }

    /// 모임 데이터 가져오기
    func fetchMeeting(_ meetingID: String){
        print("meetingListner")
        Task{
            do{
                let doc = db.collection(strMeetings).document(meetingID)
                let updatedMeeting = try await doc.getDocument(as: Meeting.self)
                guard let index = meetings.firstIndex(where: { meeting in
                    meeting.id == updatedMeeting.id
                }) else {return}
                meetings[index] = updatedMeeting
            }catch{
                print("에러fetchMeeting")
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
                let query = doc.collection(strMembers)
                            .whereField("memberUID", isEqualTo: memberUID)

                guard let member = try await getUser(memberUID) else{return}  //오류메시지 출력해야함

                let querySnapshot = try await query.getDocuments()

                for document in querySnapshot.documents {
                    try await doc.collection(strMembers).document(document.documentID).delete()
                }

                let text = "\(member.userName)님이 채팅에 나가셨습니다."
                let message = Message(text, uid: "", isSystemMessage: true)

                try await doc.collection(strMessage).addDocument(data: message.firestoreData)
                    
                
                isLoading = false
                // query.getDocuments { (querySnapshot, error) in
                //     if let error = error {
                //         print("에러: \(error)")
                //         return
                //     } else {
                //         guard let documents = querySnapshot?.documents else { return }
                //         for document in documents {
                //             doc.collection(self.strMembers).document(document.documentID).delete()
                //         }
                //         doc.collection(self.strMessage).addDocument(data: [
                //             "text": "\(self.user!.userName)님이 채팅에 나가셨습니다.",
                //             "userId": "SYSTEM",
                //             "userName": "SYSTEM",
                //             "timestamp": Timestamp(),
                //             "isSystemMessage": true
                //         ])
                //     }
                // }
                // await MainActor.run(body: {
                //     isLoading = false
                // })
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
                    self.handleErrorTask(error)
                }else{
                    doc.collection(self.strMembers).getDocuments{ querySnapshot, error in
                        if let error = error{
                            self.handleErrorTask(error)
                        }else{
                            for document in querySnapshot!.documents {
                                document.reference.delete()
                            }
                        }
                    }
                    doc.collection(self.strMessage).getDocuments{ querySnapshot, error in
                        if let error = error{
                            self.handleErrorTask(error)
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
    func editMeeting(title: String?, description: String?, place: String?, numbersOfMembers: Int?, meetingDate: Date?){
        print("updateMeeting:\(title)")
        isLoading = true
        Task{
            do{
                guard let meeting = meeting else{return}
                guard let meetingID = meeting.id else{return}
                
                let doc = db.collection(strMeetings).document(meetingID)
                let updateMeeting = Meeting.updateMeeting(title: title, description: description, place: place, numbersOfMembers: numbersOfMembers, meetingDate: meetingDate)
                try await doc.updateData(updateMeeting.firestoreUpdate)

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
        isLoading = false
        let doc = db.collection(strMeetings).document(meetingID)
        
        let listener = doc.addSnapshotListener{ snapshot, error in
            if let error = error {
                self.handleErrorTask(error)
                return
            }
            guard let snapshot = snapshot else{
                print("모임삭제됨")
                self.isLoading = false
                return
            }
            guard let data = snapshot.data(as: Meeting.self) else{
                print("오류")
                return
            }
            print("모임\(data)")
            Task{
                await MainActor.run{
                    self.meeting = data
                    self.isLoading = false
                }
            }
        }
        listeners[doc.description] = listener
    }
    // 모임 host 이름과 이미지 가져오기
    func fetchHostData()  {
        Task{
            do{
                meeting = try await getHostData(meeting: meeting)
            }catch{
                print("오류!")
            }
        }
    }
    // 모임 host 이름과 이미지 가져오기
    func getHostData(meeting: Meeting?) async throws -> Meeting? {
        guard let meeting = meeting else{throw SomeError.error}
        do{
            guard let host = try await getUser(meeting.hostUID) else{throw SomeError.error}
            return Meeting.putHostData(meeting: meeting, user: host)
        }catch{
            throw error
        }
    }
}

/*
func meetingListener(meetingID: String){
        print("meetingListener")
        isLoading = false
        let doc = db.collection(strMeetings).document(meetingID)
        
        let listener = doc.addSnapshotListener({ snapshot, error in
            if let error = error {
                self.handleErrorTask(error)
                return
            }
            guard let snapshot = snapshot else{
                print("모임삭제")
                self.deletedMeeting = true
                self.isLoading = false
                return
            }
            guard let data = try? snapshot.data(as: Meeting.self) else{
                print("오류")
                return
            }
            self.meeting = data
            self.isLoading = false
            print("모임수정")
        })
        listeners[doc.description] = listener
    }
    */
