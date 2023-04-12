//
//  Location.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/03/26.
//

import Foundation
import FirebaseFirestoreSwift
import CoreLocation

struct Location : Identifiable{
    let id = UUID()
    //@DocumentID var id: String?
    let coordinate: CLLocationCoordinate2D
    var userImage: URL?
    
//
//    @DocumentID var id: String?
////    var name:String
////    var description:String
//    var latitude:Double
//    var longitude:Double
//    var publishedDate: Date = Date()
//
//    var userUID: String?
}





