//
//  Members.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/04/17.
//

import SwiftUI
import FirebaseFirestoreSwift

struct Members: Identifiable,Codable,Equatable, Hashable{
    @DocumentID var id: String?
    
    let memberId: String
    var memberName: String
    var memberImage: URL?
    var joinDate: Date = Date()
}



