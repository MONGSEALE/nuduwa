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

// 이것도 FirebaseViewModel와 비슷하게 상속되는 부모클래스
// Firestore Meetings 컬렉션을 사용하는 ViewModel이 상속받는다
// Meeting, Member, MeetingList 배열이 있다.
// Member와 MeetingList 리스너 함수, 모임 참가하기 함수가 있다.

class FirebaseViewModelwithMeetings: FirebaseViewModel {

    @Published var members: [Member] = []
    @Published var meetings: [Meeting] = []     // 모임 배열
    
    @Published var meetingsList: [MeetingList] = []  //수정

    //나중에 하위 클래스로 이동
    @Published var meeting: Meeting?

    /// 자식Class MeetingViewModel에서 쓸 함수
    func convertMembers(meetingID: String) { }
    
    /// 모임맴버 실시간으로 클래스 변수 members에 저장
    func membersListener(meetingID: String){
        print("membersListener")
        let col = db.collection(strMeetings).document(meetingID).collection(strMembers)

        let listener = col.addSnapshotListener { querySnapshot, error in
            if let error = error{print("에러membersListener:\(error)");return}
            
            guard let documents = querySnapshot?.documents else {return}
            self.members = documents.compactMap{ documents -> Member? in
                documents.data(as: Member.self)
            }
            self.convertMembers(meetingID: meetingID)
        }
        listeners[col.path] = listener   // 리스너 저장
    }

    /// 유저가 참여한 모임리스트 실시간으로 클래스 변수 meetings에 저장
    func meetingsListListener(){
        print("meetingsListListener")
        guard let currentUID = currentUID else{return}
        isLoading = true
        Task{
            do{
                // 끝나지 않은 모임만 가져오는 쿼리
                let query = db.collection(strUsers).document(currentUID).collection(strMeetingList)
                    .whereField("isEnd", isEqualTo: false)
                    // .order(by: "meetingDate", descending: true) // 밑에서 정렬함
                let listener = query.addSnapshotListener { querySnapshot, error in
                    // 리스너 다 실행되면 isLoading = false
                    defer {self.isLoading = false}
                    if let error = error {print("에러!meetingsListener:\(error)");return}
                                        
                    guard let documents = querySnapshot?.documents else{return}
                    self.meetingsList = documents.compactMap { document -> MeetingList? in
                        document.data(as: MeetingList.self)
                    }.sorted(by: { meeting1, meeting2 in
                    // 자신이 만든 모임이 제일 앞으로 가게 정렬한다음 모임시간순으로 정렬
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

// 오류 안나면 삭제 예정
    // /// = 서버에서 수정된 모임 meetings 배열에서 수정하기
    // func updateLocalMeetingDataFromServer(updatedMeeting: Meeting) {
    //     print("updateLocalMeetingDataFromServer")
    //     guard let index = meetings.firstIndex(where: { meeting in
    //         meeting.id == updatedMeeting.id
    //     }) else {return}
    //     meetings[index] = updatedMeeting
    // }

    // /// - 서버에서 삭제된 모임 meetings 배열에서 삭제하기
    // func deleteLocalMeetingDataFromServer(deletedMeetingID: String) {
    //     print("deleteLocalMeetingDataFromServer")
    //     meetings.removeAll{deletedMeetingID == $0.id}
    // }
    
    /// 모임 참가하기
    func joinMeeting(meetingID: String, meetingDate: Date, hostUID: String, numbersOfMembers: Int){
        print("joinMeeting")
        isLoading = true
        Task{
            do{
                guard let currentUID = currentUID,
                    // 유저 이름 가져오기용 user 변수
                      let user = try await getUser(currentUID)
                else{print("조인미팅오류");isLoading = false;return}

                // 컬렉션들 경로
                let membersCol = db.collection(strMeetings).document(meetingID).collection(strMembers)
                let messageCol = db.collection(strMeetings).document(meetingID).collection(strMessage)
                let joinMeetingsCol = db.collection(strUsers).document(currentUID).collection(strMeetingList)
                // membersCol에 저장할 데이터
                let member = Member(memberUID: currentUID)
                
                // 모임-멤버 컬렉션에 유저추가
                let docRef = try await membersCol.addDocument(data: member.firestoreData)

                if numbersOfMembers != 0 {
                    // numbersOfMembers가 0이면 최초생성이므로 확인작업 패스
                    // 멤버수가 최대멤버수 초과하지 않았는지 다시 확인
                    try await Task.sleep(nanoseconds: 200_000_000) // 유저추가 동기화될때까지 0.2초 대기
                    // 멤버정보 가져오기
                    let membersSnapshot = try await membersCol.getDocuments()


//                    guard let currentDate = membersSnapshot.documents.compactMap({ $0.data(as: Member.self) }).first(where: { $0.memberUID == currentUID })?.joinDate else {
//                        isLoading = false
//                        return
//                    }
//
//                    let numberOfFilteredMembers = membersSnapshot.documents.compactMap({ $0.data(as: Member.self) }).filter({ $0.joinDate < currentDate }).count
//
//                    print("4")
//
//                    if numberOfFilteredMembers >= numbersOfMembers {
//                        // 원하는 동작 수행
//                    }

                    // 멤버정보 배열로 만들어서 저장
                    let fetchedMembers = membersSnapshot.documents.compactMap{ document -> Member? in
                        document.data(as: Member.self)
                    }
                    // 위에서 member가 서버에 저장된 시간 currentDate에 저장
                    guard let currentDate = fetchedMembers.first(where: { $0.memberUID == currentUID })?.joinDate else{isLoading = false;return}
                    // currentDate보다 먼저 참여한 멤버수 저장
                    let membersCount = fetchedMembers.filter({ $0.joinDate < currentDate }).count

                    // currentDate보다 먼저 참여한 멤버수가 numbersOfMembers 이상이면 참가실패로 멤버에서 삭제
                    if membersCount >= numbersOfMembers {
                        // 멤버수가 최대멤버수 초과했을때 멤버 삭제
                        try await docRef.delete()
                        print("모임 참가 실패")
                        //참가 실패시 에러핸들 구현
                        isLoading = false
                        return
                    }
                }
                // 멤버수가 최대멤버수 초과하지 않았을때
                // 비동기로 2개 작업 동시 실행
                await withThrowingTaskGroup(of: Void.self) { group in
                    print("비동기실행")
                    // UserMeeting 컬렉션에 모임 추가
                    group.addTask {
                        do {
                            let meetingList = MeetingList(meetingID: meetingID, meetingDate: meetingDate, hostUID: hostUID)
                            try await joinMeetingsCol.addDocument(data: meetingList.firestoreData)
                            print("joinMeetingsCol추가")
                        } catch {
                            print("joinMeetingsCol추가실패")
                            throw error
                        }
                    }
                    // 모임-메시지 컬렉션에 메시지 추가
                    group.addTask {
                        do {
                            let text = "\(user.userName)님이 채팅에 참가하셨습니다."
                            let message = Message(text, uid: "SYSTEM", isSystemMessage: true)
                            try await messageCol.addDocument(data: message.firestoreData)
                            print("Message추가")
                        } catch {
                            print("Message추가실패")
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
    
    

    /// meetingDate 지나면 지도에서 안보이게
    func pastMeeting(meetingID: String) {
        print("pastMeeting")
        Task{
            do{
                let doc = db.collection(strMeetings).document(meetingID)

                try await doc.updateData(Meeting.firestorePastMeeting())

            }catch{
                print("지난모임오류")
            }
        }
    }
}

