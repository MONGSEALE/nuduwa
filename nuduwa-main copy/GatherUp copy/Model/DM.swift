//
//  DM.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/05/11.
//

import SwiftUI
import FirebaseFirestoreSwift
import FirebaseFirestore

struct DM: Identifiable, Codable ,Equatable{
    @DocumentID var id: String?
    let senderID: String
    let receiverID: String
    let message: String
    let timestamp: Timestamp
}


