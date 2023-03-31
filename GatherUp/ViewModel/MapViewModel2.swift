//
//  MapViewModel2.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/03/31.
//

import SwiftUI
import Firebase

class MapViewModel2: ObservableObject {
    // MARK: Error Properties
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    //로딩
    @Published var isLoading: Bool = false
    
    func createMeeting(meeting: Meeting){
        print("firebase save")
        //isLoading = true
        //showKeyboard = false
        Task{
            do{
                /// - Writing Document to Firebase Firestore
                let doc = Firestore.firestore().collection("Meetings").document()
                let _ = try doc.setData(from: meeting, completion: {error in
                    if error == nil{
                        /// Post Successfully Stored at Firebase
                        print(error as Any)
                    }
                })
                
            } catch {
                await handleError(error: error)
            }
        }
    }
    
    // MARK: Handling Error
    func handleError(error: Error)async{
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        })
    }
    
    
}
