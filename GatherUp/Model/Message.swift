//
//  ChatMessage.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/04/11.
//

import SwiftUI
import FirebaseFirestoreSwift

struct Message: Identifiable, Equatable, Hashable, FirestoreConvertible{
    @DocumentID var id: String?
    
    let content: String
    let senderUID: String
    let timestamp: Timestamp
    var isSystemMessage: Bool

    // system 메시지
    static func systemMessage(_ content: String) -> [String: Any] {
        return [
            "content": content,
            "senderUID": "SYSTEM",
            "timestamp" : FieldValue.serverTimestamp(),
            "isSystemMessage": true
        ]
    } 

    // Firestore에서 가져올 필드 - guard문 값이 하나라도 없으면 nil 반환
    init?(data: [String: Any]) {
        guard let id = data["id"] as? String,
              let content = data["content"] as? String,
              let senderUID = data["senderUID"] as? String,
              let timestamp = data["timestamp"] as? Timestamp
        else { return nil }
        
        self.id = id
        self.content = content
        self.senderUID = senderUID
        self.timestamp = timestamp
        self.isSystemMessage = data["isSystemMessage"] as? Bool ?? false
    }
    
    // Firestore에 저장할 필드
    var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "content": content,
            "senderUID": senderUID,
            "timestamp" : FieldValue.serverTimestamp()
        ]
        
        // isSystemMessage true일 때만 Firestore에 저장
        if isSystemMessage == true {
            data["isSystemMessage"] = isSystemMessage
        }
        
        return data
    }
}

