//
//  Location.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/03/26.
//

import Foundation


struct Location : Identifiable,Codable,Equatable{
    let id:UUID
    var name:String
    var description:String
    var latitude:Double
    var longitude:Double
}





