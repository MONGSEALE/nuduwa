//
//  FirestoreConvertible.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/05/15.
//

import SwiftUI
import FirebaseFirestore

protocol FirestoreConvertible {
    init?(data: [String: Any])
    var firestoreData: [String: Any] { get }
}

extension DocumentSnapshot {
    func data<T: FirestoreConvertible>(as type: T.Type) -> T? {
        let data = self.data()
        return data.flatMap { T(data: $0) }
    }
}
