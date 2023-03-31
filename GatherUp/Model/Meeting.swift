//
//  Meeting.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/03/31.
//

import SwiftUI
import FirebaseFirestoreSwift

import Foundation

struct Meeting : Identifiable,Codable,Equatable{
    @DocumentID var id: String?
    var name:String
    var description:String
    var latitude:Double
    var longitude:Double

}
