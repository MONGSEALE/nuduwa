//
//  Chatter.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/05/11.
//

import SwiftUI
import FirebaseFirestoreSwift

struct Chatter : Identifiable,Codable,Equatable {
    @DocumentID var id: String?
    
    var chatterUID : String
    var DMPeopleID : String
}

