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
  
    let latitude: Double
    let longitude: Double
    
    var geoHash: String?
    
    var publishedDate: Date
    var meetingDate: Date
    
    var hostUID: String
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
        case exercise = "Exercise" // 운동
        case meal = "Meal" // 밥
        case alcohol = "Alcohol" // 술
        case study = "Study" // 공부
        case trip = "Trip" // 여행
        case play = "Play" // 놀이
        case volunteer = "Volunteer" // 자원봉사
    }


    // CLLocationCoordinate2D타입으로 location 가져오기
    var location: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // 기본 생성자
    init(title: String, description: String, place : String, numbersOfMembers : Int, location: CLLocationCoordinate2D, meetingDate: Date, hostUID: String = "", hostName: String? = nil, hostImage: URL? = nil, type: MeetingType? = nil, category: Category? = nil) {
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
        
        if let category {
            self.category = Category(rawValue: category)
        } else {
            self.category = nil
        }
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
            data["category"] = category.rawValue
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

    static func piledMapAnnotation(meeting: Meeting) -> Meeting {
        var meeting = meeting
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
    static func updateMeeting(title: String? = nil, description: String? = nil, place: String? = nil, numbersOfMembers: Int? = nil, meetingDate: Date? = nil, category: Category? = nil) -> Meeting {

        let title: String = title ?? ""
        let description: String = description ?? ""
        let place : String = place ?? ""
        let numbersOfMembers : Int = numbersOfMembers ?? 0
    
        let location = CLLocationCoordinate2D(latitude: 0, longitude: 0)

        let meetingDate: Date = meetingDate ?? Date(timeIntervalSince1970:0)
        
        let hostUID: String = " "

        let type: MeetingType = .basic
        let category: Category? = category

        return Meeting(title: title, description: description, place: place, numbersOfMembers: numbersOfMembers, location: location, meetingDate: meetingDate, hostUID: hostUID, type: type, category: category)
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
        if category != nil {
            data["category"] = category?.rawValue
        }

        return data
    }
    // 모임에 유저이름 이미지 넣기
    static func putHostData(meeting: Meeting, user: User) -> Meeting {
        var meeting = meeting
        meeting.hostName = user.userName
        meeting.hostImage = user.userImage

        return meeting
    }

    // 모임시간 지난 모임 업데이트 - 객체 안만들고 Firestore 바로 저장하기
    static func firestorePastMeeting() -> [String: Any] {
        return [
            "geoHast": nil
        ]
    }

    // var firestoreCancle: [String: Any] {
    //     return [
    //         "geoHash": geoHash as Any
    //     ]
    // }
}
