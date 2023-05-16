//
//  User.swift
//  Nudowa
//
//  Created by DaelimCI00007 on 2023/03/27.
//

import SwiftUI
import FirebaseFirestoreSwift

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var userName: String
    var userUID: String
    var userSNSID: String?
    var userEmail: String?
    var userImage: URL?
    
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

struct UserData {
    var userName: String
    var userImage: URL
}
