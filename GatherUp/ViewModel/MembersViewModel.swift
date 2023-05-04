//
//  MembersViewModel.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/05/04.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

class MembersViewModel: ObservableObject {
    @Published var members: [Members] = []
    
    private var docListner: ListenerRegistration?
    
    private let db = Firestore.firestore()
    private let strMeetings = "Meetings"        // Firestore에 저장된 콜렉션 이름
    private let strMembers = "Members"          // Firestore에 저장된 콜렉션 이름
    private let strMessage = "Message"          // Firestore에 저장된 콜렉션 이름
    
    /// 모임맴버 가져오기
    func membersListener(meetingId: String){
        docListner = db.collection(strMeetings).document(meetingId).collection(strMembers)
            .addSnapshotListener { (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {return}
                documents.forEach{document in
                    self.members = documents.compactMap{ documents -> Members? in
                        try? documents.data(as: Members.self)
                    }
                }
            }
    }
}


