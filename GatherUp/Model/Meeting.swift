//
//  Meeting.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/03/31.
//

import SwiftUI
import FirebaseFirestoreSwift
import Foundation
import CoreLocation

struct Meeting : Identifiable,Codable,Equatable{
    @DocumentID var id: String?
    
    var title: String
    var description: String
    let latitude : Double
    let longitude : Double
    
    
    var publishedDate: Date = Date()
    var meetingDate: Date = Date()
    /*
     모임시간
     모임참가비
     참가인원 []
     최대인원수
     */
    // MARK: Basic User Info
    var userName: String
    var userUID: String
    var userImage: URL?

}
