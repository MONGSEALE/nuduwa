//
//  FirebaseViewModelwithMeetings.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/05/09.
//


import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

class FirebaseViewModelwithMeetings: FirebaseViewModel {

    struct MemberData {
        var memberName: String
        var memberImage: URL
    }
    
    @Published var members: [Member] = []
    @Published var dicMembers: [String:Member] = [:]
    @Published var dicMembersData: [String:MemberData] = [:]

    @Published var meetings: [Meeting] = []     // 모임 배열

    //나중에 하위 클래스로 이동
    @Published var meeting: Meeting = Meeting(title: "", description: "", place: "", numbersOfMembers: 0, latitude: 0, longitude: 0, hostUID: "")

    /// 찾기쉽게 members 배열을 딕셔너리로 변환
    func convertMembers() {
        members.forEach { member in
            let uid = member.memberUID
            dicMembers[uid] = member
            
            if !dicMembersData.isEmpty{
                if let memberData = dicMembersData[uid] {
                    dicMembers[uid]?.memberName = memberData.memberName
                    dicMembers[uid]?.memberImage = memberData.memberImage
                }
            }
        }
    }
    /// 모임맴버 가져오기
    func membersListener(meetingID: String){
        print("membersListener")
        Task{
            let doc = db.collection(strMeetings).document(meetingID).collection(strMembers)
            docListener = doc.addSnapshotListener { (querySnapshot, error) in
                if let error = error{
                    self.firebaseError(error)
                    return
                }
                guard let documents = querySnapshot?.documents else {return}
                self.members = documents.compactMap{ documents -> Member? in
                    try? documents.data(as: Member.self)
                }
                self.convertMembers()
            }
        }
    }

    /// = 서버에서 수정된 모임 meetings 배열에서 수정하기
    func updateLocalMeetingDataFromServer(updatedMeeting: Meeting) {
        print("updateLocalMeetingDataFromServer")
        guard let index = meetings.firstIndex(where: { meeting in
            meeting.id == updatedMeeting.id
        }) else {return}
        meetings[index] = updatedMeeting
    }

    /// - 서버에서 삭제된 모임 meetings 배열에서 삭제하기
    func deleteLocalMeetingDataFromServer(deletedMeetingID: String) {
        print("deleteLocalMeetingDataFromServer")
        meetings.removeAll{deletedMeetingID == $0.id}
    }
    
    /// 모임 참가하기
    func joinMeeting(meetingID: String, numbersOfMembers: Int){
        print("joinMeeting")
        isLoading = true
        Task{
            do{
                await fetchCurrentUserAsync()
                guard let user = self.currentUser else{return}
                let member = Member(memberUID: user.id!, memberName: user.userName, memberImage: user.userImage ?? URL(string: ""))
                let doc = db.collection(strMeetings).document(meetingID)
                
                if members.count < numbersOfMembers {
                    try doc.collection(strMembers).document().setData(from: member, completion: {error in
                        if let error = error{
                            self.firebaseError(error)
                            self.isLoading = false
                            return
                        }
                        print("모임 참가 완료")
                        doc.collection(self.strMessage).addDocument(data: [
                            "text": "\(user.userName)님이 채팅에 참가하셨습니다.",
                            "userId": "SYSTEM",
                            "userName": "SYSTEM",
                            "timestamp": Timestamp(),
                            "isSystemMessage": true
                        ])
                    })
                }else{print("모임 참가 실패")}


                //참가 실패시 에러핸들 구현


            
                await MainActor.run(body: {
                    isLoading = false
                })
            } catch {
                await handleError(error)
            }
        }
    }
}

