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
    @DocumentID var id: String
    
    var title: String
    var description: String
    var place : String
    var numbersOfMembers : Int
  
    let private latitude: Double
    let private longitude: Double
    
    var geoHash: String?
    
    var publishedDate: Date
    var meetingDate: Date
    
    let hostUID: String
    var hostName: String?
    var hostImage: URL?

    var type: MeetingType   // 지도에서 겹치는 큰 아이콘 생성용 겸 새로운 모임 분별
    var category: Category?  // 모임 구분
    
    enum MeetingType: Codable {
        case basic
        case new
        case piled
    }
    enum Category: String, Codable, CaseIterable {
        case exercise   // 운동
        case meal       // 밥
        case alcohol    // 술
        case study      // 공부
        case trip       // 여행
        case play       // 놀이
        case volunteer  // 자원봉사
    }

    // CLLocationCoordinate2D타입으로 location 가져오기
    var location: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // 기본 생성자
    init(title: String, description: String, place : String, numbersOfMembers : Int, location: CLLocationCoordinate2D, meetingDate: Date, hostUID: String, type: MeetingType? = nil, category: Category? = nil) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.place = place
        self.numbersOfMembers = numbersOfMembers
    
        self.latitude = location.latitude
        self.longitude = location.longitude
        self.geoHash = nil
        
        self.publishedDate = Date()
        self.meetingDate = meetingDate

        self.hostUID = hostUID
        self.hostName = hostName
        self.hostImage = hostImage
        
        self.type = type ?? .basic
        self.category = category
    }

    // Firestore에서 가져올 필드 - guard문 값이 하나라도 없으면 nil 반환
    init?(data: [String: Any], id: String) {
        guard let title = data["title"] as? String,
              let description = data["description"] as? String,
              let place = data["place"] as?  String,
              let numbersOfMembers = data["numbersOfMembers"] as? Int,

              let latitude = data["latitude"] as? Double,
              let longitude = data["longitude"] as? Double,
            
              let publishedDate = data["publishedDate"] as? Timestamp,
              let meetingDate = data["meetingDate"] as? Timestamp,

              let hostUID = data["hostUID"] as? String
        else { print("오류!아이디:\(id)");return nil }

        let geoHash = data["geoHash"] as? String? ?? nil
        let category = data["category"] as? String? ?? nil
        
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
        self.hostName = nil
        self.hostImage = nil

        self.type = .basic
        self.type = category
    }
    
    // Firestore에 저장할 필드
    var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "title": title,
            "description": description,
            "place" : place,
            "numbersOfMembers" : numbersOfMembers,
        
            "latitude" : latitude,
            "longitude" : longitude,
            "geoHash": GFUtils.geoHash(forLocation: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)),
            
            "publishedDate": FieldValue.serverTimestamp(),
            "meetingDate": meetingDate,
            
            "hostUID": hostUID
        ]
        if let category {
            data["category"] = category
        }
        return data
    }
    

    // 모임 만들기로 지도 클릭시 생성되는 Meeting구조체
    static func createMapAnnotation(_ location: CLLocationCoordinate2D) -> Meeting {
        let title: String = ""
        let description: String = ""
        let place : String = ""
        let numbersOfMembers : Int = 0
    
        let location = location
        
        let meetingDate: Date = Date()

        let type: MeetingType = .new

        return Meeting(title: title, description: description, place: place, numbersOfMembers: numbersOfMembers, location: location, meetingDate: meetingDate, type: type)
    }
    // 모임 위치가 겹쳤을 경우 MapAnnotation용 구조체
    // static func piledMapAnnotation(id: String, location: CLLocationCoordinate2D, geoHash: String?) -> Meeting {
    //     let id = id
    //     let title: String = ""
    //     let description: String = ""
    //     let place : String = ""
    //     let numbersOfMembers : Int = 0
    
    //     let location: CLLocationCoordinate2D = location
    //     let geoHash: String? = geoHash
        
    //     let publishedDate: Date = Date()
    //     let meetingDate: Date = Date()

    //     let type: MeetingType = .piled

    //     return Meeting(id: id, title: title, description: description, place: place, numbersOfMembers: numbersOfMembers, location: location, geoHash: geoHash, publishedDate: publishedDate, meetingDate: meetingDate, type: type)
    // }
    static func piledMapAnnotation(meeting: Meeting) -> Meeting {
        meeting.type = .piled

        return meeting
    }

    // 새로운 모임 만들기
    static func createNewMeeting(title: String, description: String, place: String, numbersOfMembers: Int, location: CLLocationCoordinate2D, meetingDate: Date, category: Category? = nil) -> Meeting {
        let title: String = title
        let description: String = description
        let place : String = place
        let numbersOfMembers : Int = numbersOfMembers
    
        let location = location
        
        let meetingDate: Date = meetingDate

        let type: MeetingType = .new
        let category: Category? = category

        return Meeting(title: title, description: description, place: place, numbersOfMembers: numbersOfMembers, location: location, meetingDate: meetingDate, type: type, category: category)
    } 

    // 모임 수정용 Meeting구조체
    static func updateMeeting(title: String = "", description: String = "", place: String = "", numbersOfMembers: Int = 0, meetingDate: Date = Date(timeIntervalSince1970:0), category: Category? = nil) -> Meeting {

        let title: String = title
        let description: String = description
        let place : String = place
        let numbersOfMembers : Int = numbersOfMembers
    
        let location = CLLocationCoordinate2D(latitude: 0, longitude: 0)

        let meetingDate: Date = meetingDate
        
        let hostUID: String = " "

        let type: MeetingType = .basic
        let category: Category = category

        return Meeting(title: title, description: description, place: place, numbersOfMembers: numbersOfMembers, location: location, meetingDate: meetingDate, hostUID: hostUID, type: type)
    }
    // 수정 모임 firestore에 업데이트
    var firestoreUpdate: [String: Any] {
        var data: [String: Any] = [:]
        
        // 바뀐값만 Firestore에 Update
        if !title.isEmpty {
            data["title"] = title
        }
        if !description.isEmpty {
            data["description"] = description
        }
        if !place.isEmpty {
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
    // 수정 모임 업데이트 - 객체 안만들고 Firestore 바로 저장하기
    // static func firestoreUpdateMeeting(title: String? = nil, description: String? = nil, place: String? = nil, numbersOfMembers: Int? = nil, meetingDate: Date? = nil) -> [String: Any] {
    //     var data: [String: Any] = [:]

    //     if let title {
    //         data["title"] = title
    //     }
    //     if let description {
    //         data["description"] = description
    //     }
    //     if let place {
    //         data["place"] = place
    //     }
    //     if let numbersOfMembers {
    //         data["numbersOfMembers"] = numbersOfMembers
    //     }
    //     if let meetingDate {
    //         data["meetingDate"] = meetingDate
    //     }

    //     return data
    // }

    // var firestoreCancle: [String: Any] {
    //     return [
    //         "geoHash": geoHash as Any
    //     ]
    // }
}
