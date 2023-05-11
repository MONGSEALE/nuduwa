//
//  User.swift
//  Nudowa
//
//  Created by DaelimCI00007 on 2023/05/12.
//

import SwiftUI
import FirebaseFirestoreSwift

struct JoinMeeting: Identifiable, Codable {
    @DocumentID var id: String?

    let meetingID: string
    var joinDate: Date = Date()
    let isHost: Bool?
}

