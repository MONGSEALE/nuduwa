//
//  Meeting.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/03/31.
//

import SwiftUI
import FirebaseFirestoreSwift

import Foundation

struct Meeting : Identifiable,Codable,Equatable{
    @DocumentID var id: String?
    var text: String
    var publishedDate: Date = Date()
    // MARK: Basic User Info
    var userName: String
    var userUID: String
    var userImage: URL

}
