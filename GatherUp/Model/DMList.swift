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
    let receiverUID: String
    // let DMPeopleID: String
    let dmPeopleRef: DocumentReference
    var unreadMessages: Int
    let latestMessage: Date
    // let latestReadTime: Date

    // 기본 생성자
    init(receiverUID: String, dmPeopleRef: DocumentReference) {
        self.id = UUID().uuidString
        self.receiverUID = receiverUID
        self.dmPeopleRef = dmPeopleRef
        self.unreadMessages = 0
        self.latestMessage = Date()
    }
    // Firestore에서 가져올 필드 - guard문 값이 하나라도 없으면 nil 반환
    init?(data: [String: Any], id: String) {
        guard let receiverUID = data["receiverUID"] as? String,
              let dmPeopleRef = data["dmPeopleRef"] as? DocumentReference,
              let unreadMessages = data["unreadMessages"] as? Int,
              let latestMessage = data["latestMessage"] as? Timestamp
        else { return nil }
        
        self.id = id
        self.receiverUID = receiverUID
        self.dmPeopleRef = dmPeopleRef
        self.unreadMessages = unreadMessages
        self.latestMessage = latestMessage.dateValue()
    }
    
    // Firestore에 저장할 필드 - unreadMessages와 latestMessage는 채팅 치면 생성
    var firestoreData: [String: Any] {
        return [
            "receiverUID": receiverUID,
            "dmPeopleRef": dmPeopleRef
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
    static var readDM: [String: Any] {
        return [
            "unreadMessages": 0
        ]
    }
    
}
