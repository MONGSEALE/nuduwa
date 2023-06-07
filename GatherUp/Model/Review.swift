//
//  Review.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/06/05.
//

import SwiftUI
import Firebase
import FirebaseFirestoreSwift

struct Review: Identifiable, Equatable, Hashable, FirestoreConvertible{
    @DocumentID var id: String?
    
    let meetingID: String
    let memberUID: String
    var memberName: String?
    var memberImage: URL?
    let reviewText: String
    let rating: Int
    let timestamp: Date

    init(meetingID: String, memberUID: String, reviewText: String, rating: Int) {
        self.id = UUID().uuidString
        self.meetingID = meetingID
        self.memberUID = memberUID
        self.memberName = nil
        self.memberImage = nil
        self.reviewText = reviewText
        self.rating = rating
        self.timestamp = Date()
    }

    // Firestore에서 가져올 필드 - guard문 값이 하나라도 없으면 nil 반환
    init?(data: [String: Any], id: String) {
        guard let meetingID = data["meetingID"] as? String,
              let memberUID = data["memberUID"] as? String,
              let reviewText = data["reviewText"] as? String,
              let rating = data["rating"] as? Int,
              let timestamp = data["timestamp"] as? Timestamp
        else { return nil }
        
        self.id = id
        self.meetingID = meetingID
        self.memberUID = memberUID
        self.memberName = nil
        self.memberImage = nil
        self.reviewText = reviewText
        self.rating = rating
        self.timestamp = timestamp.dateValue()
    }
    
    // Firestore에 저장할 필드
    var firestoreData: [String: Any] {
        return [
            "meetingID": meetingID,
            "memberUID": memberUID,
            "reviewText": reviewText,
            "rating": rating,
            "timestamp" : FieldValue.serverTimestamp()
        ]
    }
    
}
