//
//  LoginViewModel.swift
//  Nudowa
//
//  Created by DaelimCI00007 on 2023/03/24.
//

import SwiftUI

import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

import AuthenticationServices
import GoogleSignIn

// SHA256 import
import CryptoKit

import PhotosUI

class LoginViewModel: FirebaseViewModel {
    
    @Published var isLogin: Bool = false
    // MARK: Apple Sign in Properies
    @Published var nonce: String = ""
    
    override init() {
        super.init()
        listenForUserChanges()
        listenForAuthChanges()
    }
    
    /// Firestore User 컬랙션에 정보가 없을때 로그아웃
    private func listenForUserChanges() {
        print("listenForUserChanges")
        Task{
            guard let userUID = Auth.auth().currentUser?.uid else{
                DispatchQueue.main.async {
                    withAnimation(.easeInOut) {
                        self.isLogin = false
                    }
                }
                return
            }
            db.collection(strUsers).document(userUID).addSnapshotListener { (snapshot, error) in
                if let error = error {print("에러!listenForUserChanges: \(error)");return}
                if let snapshot{
                    if snapshot.exists{
                        self.isLogin = true
                        print("isLogin2: \(self.isLogin)")
                    } else {
                        DispatchQueue.main.async {
                            withAnimation(.easeInOut) {
                                self.isLogin = false
                            }
                        }
                    }
                }
                
            }
        }
    }
    /// Firebase User 로그인 인증이 안될때 로그아웃
    private func listenForAuthChanges() {
        print("listenForAuthChanges")
        Auth.auth().addStateDidChangeListener { _, user in
            if user != nil {
                self.isLogin = true
            } else {
                DispatchQueue.main.async {
                    withAnimation(.easeInOut) {
                        self.isLogin = false
                    }
                }
            }
        }
    }
    
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
        }
    }
    
    // MARK: Loggin Google User into Firebase
    func logGoogleUser(user: GIDGoogleUser) {
        print("logGoogleUser")
        //로딩
        isLoading = true
        Task{
            do{
                guard let idToken = user.authentication.idToken else{return}
                let accesToken = user.authentication.accessToken
                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accesToken)
                
                try await Auth.auth().signIn(with: credential)
                
                let currentUser = try? await getUser(currentUID)
                if currentUser == nil{
                    registerUser()
                }
                
                print("Success Google")
                await MainActor.run(body: {
                    isLoading = false
                })
            } catch {
                await handleError(error)
            }
        }
    }

    func registerUser() {
        print("registerUser")
        Task{
            do{
                guard let userData = Auth.auth().currentUser?.providerData[0] else{
                    print("registerUser오류")
                    return
                }
                guard let currentUID = currentUID else{
                    print("registerUser오류")
                    return
                }
                print("1")
                // Creating a User Firestore Object
                let newUser = User.newGoogleUser(userName: userData.displayName, userGoogleUID: userData.uid, userGoogleEmail: userData.email, userImage: userData.photoURL)
                // Saving User Doc into Firestore Database
                print("2")
                let doc = db.collection(strUsers).document(currentUID)
                print("3")
//                try await doc.setData(newUser)
                try doc.setData(newUser, completion: {
                    error in
                    guard let error = error else{
                        print("에러")
                        self.isLoading = false
                        return
                    }
                    print("Saved Successfully")
                    
                })
                print("4")
            }catch{
                print("5")
                await handleError(error)
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
