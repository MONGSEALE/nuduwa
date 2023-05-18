//
//  Chatter.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/05/11.
//

import SwiftUI
import Firebase
import FirebaseFirestoreSwift

struct DMList : Identifiable, Codable, Equatable, FirestoreConvertible {
    @DocumentID var id: String?
    let chatterUID: String
    let DMPeopleID: String
    var unreadMessages: Int
    let latestMessage: Date
    // let latestReadTime: Date

    // 기본 생성자
    init(chatterUID: String, DMPeopleID: String) {
        self.id = UUID().uuidString
        self.chatterUID = chatterUID
        self.DMPeopleID = DMPeopleID
        self.latestMessage = Date()
    }
    // Firestore에서 가져올 필드 - guard문 값이 하나라도 없으면 nil 반환
    init?(data: [String: Any], id: String) {
        guard let chatterUID = data["chatterUID"] as? String,
              let DMPeopleID = data["DMPeopleID"] as? String,
              let latestMessage = data["latestMessage"] as? Timestamp
        else { return nil }
        
        self.id = id
        self.chatterUID = chatterUID
        self.DMPeopleID = DMPeopleID
        self.latestMessage = latestMessage.dateValue()
    }
    
    // Firestore에 저장할 필드 - unreadMessages와 latestMessage는 채팅 치면 생성
    var firestoreData: [String: Any] {
        return [
            "chatterUID": chatterUID,
            "DMPeopleID": DMPeopleID
        ]
    }

    // update Message
    static var firestoreUpdate: [String: Any] {
        return [
            "unreadMessages": FieldValue.increment(Int64(1)),
            "latestMessage": FieldValue.serverTimestamp()
        ]
    }
    // update unread
    static var enterDMRoom: [String: Any] {
        return [
            "unreadMessages": 0
        ]
    }
    
}
