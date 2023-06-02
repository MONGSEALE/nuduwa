//
//  Block.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/06/02.
//

import SwiftUI
import Firebase
import FirebaseFirestoreSwift

struct Block: Identifiable, Equatable, Hashable, FirestoreConvertible{
    @DocumentID var id: String?
    
    let blockUID: String
    let timestamp: Timestamp

    init(_ blockUID: String) {
        self.id = UUID().uuidString
        self.blockUID = blockUID
        self.timestamp = Timestamp(date: Date())
    }

    // Firestore에서 가져올 필드 - guard문 값이 하나라도 없으면 nil 반환
    init?(data: [String: Any], id: String) {
        guard let blockUID = data["blockUID"] as? String,
              let timestamp = data["timestamp"] as? Timestamp
        else { return nil }
        
        self.id = id
        self.blockUID = blockUID
        self.timestamp = timestamp
    }
    
    // Firestore에 저장할 필드
    var firestoreData: [String: Any] {
        return [
            "blockUID": blockUID,
            "timestamp" : FieldValue.serverTimestamp()
        ]
    }
    
}
