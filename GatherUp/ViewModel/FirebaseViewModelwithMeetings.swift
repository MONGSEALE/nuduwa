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

    
    
    @Published var members: [Member] = []
    @Published var meetings: [Meeting] = []     // 모임 배열
    @Published var joinMeetingIDs: [String] = []     // 가입모임ID 배열

    //나중에 하위 클래스로 이동
    @Published var meeting: Meeting?

    /// 자식Class MeetingViewModel에서 쓸 함수
    func convertMembers(meetingID: String) { }
    
    /// 모임맴버 가져오기
    func membersListener(meetingID: String){
        print("membersListener")
        let col = db.collection(strMeetings).document(meetingID).collection(strMembers)

        let listener = col.addSnapshotListener { querySnapshot, error in
            if let error = error{print("에러membersListener:\(error)");return}
            
            guard let documents = querySnapshot?.documents else {return}
            self.members = documents.compactMap{ documents -> Member? in
                documents.data(as: Member.self)
            }
            print("member:\(self.members)")
            self.convertMembers(meetingID: meetingID)
        }
        listeners[col.path] = listener
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
    func joinMeeting(meetingID: String, meetingDate: Date, hostUID: String, numbersOfMembers: Int){
        print("joinMeeting")
        isLoading = true
        Task{
            do{
                guard let currentUID = currentUID,
                      let user = try await getUser(currentUID) else{return}
                print("저장1")

                let meetingsDoc = db.collection(strMeetings).document(meetingID)
                let joinMeetingsCol = db.collection(strUsers).document(currentUID).collection(strMeetingList)
                let membersCol = db.collection(strMeetings).document(meetingID).collection(strMembers)
            
                let member = Member(memberUID: currentUID)
                
                // 모임-멤버 컬렉션에 유저추가
                let docRef = try await meetingsDoc.collection(strMembers).addDocument(data: member.firestoreData)
                
                if numbersOfMembers != 0 {
                    // numbersOfMembers가 0이면 최초생성
                    // 멤버수가 최대멤버수 초과하지 않았는지 다시 확인
                    let membersSnapshot = try await membersCol.getDocuments()
                    let fetchedMembers = membersSnapshot.documents.compactMap{ document -> Member? in
                        document.data(as: Member.self)
                    }
                    
                    let currentDate = fetchedMembers.first(where: { $0.memberUID == currentUID })?.joinDate
                    guard let currentDate = currentDate else{return}
                    let filteredMembers = fetchedMembers.filter { member in
                        return member.joinDate < currentDate
                    }
                    if filteredMembers.count >= numbersOfMembers {
                        // 멤버수가 최대멤버수 초과했을때 멤버 삭제
                        try await docRef.delete()
                        print("모임 참가 실패")
                        //참가 실패시 에러핸들 구현
                        await MainActor.run {
                            isLoading = false
                        }
                        return
                    }
                }
                    
                // 멤버수가 최대멤버수 초과하지 않았을때
                // 비동기로 2개 작업 동시 실행
                await withThrowingTaskGroup(of: Void.self) { group in
                    // UserMeeting 컬렉션에 모임 추가
                    group.addTask {
                        do {
                            let meetingList = MeetingList(meetingID: meetingID, meetingDate: meetingDate, hostUID: hostUID)
                            try await joinMeetingsCol.addDocument(data: meetingList.firestoreData)
                        } catch {
                            throw error
                        }
                    }
                    // 모임-메시지 컬렉션에 메시지 추가
                    group.addTask {
                        do {
                            let text = "\(user.userName)님이 채팅에 참가하셨습니다."
                            let message = Message(text, uid: "SYSTEM", isSystemMessage: true)
                            try await meetingsDoc.collection(self.strMessage).addDocument(data: message.firestoreData)
                        } catch {
                            throw error
                        }
                    }
                }
                
                //참가 실패시 에러핸들 구현
                await MainActor.run {
                    isLoading = false
                }
                
            } catch {
                handleErrorTask(error)
            }
        }
    }
    
    func joinMeetingsListener(){
        guard let currentUID = currentUID else{return}

        let col = db.collection(strUsers).document(currentUID).collection(strMeetingList)

        let listener = col.addSnapshotListener { querySnapshot, error in
            if let error = error{
                self.handleErrorTask(error)
                return
            }
            guard let querySnapshot = querySnapshot else{
                return
            }
            self.joinMeetingIDs = querySnapshot.documents.compactMap{ documents -> String? in
                try? documents.data()["meetingID"] as? String
            }
        }
        listeners[col.path] = listener
    }
}

