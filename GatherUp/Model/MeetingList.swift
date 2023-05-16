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
    @DocumentID var id: String

    let meetingID: String
    var joinDate: Date
    let isHost: Bool

    // 기본 생성자
    init(meetingID: String, isHost: Bool? = nil) {
        self.id = UUID().uuidString
        self.meetingID = meetingID
        self.joinDate = Date()
        self.isHost = isHost ?? false
    }

    // Firestore에서 가져올 필드 - guard문 값이 하나라도 없으면 nil 반환
    init?(data: [String: Any], id: String) {
        guard let meetingID = data["meetingID"] as? String,
              let joinDate = data["joinDate"] as? Timestamp
        else { return nil }
        
        self.id = id
        self.meetingID = meetingID
        self.joinDate = joinDate.dateValue()
        self.isHost = data["isHost"] as? Bool ?? false
    }
    
    // Firestore에 저장할 필드
    var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "meetingID": meetingID,
            "joinDate": FieldValue.serverTimestamp()
        ]
        
        // isHost가 true일 때만 Firestore에 저장
        if isHost {
            data["isHost"] = isHost
        }
        
        return data
    }

    struct func createMeeting(_ meetingID: String) -> MeetingList {
        return MeetingList(meetingID: meetingID, isHost = true)
    }
    /*
    // member가 가입
    static func member(_ meetingID: String) -> [String: Any] {
        return [
            "meetingID": meetingID,
            "joinDate": FieldValue.serverTimestamp()
        ]
    }
    
    // 모임 새로 만들어서 host가 가입시
    static func host(_ meetingID: String) -> [String: Any] {
        return [
            "meetingID": meetingID,
            "joinDate": FieldValue.serverTimestamp(),
            "isHost" : true
        ]
    }
     */
}
