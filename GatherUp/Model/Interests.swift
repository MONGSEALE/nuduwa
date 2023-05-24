//
//  Interests.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/05/22.
//

import SwiftUI

struct Interests:Identifiable, Hashable{
    var id = UUID().uuidString
    var interestText : String
    var isExceeded = false
}
