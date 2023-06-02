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
    let receiverUID: String             // 상대방 UID
    let dmPeopleRef: DocumentReference  // Firestore 경로 데이터 타입
    var unreadMessages: Int             // 안읽은 메시지 수 - DM방 나갈시 삭제
    let latestMessage: Date             // 마지막 메시지 시간 - DM방 나갈시 삭제

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
    
    // Firestore에 저장할 필드 - DMList애서는 안보이고 서버에만 일단 저장
    var firestoreData: [String: Any] {
        return [
            "receiverUID": receiverUID,
            "dmPeopleRef": dmPeopleRef
        ]
    }

    // 새로운 메시지 생성 될 때 - DMList에서 나타남
    static var firestoreUpdate: [String: Any] {
        return [
            "unreadMessages": FieldValue.increment(Int64(1)),
            "latestMessage": FieldValue.serverTimestamp()
        ]
    }
    // DM방 들어갔을 때 unreadMessages = 0
    static var readDM: [String: Any] {
        return [
            "unreadMessages": 0
        ]
    }
    // DM방 나갈 때, unreadMessages와 latestMessage 삭제 - DMList에서 안보임
    static var disAppear: [String: Any] {
        return [
            "unreadMessages": FieldValue.delete(),
            "latestMessage": FieldValue.delete()
        ]
    }
    
}
