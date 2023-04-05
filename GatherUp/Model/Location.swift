//
//  Location.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/03/26.
//

import Foundation
import FirebaseFirestoreSwift

struct Location : Identifiable,Codable,Equatable{
    
    @DocumentID var id: String?
//    var name:String
//    var description:String
    var latitude:Double
    var longitude:Double
    var publishedDate: Date = Date()
    
    var userUID: String?
}





