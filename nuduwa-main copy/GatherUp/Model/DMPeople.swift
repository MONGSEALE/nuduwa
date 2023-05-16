//
//  DMPeople.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/05/11.
//

import SwiftUI
import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore

struct DMPeople : Identifiable,Codable,Equatable {
    @DocumentID var id: String?

    var users:[String]
}
