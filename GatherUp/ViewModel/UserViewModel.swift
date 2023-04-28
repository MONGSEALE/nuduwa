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
    
    /// 유저 데이터 실시간 가져오기
    func userListener(userUID: String) {
        print("userListener")
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
    
    /// 유저 데이터 한번 가져오기
    func fetchUser(userUID: String){
        print("fetchUser")
        print(userUID)
        db.document(userUID).getDocument{ (document, error) in
            guard error == nil else{print("에러!fetchUser:\(String(describing: error))");return}
            guard let document = document else{print("에러!fetchUser1");return}
            
            do{
                self.user = try document.data(as: User.self)
            } catch {
                print("에러!fetchUser2")
            }
        }
    }
}
