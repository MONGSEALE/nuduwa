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
    /* meetingListListener로 변경
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
     */

    /// 모임 데이터 가져오기
    func fetchMeeting(_ meetingID: String){
        print("fetchMeeting")
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
                guard let memberUID else{return}

                let meetingDoc = db.collection(strMeetings).document(meetingID)
                let memberQuery = meetingDoc.collection(strMembers)
                            .whereField("memberUID", isEqualTo: memberUID)
                let meetingListQuery = db.collection(strUsers).document(memberUID).collection(strMeetingList).whereField("meetingID", isEqualTo: meetingID)

                guard let member = try await getUser(memberUID) else{return}  //오류메시지 출력해야함

                try await memberQuery.getDocuments().documents.first?.reference.delete()
                
                try await meetingListQuery.getDocuments().documents.first?.reference.delete()
                    
                let text = "\(member.userName)님이 채팅에 나가셨습니다."
                let message = Message(text, uid: "", isSystemMessage: true)

                try await meetingDoc.collection(strMessage).addDocument(data: message.firestoreData)
                
                await MainActor.run{
                    isLoading = false
                }
            }catch{
                await handleError(error)
            }
        }
    }

    /// - 모임 지우기
    // 예전(주석처리)에는 서버에서 모임데이터를 아예 지웠는데
    // 현재는 서버에는 데이터 남아있고 지도와 모임탭에서 안보이게 수정
    // 추후 프로필에 이전모임 탭이 생기면 거기서 지워진 모임 확인가능하게 수정예정
    func cancleMeeting(meetingID: String){
        print("cancleMeeting")
        isLoading = true
        Task{
            do{
                let meetingDoc = db.collection(strMeetings).document(meetingID)
                let membersUID = self.members.map{$0.memberUID}
                for member in members {
                    Task{
                        let index = membersUID.firstIndex(of: member.memberUID)
                        guard let index else {return}
                        var membersUIDwithoutMember = membersUID
                        membersUIDwithoutMember.remove(at: index)
                        let memberMeetingListQuery = db.collection(strUsers).document(member.memberUID).collection(strMeetingList).whereField("meetingID", isEqualTo: meetingID)
                        let meetingListDoc = try await memberMeetingListQuery.getDocuments()
                        try await meetingListDoc.documents.first?.reference.updateData(MeetingList.firestoreEndMeeting(membersUIDwithoutMember))
                    }
                }
                try await meetingDoc.updateData(Meeting.firestorePastMeeting())
                
                await MainActor.run(body: {
                    isLoading = false
                })
            }catch{
                print("모임삭제 오류")
            }
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
