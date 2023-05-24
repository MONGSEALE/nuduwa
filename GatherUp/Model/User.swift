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
    var introduction: String?
    var interests: [String]?
    var signUpDate: Timestamp
    
    init(id: String? = nil, userName: String, userEmail: String? = nil, userImage: URL? = nil, userGoogleData: UserProviderData? = nil){
        self.id = id ?? UUID().uuidString
        self.userName = userName
        self.userEmail = userEmail
        self.userGoogleData = userGoogleData
        self.userImage = userImage
        self.signUpDate = Timestamp(date: Date())
        self.introduction = nil
        self.interests = nil
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
            self.userGoogleData = UserProviderData(uid: data.uid, name: data.name, email: data.email, image: data.image)
        } else {
            self.userGoogleData = nil
        }
        
       self.introduction = data["introduction"] as? String ?? nil   // String이아니면 nil값을 반환함 ,만약 introduction이 nil값이 들어가면 안될때 끝에 ?? 를 붙임
       self.interests = data["interests"] as? [String] ?? nil   // 서버에서 가져온 타입이 String배열이 아닐때 nil 처리


        self.signUpDate = signUpDate
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
    
    static func firestoreUpdate(introduction:String?, interests:[String]?) -> [String:Any]{
        var data : [String:Any] = [:]
        if let introduction {
            data["introduction"] = introduction
        }
        if let interests {
            data["interests"] = interests
        }
        return data
    }
    
    
}
struct UserProviderData: Codable {
    var uid: String?
    var name: String?
    var email: String?
    var image: URL?
}
