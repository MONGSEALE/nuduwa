//
//  DMPeople.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/05/11.
//

import SwiftUI
import FirebaseFirestoreSwift

struct DMPeople: Identifiable, Codable, Equatable, FirestoreConvertible {
    @DocumentID var id: String?
    
    var chattersUID: [String]

    // 기본 생성자
    init(chattersUID: [String]) {
        self.id = UUID().uuidString
        self.chattersUID = chattersUID
    }
    // Firestore에서 가져올 필드 - guard문 값이 하나라도 없으면 nil 반환
    init?(data: [String: Any], id: String) {
        guard let chattersUID = data["chattersUID"] as? [String] else { return nil }
        
        self.id = id
        self.chattersUID = chattersUID
    }
    
    // Firestore에 저장할 필드
    var firestoreData: [String: Any] {
        return [
            "chattersUID": chattersUID
        ]
    }
}
