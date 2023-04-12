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
    let latitude : Double
    let longitude : Double
    
    var publishedDate: Date = Date()
    var meetingDate: Date = Date()
    
    var members: [String]
    var numbersOfMembers: Int
    /*
     참가비
     */
    // MARK: Basic User Info
    var hostName: String
    var hostUID: String
    var hostImage: URL?

}
