//
//  SaveNewMeeting.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/03/31.
//

import SwiftUI
import Firebase

class SaveNewMeeting: ObservableObject {
    
    func createMeeting(meeting: Meeting){
        print("firebase save")
        //isLoading = true
        //showKeyboard = false
        Task{
            do{
                
                
                /// Directly Post Text Data to Firebase (Since there is no Images Present)
                
                try await createDocumentAtFirebase(meeting)
                
            }
        }
    }
    
    func createDocumentAtFirebase(_ meeting: Meeting)async throws{
        /// - Writing Document to Firebase Firestore
        let doc = Firestore.firestore().collection("Meetings").document()
        let _ = try doc.setData(from: meeting, completion: {error in
            if error == nil{
                /// Post Successfully Stored at Firebase
                print(error as Any)
            }
        })
    }
}

