//
//  FirestoreConvertible.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/05/15.
//

import SwiftUI
import FirebaseFirestore
import Combine

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

//test
extension Query {
    func getDocuments<T>(as type: T.Type) async throws -> [T] where T: Decodable {
        try await getDocumentsWithSnapshot(as: type).items
    }
    
    func getDocumentsWithSnapshot<T>(as type: T.Type) async throws -> (items: [T], lastDocument: DocumentSnapshot?) where T: Decodable {
        let snapshot = try await self.getDocuments()
        
        let items = try snapshot.documents.map{ document in
            try document.data(as: T.self)
        }
        
        return (items, snapshot.documents.last)
    }
    
    func addSnapshotListener<T>(as type: T.Type) -> (AnyPublisher<[T], Error>, ListenerRegistration) where T: Decodable {
        let publisher = PassthroughSubject<[T], Error>()
        
        let listener = self.addSnapshotListener { snapshot, error in
            if error != nil {return}
            // 에러가 안나고 정상적으로 작동했는데 서버에 데이터가 없을때 else문 실행
            guard let documents = snapshot?.documents else{print("No Users");return}
            
            let items: [T] = documents.compactMap{ doc -> T? in
                try? doc.data(as: T.self)
            }
            publisher.send(items)
        }
        
        return (publisher.eraseToAnyPublisher(), listener)
    }
}
