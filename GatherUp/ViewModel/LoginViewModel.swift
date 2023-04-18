//
//  LoginViewModel.swift
//  Nudowa
//
//  Created by DaelimCI00007 on 2023/03/24.
//

import SwiftUI

import Firebase
//import FirebaseCore
import FirebaseFirestore
import FirebaseStorage

import AuthenticationServices
import GoogleSignIn

// SHA256 import
import CryptoKit

import PhotosUI

class LoginViewModel: ObservableObject {
    
    // MARK: Error Properties
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    // MARK: App Log Status
    @AppStorage("log_status") var logStatus: Bool = false
    
    // MARK: Apple Sign in Properies
    @Published var nonce: String = ""
    
    //로딩
    @Published var isLoading: Bool = false
    
    // Firestore
    //let db = Firestore.firestore()
    
    // MARK: Apple Sign in API
    func appleAuthenticate(credential: ASAuthorizationAppleIDCredential) {
        
        // getting Token...
        guard let token = credential.identityToken else{
            print("error with firebase")
            
            return
        }
        
        // Token String...
        guard let tokenString = String(data: token, encoding: .utf8) else{
            print("error with Token")
            return
        }
        
        let firebaseCredential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokenString, rawNonce: nonce)
        
        Auth.auth().signIn(with: firebaseCredential) { (result, err) in
            
            if let error = err{
                print(error.localizedDescription)
                return
            }
            
            // User Successfully Logged Into Firebase...
            print("Success Apple")
            withAnimation(.easeInOut) {self.logStatus = true}
            
        }
    }
    
    // MARK: Loggin Google User into Firebase
    func logGoogleUser(user: GIDGoogleUser) {
        //로딩
        isLoading = true
        Task{
            do{
                guard let idToken = user.authentication.idToken else{return}
                let accesToken = user.authentication.accessToken
                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accesToken)
                
                try await Auth.auth().signIn(with: credential)
                
                registerUser()
                
                print("Success Google")
                await MainActor.run(body: {
                    withAnimation(.easeInOut){logStatus = true}
                    isLoading = false
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

    func registerUser() {
        Task{
            do{
                let userData = Auth.auth().currentUser?.providerData[0]
                // Uploading Profile Photo Into Firebase Storage
                guard let userUID = Auth.auth().currentUser?.uid else{return}
                
                // Creating a User Firestore Object
                let user = User(userName: (userData?.displayName)!, userUID: userUID, userSNSID: userData?.uid, userEmail: userData?.email, userImage: userData?.photoURL)
                // Saving User Doc into Firestore Database
                let _ = try Firestore.firestore().collection("Users").document(userUID).setData(from: user, completion: {
                    error in
                    if error == nil{
                        print("Saved Successfully")
                    }
                })
            }catch{
                await handleError(error: error)
            }
        }
    }
}


// MARK: Extensions
extension UIApplication{
    func closeKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // Root Controller
    func rootController() -> UIViewController {
        guard let window = connectedScenes.first as? UIWindowScene else{return .init()}
        guard let viewcontroller = window.windows.last?.rootViewController else{return .init()}
        
        return viewcontroller
    }
}

// MARK: Apple Sign in Helpers
// Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
// 아래는 애플에서 제공하는 코드
func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
        return String(format: "%02x", $0)
    }.joined()
    
    return hashString
}
func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: Array<Character> = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length
    
    while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1,
                                               &random)
            if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
            }
            return random
        }
        
        randoms.forEach{ random in
            if remainingLength == 0 {
                return
            }
        
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
    print("randomNonceString: $result")
    return result
}
