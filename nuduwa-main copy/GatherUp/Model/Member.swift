//
//  Members.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/04/17.
//

import SwiftUI
import FirebaseFirestoreSwift

struct Member: Identifiable,Codable,Equatable, Hashable{
    @DocumentID var id: String?
    
    let memberUID: String
    var memberName: String?
    var memberImage: URL?
    var joinDate: Date = Date()
}



