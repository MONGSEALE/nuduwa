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
    
    @Published var meetings: [Meeting] = []
    @Published var meetings2: [Meeting] = []
    @Published var pins: [Meeting] = []
    /// - View Properties
    @State var isFetching: Bool = true
    var newMeeting:Meeting?
    
    /// - Fetching Meeting's
    func fetchMeetings()async{
        do{
            var query: Query!
            query = Firestore.firestore().collection("Meetings")
                .order(by: "publishedDate", descending: true)
                .limit(to: 20)
            let docs = try await query.getDocuments()
            let fetchedMeetings = docs.documents.compactMap{ doc -> Meeting? in
                try? doc.data(as: Meeting.self)
            }
            await MainActor.run(body: {
                meetings = fetchedMeetings
                if let newMeeting = newMeeting{
                    meetings2 = meetings + [newMeeting]
                }else{
                    meetings2 = meetings
                }
                isFetching = false
            })
        }catch{
            print(error.localizedDescription)
        }
    }
    func addMeeting(la:Double, lo:Double){
        let user = Auth.auth().currentUser
        guard
            let userName: String = user?.displayName,
            let userUID: String = user?.uid
        else{return}
        let profileURL = user?.photoURL ?? URL(filePath: "")
        newMeeting = Meeting(name: "모임1", description: "아무나", latitude: la, longitude: lo, userName: userName, userUID: userUID, userImage: profileURL)
        
        meetings2 = meetings + [newMeeting!]
        print("add : \(String(describing: newMeeting?.latitude))")
        
        //createMeeting(meeting: newMeeting)
    }
    func cancleMeeting(){
        newMeeting = nil
        meetings2 = meetings
    }
    
    
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
