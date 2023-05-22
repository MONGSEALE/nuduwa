//
//  FirestoreConvertible.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/05/15.
//

import SwiftUI
import FirebaseFirestore

protocol FirestoreConvertible {
    init?(data: [String: Any], id: String)
    var firestoreData: [String: Any] { get }
}

extension DocumentSnapshot {
    func data<T: FirestoreConvertible>(as type: T.Type) -> T? {
        let data = self.data()
        let id = self.documentID // documentID 가져오기
        return data.flatMap { T(data: $0, id: id) }
    }
}
