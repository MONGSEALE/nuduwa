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
    let userEmail: String?
    let userGoogleIDCode: Int?
    let userGoogleEmail: String?
    var userImage: URL?

    var signUpDate: Timestamp?
    
    init(id: String? = nil, userName: String? = nil, userEmail: String? = nil, userGoogleIDCode: Int? = nil, userGoogleEmail: String? = nil, userImage: URL? = nil, signUpDate: Timestamp? = nil){
        self.id = id
        self.userName = userName
        self.userEmail = userEmail
        self.userGoogleIDCode = userGoogleIDCode
        self.userGoogleEmail = userGoogleEmail
        self.userImage = userImage
        self.signUpDate = signUpDate
    }

    // Firestore에서 가져올 필드 - guard문 값이 하나라도 없으면 nil 반환
    init?(data: [String: Any]) {
        guard let id = data["id"] as? String,
            let userName = data["userName"] as? String,
            let signUpDate = data["signUpDate"] as? Timestamp
        else { return nil }
        
        self.id = id
        self.userName = userName
        self.userEmail = data["userEmail"] as? String? ?? nil
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
            data["userEmail"] = userGoogleEmail
            data["userGoogleEmail"] = userGoogleEmail
        }
        if let userImage = userImage {
            data["userImage"] = userImage
        }
        
        return data
    }
    
    static func convertUserData(_ userData: UserData) -> User {
        return User(id: userData.id, userName: userData.userName, userImage: userData.userImage)
    }
    
    static func newGoogleUser(userName: String, userGoogleIDCode: String, userGoogleEmail: String, userImage: URL) -> [String: Any] {
        return [
            "userName": userName,
            "userEmail": userGoogleEmail,
            "userGoogleIDCode": userGoogleIDCode,
            "userGoogleEmail": userGoogleEmail,
            "userImage": userImage,
            "signUpDate": FieldValue.serverTimestamp()
        
        ]
    }
    
    // system 메시지
    static func systemMessage(_ text: String) -> [String: Any] {
        return [
            "text": text,
            "senderUID": "SYSTEM",
            "timestamp" : FieldValue.serverTimestamp(),
            "isSystemMessage": true
        ]
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
