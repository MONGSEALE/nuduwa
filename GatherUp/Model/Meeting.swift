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

struct Meeting : Identifiable,Codable,Equatable, Hashable{
    @DocumentID var id: String?
    
    var title: String
    var description: String
    var place : String
    var numbersOfMembers : Int
  
    let latitude : Double
    let longitude : Double
    var geoHash: String?
    
    var publishedDate: Date = Date()
    var meetingDate: Date = Date()
    /*
     참가비
     */
    // MARK: Basic User Info
    var hostName: String
    var hostUID: String
    var hostImage: URL?

    var type: MeetingType = .basic
    
    enum MeetingType: Codable {
        case basic
        case new
        case piled
    }
}
