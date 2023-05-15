//
//  Meeting.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/03/31.
//

import SwiftUI
import Firebase
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
  
    var latitude: Double
    var longitude: Double
    
    var geoHash: String?
    
    var publishedDate: Date
    var meetingDate: Date
    
    let hostUID: String

    var type: MeetingType
    
    enum MeetingType: String, Codable {
        case basic
        case new
        case piled
    }
    
    init(id: String? = nil, title: String, description: String, place : String, numbersOfMembers : Int, location: CLLocationCoordinate2D, geoHash: String? = nil, publishedDate: Date? = nil, meetingDate: Date, hostUID: String? = nil, type: MeetingType? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.place = place
        self.numbersOfMembers = numbersOfMembers
    
        self.latitude = location.latitude
        self.longitude = location.longitude
        self.geoHash = geoHash
        
        self.publishedDate = publishedDate ?? Date()
        self.meetingDate = meetingDate

        self.hostUID = hostUID ?? ""
        
        self.type = type ?? .basic
    }

    // Firestore에서 가져올 필드 - guard문 값이 하나라도 없으면 nil 반환
    init?(data: [String: Any], id: String) {
        guard let title = data["title"] as? String,
              let description = data["description"] as? String,
              let place = data["place"] as?  String,
              let numbersOfMembers = data["numbersOfMembers"] as? Int,

              let latitude = data["latitude"] as? Double,
              let longitude = data["longitude"] as? Double,
              let geoHash = data["geoHash"] as? String? ?? nil,
            
              let publishedDate = data["publishedDate"] as? Timestamp,
              let meetingDate = data["meetingDate"] as? Timestamp,

              let hostUID = data["hostUID"] as? String
        else { print("아이디:\(id)");return nil }
        
        self.id = id
        self.title = title
        self.description = description
        self.place = place
        self.numbersOfMembers = numbersOfMembers
    
        self.latitude = latitude
        self.longitude = longitude
        self.geoHash = geoHash
        
        self.publishedDate = publishedDate.dateValue()
        self.meetingDate = meetingDate.dateValue()

        self.hostUID = hostUID
        
        self.type = .basic
    }
    
    // Firestore에 저장할 필드
    var firestoreData: [String: Any] {
        guard let uid = Auth.auth().currentUser?.uid else{return [:]}
        return [
            "title": title,
            "description": description,
            "place" : place,
            "numbersOfMembers" : numbersOfMembers,
        
            "latitude" : latitude,
            "longitude" : longitude,
            "geoHash": GFUtils.geoHash(forLocation: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)),
            
            "publishedDate": FieldValue.serverTimestamp(),
            "meetingDate": meetingDate,
            
            //nil이면 오류나게 수정!!
            "hostUID": uid
        ]
    }
    
    var location: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    // 모임 만들기로 지도 클릭시 생성되는 Meeting구조체
    static func createMapAnnotation(_ location: CLLocationCoordinate2D) -> Meeting {
        let title: String = ""
        let description: String = ""
        let place : String = ""
        let numbersOfMembers : Int = 0
    
        let location = location
        let geoHash: String? = nil
        
        let publishedDate: Date = Date()
        let meetingDate: Date = Date()

        let type: MeetingType = .new

        return Meeting(title: title, description: description, place: place, numbersOfMembers: numbersOfMembers, location: location, geoHash: geoHash, publishedDate: publishedDate, meetingDate: meetingDate, type: type)
    }
    // 중첩 모임
    static func piled(id: String, location: CLLocationCoordinate2D, geoHash: String?) -> Meeting {
        let id = id
        let title: String = ""
        let description: String = ""
        let place : String = ""
        let numbersOfMembers : Int = 0
    
        let location: CLLocationCoordinate2D = location
        let geoHash: String? = geoHash
        
        let publishedDate: Date = Date()
        let meetingDate: Date = Date()

        let type: MeetingType = .piled

        return Meeting(id: id, title: title, description: description, place: place, numbersOfMembers: numbersOfMembers, location: location, geoHash: geoHash, publishedDate: publishedDate, meetingDate: meetingDate, type: type)
    }

    // 새로운 모임 만들기
    static func createNewMeeting(title: String, description: String, place: String, numbersOfMembers: Int, location: CLLocationCoordinate2D, meetingDate: Date) -> Meeting {
        let title: String = title
        let description: String = description
        let place : String = place
        let numbersOfMembers : Int = numbersOfMembers
    
        let location = location
        let geoHash: String? = GFUtils.geoHash(forLocation: location)
        
        let publishedDate: Date = Date()
        let meetingDate: Date = meetingDate

        let type: MeetingType = .new

        return Meeting(title: title, description: description, place: place, numbersOfMembers: numbersOfMembers, location: location, geoHash: geoHash, publishedDate: publishedDate, meetingDate: meetingDate, type: type)
    } 

    // 모임 수정용 Meeting구조체
    static func updateMeeting(title: String = "", description: String = "", place: String = "", numbersOfMembers: Int = 0, meetingDate: Date = Date(timeIntervalSince1970:0)) -> Meeting {

        let title: String = title
        let description: String = description
        let place : String = place
        let numbersOfMembers : Int = numbersOfMembers
    
        let location = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let geoHash: String? = nil
        
        let publishedDate: Date = Date()
        let meetingDate: Date = meetingDate
        
        let hostUID: String = " "

        let type: MeetingType = .basic

        return Meeting(title: title, description: description, place: place, numbersOfMembers: numbersOfMembers, location: location, geoHash: geoHash, publishedDate: publishedDate, meetingDate: meetingDate, hostUID: hostUID, type: type)
    }
    var firestoreUpdate: [String: Any] {
        var data: [String: Any] = [:]
        
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
