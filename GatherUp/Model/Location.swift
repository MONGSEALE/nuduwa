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
    let coordinate: CLLocationCoordinate2D
    var userImage: URL?

}





