//
//  ProfileViewModel.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/04/05.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import GoogleSignIn

class ProfileViewModel: ObservableObject {
    @Published var myProfile: User?
    
    @Published var errorMessage: String = ""
    @Published var showError: Bool = false
    @Published var isLoading: Bool = false
    
    // MARK: Fetching User Data
    func fetchUserData()async{
        guard let userUID = Auth.auth().currentUser?.uid else{return}
        guard let user = try? await Firestore.firestore().collection("Users").document(userUID).getDocument(as: User.self) else{return}
        await MainActor.run(body: {
            myProfile = user
        })
    }
    
    // MARK: Logging User Out
    func logOutUser() {
        try? Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
    }
    
    // MARK: Deleting User Entire Account
    func deleteAccount() {
        isLoading = true
        Task{
            do{
                guard let userUID = Auth.auth().currentUser?.uid else{return}
                print(userUID)
                // Step 1: First Deleting Profile Image From Storage
//                let reference = Storage.storage().reference().child("Profile_Images").child(userUID)
//                try await reference.delete()
                // Step 2 : Deleting Firestore User Document
                try await Firestore.firestore().collection("Users").document(userUID).delete()
                // Final Step: Deleting Auth Account and Setting Log Status to False
                try await Auth.auth().currentUser?.delete()
                isLoading = false
            } catch {
                // await setError(error)
            }
        }
    }
    
    func registerUser(){
        
    }
    
    // MARK: Setting Error
    func setError(_ error: Error)async{
        // MARK: UI Must be run on Main Thread
        await MainActor.run(body: {
            isLoading = false
            errorMessage = error.localizedDescription
            showError.toggle()
        })
    }
}
