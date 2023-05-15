//
//  User.swift
//  Nudowa
//
//  Created by DaelimCI00007 on 2023/03/27.
//

import SwiftUI
import Firebase
import FirebaseFirestoreSwift

struct User: Identifiable, Codable, FirestoreConvertible {
    @DocumentID var id: String?

    var userName: String?
    let userGoogleIDCode: Int?
    let userGoogleEmail: String?
    var userImage: URL?

    var signUpDate: Timestamp?

    // Firestore에서 가져올 필드 - guard문 값이 하나라도 없으면 nil 반환
    init?(data: [String: Any]) {
        guard let id = data["id"] as? String,
            let userName = data["userName"] as? String,
            let signUpDate = data["signUpDate"] as? Timestamp
        else { return nil }
        
        self.id = id
        self.userName = userName
        self.userGoogleIDCode = data["userGoogleIDCode"] as? Int? ?? nil
        self.userGoogleEmail = data["userGoogleEmail"] as? String? ?? nil
        self.userImage = data["userImage"] as? URL? ?? nil

        self.signUpDate = signUpDate
    }
    
    // Firestore에 저장할 필드
    var firestoreData: [String: Any] {
        guard let userName = userName else{return [:]}
        var data: [String: Any] = [
            "userName": userName,
            "signUpDate": FieldValue.serverTimestamp()
        ]
        
        // 값이 있을때만 Firestore에 저장
        if let userGoogleIDCode = userGoogleIDCode {
            data["userGoogleIDCode"] = userGoogleIDCode
        }
        if let userGoogleEmail = userGoogleEmail {
            data["userGoogleEmail"] = userGoogleEmail
        }
        if let userImage = userImage {
            data["userImage"] = userImage
        }
        
        return data
    }
    
    mutating func convertUserData(_ userData: UserData) {
        self.id = userData.id
        self.userName = userData.userName
        self.userImage = userData.userImage
    }

    /*
    enum CodingKeys: CodingKey {
        case id
        case username
        case userUID
        case userSnsID
        case userEmail
        case userImage
    }
     */
}

struct UserData: Identifiable, Codable {
    @DocumentID var id: String?

    var userName: String
    var userImage: URL?

    // Firestore에서 가져올 필드 - guard문 값이 하나라도 없으면 nil 반환
    init?(data: [String: Any]) {
        guard let id = data["id"] as? String,
              let userName = data["userName"] as? String
        else { return nil }
        
        self.id = id
        self.userName = userName
        self.userImage = data["userImage"] as? URL? ?? nil
    }
}
