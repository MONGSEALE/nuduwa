//
//  JoinMeeting.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/05/15.
//

import SwiftUI
import Firebase
import FirebaseFirestoreSwift

struct MeetingList: Identifiable, Codable, FirestoreConvertible {
    @DocumentID var id: String?

    let meetingID: String
    let isEnd: Bool
    var meetingDate: Date
    var joinDate: Date
    let hostUID: String
    let nonReviewMembers: [String]?

    // 기본 생성자
    init(meetingID: String, meetingDate: Date, hostUID: String) {
        self.id = UUID().uuidString
        self.meetingID = meetingID
        self.isEnd = false
        self.meetingDate = meetingDate
        self.joinDate = Date()
        self.hostUID = hostUID
        self.nonReviewMembers = nil
    }

    // Firestore에서 가져올 필드 - guard문 값이 하나라도 없으면 nil 반환
    init?(data: [String: Any], id: String) {
        guard let meetingID = data["meetingID"] as? String,
              let isEnd = data["isEnd"] as? Bool,
              let meetingDate = data["meetingDate"] as? Timestamp,
              let joinDate = data["joinDate"] as? Timestamp,
              let hostUID = data["hostUID"] as? String
        else { return nil }
        
        self.id = id
        self.meetingID = meetingID
        self.isEnd = isEnd
        self.meetingDate = meetingDate.dateValue()
        self.joinDate = joinDate.dateValue()
        self.hostUID = hostUID
        self.nonReviewMembers = data["nonReviewMembers"] as? [String] ?? nil
    }
    
    // Firestore에 저장할 필드
    var firestoreData: [String: Any] {
        return [
            "meetingID": meetingID,
            "isEnd" : isEnd,
            "meetingDate" : meetingDate,
            "joinDate": FieldValue.serverTimestamp(),
            "hostUID": hostUID
        ]
    }
    // 종료된 모임 수정
    static func firestoreEndMeeting(_ membersUID: [String]) -> [String: Any] {
        return [
            "isEnd" : true,
            "nonReviewMembers" : membersUID
        ]
    }
    // 멤버리뷰 썼을때 수정
    static func createReview(_ userUID: String) -> [String: Any] {
        print("createReview구조체")
        return [
            "nonReviewMembers" : FieldValue.arrayRemove([userUID])
        ]
    }
}

