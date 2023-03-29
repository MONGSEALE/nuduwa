//
//  Group.swift
//  Nudowa
//
//  Created by DaelimCI00007 on 2023/03/29.
//

import SwiftUI
import FirebaseFirestoreSwift

// MARK: Group Model
struct Group: Identifiable, Codable {
    @DocumentID var id: String?
    var text: String
    var publishedDate: Date = Date()
    // MARK: Basic User Info
    var userName: String
    var userUID: String
//    var userImage: URL
    
    enum CodingKeys: CodingKey {
        case id
        case text
        case publishedDate
        case userName
        case userUID
//        case userImage
    }
}
