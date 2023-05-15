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
    let timestamp: Timestamp

    // Firestore에서 가져올 필드 - guard문 값이 하나라도 없으면 nil 반환
    init?(data: [String: Any]) {
        guard let id = data["id"] as? String,
              let chatterUID = data["chatterUID"] as? String,
              let DMPeopleID = data["DMPeopleID"] as? String,
              let timestamp = data["timestamp"] as? Timestamp
        else { return nil }
        
        self.id = id
        self.chatterUID = chatterUID
        self.DMPeopleID = DMPeopleID
        self.timestamp = timestamp
    }
    
    // Firestore에 저장할 필드
    var firestoreData: [String: Any] {
        return [
            "chatterUID": chatterUID,
            "DMPeopleID": DMPeopleID,
            "timestamp" : FieldValue.serverTimestamp()
        ]
    }
}
