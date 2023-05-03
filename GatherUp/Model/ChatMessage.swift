//
//  ChatMessage.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/04/11.
//

import SwiftUI
import Firebase
import FirebaseFirestoreSwift

struct ChatMessage: Identifiable, Equatable, Hashable{
    @DocumentID var id: String?
    
    let text: String
    let userUID: String
    let userName: String
    let timestamp: Timestamp
    var isSystemMessage: Bool
}

