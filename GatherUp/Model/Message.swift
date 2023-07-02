//
//  ChatMessage.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/04/11.
//

import SwiftUI
import Firebase
import FirebaseFirestoreSwift

struct Message: Identifiable, Equatable, Hashable, FirestoreConvertible{
    @DocumentID var id: String?
    
    let text: String
    let senderUID: String
    let timestamp: Timestamp
    var isSystemMessage: Bool
    var imageUrl: String?
  

    init(_ text: String, uid: String, imageUrl: String? = nil, isSystemMessage: Bool? = nil) {
          self.id = UUID().uuidString
          self.text = text
          self.senderUID = uid
          self.timestamp = Timestamp(date: Date())
          self.imageUrl = imageUrl
          self.isSystemMessage = isSystemMessage ?? false
      }

    // Firestore에서 가져올 필드 - guard문 값이 하나라도 없으면 nil 반환
    init?(data: [String: Any], id: String) {
            guard let text = data["text"] as? String,
                  let senderUID = data["senderUID"] as? String,
                  let timestamp = data["timestamp"] as? Timestamp
            else { return nil }
            
            self.id = id
            self.text = text
            self.senderUID = senderUID
            self.timestamp = timestamp
            self.isSystemMessage = data["isSystemMessage"] as? Bool ?? false
            self.imageUrl = data["imageUrl"] as? String  // 이미지 URL 필드 추가
        }
    
    // Firestore에 저장할 필드
    var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "text": text,
            "senderUID": senderUID,
            "timestamp" : FieldValue.serverTimestamp(),
            "imageUrl": imageUrl ?? ""
        ]
        
        // isSystemMessage true일 때만 Firestore에 저장
        if isSystemMessage == true {
            data["isSystemMessage"] = isSystemMessage
            data["senderUID"] = "SYSTEM"
        }
        return data
    }

    // system 메시지
    static func createSystemMessage(_ text: String) -> Message {
        let uid = "SYSTEM"
        let isSystemMessage = true
        return Message(text, uid: uid, isSystemMessage: isSystemMessage)
    }
    /*
    static func systemMessage(_ text: String) -> [String: Any] {
        return [
            "text": text,
            "senderUID": "SYSTEM",
            "timestamp" : FieldValue.serverTimestamp(),
            "isSystemMessage": true
        ]
    }
 */
}
