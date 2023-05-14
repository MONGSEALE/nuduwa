//
//  Meeting.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/03/31.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestoreSwift
import Foundation
import CoreLocation
import GeoFireUtils

struct Meeting : Identifiable, Codable, Equatable, Hashable, FirestoreConvertible{
    @DocumentID var id: String?
    
    var title: String
    var description: String
    var place : String
    var numbersOfMembers : Int
  
    let location: CLLocationCoordinate2D
    var geoHash: String?
    
    var publishedDate: Timestamp
    var meetingDate: Date
    
    let hostUID: String

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
    
        self.location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
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
        
            "latitude" : location.latitude,
            "longitude" : location.longitude,
            "geoHash": geoHash,
            
            "publishedDate": FieldValue.serverTimestamp(),
            "meetingDate": meetingDate,
            
            //nil이면 오류나게 수정!!
            "hostUID": Auth.auth().currentUser?.uid
        ]
    }

    // 모임 만들기로 지도 클릭시 생성되는 Meeting구조체
    static func createMapAnnotation(location: CLLocationCoordinate2D) -> Meeting {
        var title: String = ""
        var description: String = ""
        var place : String = ""
        var numbersOfMembers : Int = 0
    
        let location = location
        var geoHash: String? = nil
        
        var publishedDate: Timestamp = Timestamp(date: Date())
        var meetingDate: Date = Date()
        
        var hostUID: String = ""

        var type: MeetingType = .new

        return Meeting(title: title, description: description, place: place, numbersOfMembers: numbersOfMembers, location: location, geoHash: geoHash, publishedDate: publishedDate, meetingDate: meetingDate, hostUID: hostUID, type: type)
    } 

    // 새로운 모임 만들기
    static func createNewMeeting(title: String, description: String, place: String, numbersOfMembers: Int, location: CLLocationCoordinate2D, meetingDate: Date) -> Meeting {
        var title: String = title
        var description: String = description
        var place : String = place
        var numbersOfMembers : Int = numbersOfMembers
    
        let location = location
        var geoHash: String? = GFUtils.geoHash(forLocation: location)
        
        var publishedDate: Timestamp = Timestamp(date: Date())
        var meetingDate: Date = meetingDate
        
        var hostUID: String = ""

        var type: MeetingType = .new

        return Meeting(title: title, description: description, place: place, numbersOfMembers: numbersOfMembers, location: location, geoHash: geoHash, publishedDate: publishedDate, meetingDate: meetingDate, hostUID: hostUID, type: type)
    } 

    // 모임 수정용 Meeting구조체
    static func updateMeeting(title: String = "", description: String = "", place: String = "", numbersOfMembers: Int = 0, meetingDate: Date = Date(timeIntervalSince1970:0)) -> Meeting {

        var title: String = title
        var description: String = description
        var place : String = place
        var numbersOfMembers : Int = numbersOfMembers
    
        let location = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        var geoHash: String? = nil
        
        var publishedDate: Timestamp = Timestamp(date: Date())
        var meetingDate: Date = meetingDate 
        
        var hostUID: String = " "

        var type: MeetingType = .basic

        return Meeting(title: title, description: description, place: place, numbersOfMembers: numbersOfMembers, location: location, geoHash: geoHash, publishedDate: publishedDate, meetingDate: meetingDate, hostUID: hostUID, type: type)
    }
    var firestoreUpdate: [String: Any] {
        var data: [String: Any] = []
        
        // 바뀐값만 Firestore에 Update
        if title != "" {
            data["title"] = title
        }
        if description != "" {
            data["description"] = description
        }
        if place != "" {
            data["place"] = place
        }
        if numbersOfMembers != 0 {
            data["numbersOfMembers"] = numbersOfMembers
        }
        if meetingDate != Date(timeIntervalSince1970:0) {
            data["meetingDate"] = meetingDate
        }

        return data
    }
}
