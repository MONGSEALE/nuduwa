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
    @DocumentID let id: String

    var userName: String
    var userEmail: String?
    var userImage: URL?
    let userGoogleData: UserProviderData?

    var signUpDate: Timestamp
    
    struct UserProviderData: Codable {
        let uid: String?
        let name: String?
        let email: String?
        let image: URL?
    }

    init(id: String?=nil. userName: String, userEmail: String? = nil, userGoogleUID: String? = nil, userGoogleName: String? = nil, userGoogleEmail: String? = nil, userGoogleImage: URL? = nil, userImage: URL? = nil){
        self.id = id ?? UUID().uuidString
        self.userName = userName
        self.userEmail = userEmail
        self.userGoogleData.uid = userGoogleUID
        self.userGoogleData.name = userGoogleName
        self.userGoogleData.email = userGoogleEmail
        self.userGoogleData.image = userGoogleImage
        self.userImage = userImage
    }

    // Firestore에서 가져올 필드 - guard문 값이 하나라도 없으면 nil 반환
    init?(data: [String: Any], id: String) {
        guard let userName = data["userName"] as? String,
            let signUpDate = data["signUpDate"] as? Timestamp
        else {return nil }
        
        self.id = id
        self.userName = userName
        self.userEmail = data["userEmail"] as? String? ?? nil
        let userImage = data["userImage"] as? String? ?? nil
        if let userImage {
            self.userImage = URL(string: userImage)
        } else {
            self.userImage = nil
        }

        let userGoogleData = data["userGoogleData"] as? UserProviderData? ?? nil
        if let data = userGoogleData {
            self.userGoogleData = UserProviderData(uid: data.uid?, name: data.name?, email: data.email?, image: data.image?)
        } else {
            self.userGoogleData = nil
        }   

        self.signUpDate = signUpDate
    }
    
    // Firestore에 저장할 필드
    var firestoreDataGoogleUser: [String: Any] {
        guard let userName = userName else{return [:]}
        var data: [String: Any] = [
            "userName": userName,
            "signUpDate": FieldValue.serverTimestamp()
        ]
        
        // 값이 있을때만 Firestore에 저장
        if let data = userGoogleData {
            data["userGoogleData"] = userGoogleData
            data["userEmail"] = userGoogleData.email
            data["userImage"] = userGoogleData.image.absoluteString
        }
        // if let userGoogleEmail = userGoogleEmail {
        //     data["userEmail"] = userGoogleEmail
        //     data["userGoogleEmail"] = userGoogleEmail
        // }
        // if let userImage = userImage {
        //     data["userImage"] = userImage.absoluteString
        // }
        
        return data
    }
    
    static func convertUserData(_ userData: UserData) -> User {
        return User(id: userData.id, userName: userData.userName, userImage: userData.userImage)
    }
    
    // static func newGoogleUser(userName: String?, userGoogleUID: String?, userGoogleEmail: String?, userImage: URL?) -> [String: Any] {
    //     return [
    //         "userName": userName as Any,
    //         "userEmail": userGoogleEmail as Any,
    //         "userGoogleUID": userGoogleUID as Any,
    //         "userGoogleEmail": userGoogleEmail as Any,
    //         "userImage": userImage?.absoluteString as Any,
    //         "signUpDate": FieldValue.serverTimestamp()
    //     ]
    // }
    
    // system 메시지
//    static func systemMessage(_ text: String) -> [String: Any] {
//        return [
//            "text": text,
//            "senderUID": "SYSTEM",
//            "timestamp" : FieldValue.serverTimestamp(),
//            "isSystemMessage": true
//        ]
//    }

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
    @DocumentID var id: String

    var userName: String
    var userImage: URL?

    // Firestore에서 가져올 필드 - guard문 값이 하나라도 없으면 nil 반환
    init?(data: [String: Any]) {
        guard let id = data["id"] as? String,
              let userName = data["userName"] as? String
        else { return nil }
        
        self.id = id
        self.userName = userName
        let userImage = data["userImage"] as? String? ?? nil
        if let userImage {
            self.userImage = URL(string: userImage)
        }

    }
}
