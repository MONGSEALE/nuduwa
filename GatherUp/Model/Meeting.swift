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

struct Meeting : Identifiable,Codable,Equatable, Hashable, FirestoreConvertible{
    @DocumentID var id: String?
    
    var title: String
    var description: String
    var place : String
    var numbersOfMembers : Int
  
    let latitude : Double
    let longitude : Double
    var geoHash: String?
    
    var publishedDate: Date
    var meetingDate: Date
    
    var hostUID: String

    var type: MeetingType
    
    enum MeetingType: Codable {
        case basic
        case new
        case piled
    }

    // Firestore에서 가져올 필드 - guard문 값이 하나라도 없으면 nil 반환
    init?(data: [String: Any]) {
        guard let id = data["id"] as? String,
              let title = data["title"] as? String,
              let description = data["description"] as? String,
              let place = data["place"] as?  String,
              let numbersOfMembers = data["numbersOfMembers"] as? Int,

              let latitude = data["latitude"] as? Double,
              let longitude = data["longitude"] as? Double,
              let geoHash = data["geoHash"] as? String? ?? nil,
            
              let publishedDate = data["publishedDate"] as? Date,
              let meetingDate = data["meetingDate"] as? Date,

              let hostUID = data["hostUID"] as? String
        else { return nil }
        
        self.id = id
        self.title = title
        self.description = description
        self.place = place
        self.numbersOfMembers = numbersOfMembers
    
        self.latitude = latitude
        self.longitude = longitude
        self.geoHash = geoHash
        
        self.publishedDate = publishedDate
        self.meetingDate = meetingDate

        self.hostUID = hostUID
        
        self.type = .basic
    }
    
    // Firestore에 저장할 필드
    var firestoreData: [String: Any] {
        return [
            "title": title,
            "description": description,
            "place" : place,
            "numbersOfMembers" : numbersOfMembers,
        
            "latitude" : latitude,
            "longitude" : longitude,
            "geoHash": geoHash,
            
            "publishedDate": publishedDate,
            "meetingDate": meetingDate,
            
            "hostUID": hostUID
        ]
    }
}
