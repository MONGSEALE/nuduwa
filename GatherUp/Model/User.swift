//
//  User.swift
//  Nudowa
//
//  Created by DaelimCI00007 on 2023/03/27.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestoreSwift

import AuthenticationServices

struct User: Identifiable, Codable, FirestoreConvertible {
    @DocumentID var id: String?

    var userName: String
    var userEmail: String?
    var userImage: URL?
    var userGoogleData: UserProviderData?

    var signUpDate: Timestamp
    
    init(id: String? = nil, userName: String, userEmail: String? = nil, userImage: URL? = nil, userGoogleData: UserProviderData? = nil){
        self.id = id ?? UUID().uuidString
        self.userName = userName
        self.userEmail = userEmail
        self.userGoogleData = userGoogleData
        self.userImage = userImage
        self.signUpDate = Timestamp(date: Date())
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
        self.userImage = userImage!=nil ? URL(string: userImage) : nil
        self.userGoogleData = nil

        self.signUpDate = signUpDate
    }
    static func getAllData(data: [String: Any], id: String) -> User? {
        guard let userName = data["userName"] as? String,
            let signUpDate = data["signUpDate"] as? Timestamp
        else {return nil }
        
        let userEmail = data["userEmail"] as? String? ?? nil
        let userImageData = data["userImage"] as? String? ?? nil
        let userImage = userImageData!=nil ? URL(string: userImageData) : nil

        let userGoogleData = data["userGoogleData"] as? UserProviderData? ?? nil

        return User(id: id, userName: userName, userEmail: userEmail, userImage: userImage, userGoogleData: userGoogleData)
    }
    static func getUserNameImage(data: [String: Any], id: String) -> User {
        guard let userName = data["userName"] as? String
        else {return nil }
        
        let userEmail = data["userEmail"] as? String? ?? nil
        let userImageData = data["userImage"] as? String? ?? nil
        let userImage = userImageData!=nil ? URL(string: userImageData) : nil

        return User(id: id, userName: userName, userImage: userImage)
    }
    
    var firestoreData: [String : Any] {
        return firestoreDataGoogleUser
    }
    // Firestore에 저장할 필드
    var firestoreDataGoogleUser: [String: Any] {
//        guard let userName = userName else{return [:]}
        var data: [String: Any] = [
            "userName": userName,
            "signUpDate": FieldValue.serverTimestamp()
        ]
        
        // 값이 있을때만 Firestore에 저장
        if let userEmail = userEmail {
            data["userEmail"] = userEmail
        }
        if let userImage = userImage {
            data["userImage"] = userImage.absoluteString
        }
        if let googleData = userGoogleData {
            data["userGoogleData"] = [ "googleUID": googleData.uid, "name": googleData.name, "email": googleData.email, "image": googleData.image?.absoluteString ]
        }
        
        return data
    }
    
     static func newGoogleUser(userGoogleData: UserProviderData) -> User {
         let name = userGoogleData.name ?? ""
         let email = userGoogleData.email
         let image = userGoogleData.image
         
         return User(userName: name, userEmail: email, userImage: image, userGoogleData: userGoogleData)
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
struct UserProviderData: Codable {
    var uid: String?
    var name: String?
    var email: String?
    var image: URL?
}

// struct UserData: Identifiable, Codable {
//     @DocumentID var id: String?

//     var userName: String
//     var userImage: URL?

//     // Firestore에서 가져올 필드 - guard문 값이 하나라도 없으면 nil 반환
//     init?(data: [String: Any]) {
//         guard let id = data["id"] as? String,
//               let userName = data["userName"] as? String
//         else { return nil }
        
//         self.id = id
//         self.userName = userName
//         let userImage = data["userImage"] as? String? ?? nil
//         if let userImage {
//             self.userImage = URL(string: userImage)
//         }

//     }
// }
