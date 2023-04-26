//
//  UserViewModel.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/04/18.
//

import SwiftUI
import Firebase
import FirebaseFirestore

class UserViewModel: ObservableObject {
    @Published var user: User?
    
    private var docListner: ListenerRegistration?
    
    private let db = Firestore.firestore().collection("Users")
    
    func userListener(userUID:String) {
        let doc = db.document(userUID)
        docListner = doc.addSnapshotListener { (snapshot, error) in
            if let error = error {print("에러!userListner:\(error)");return}
            guard let document = snapshot, ((snapshot?.exists) != nil) else{print("No Users");return}
              
            do{
                self.user = try document.data(as: User.self)
            } catch {
                print("에러!userListner")
            }
        }
    }
}
