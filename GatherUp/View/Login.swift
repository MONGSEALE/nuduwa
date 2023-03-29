//
//  Login.swift
//  Google5
//
//  Created by DaelimCI00007 on 2023/03/22.
//

import SwiftUI
// MARK: Intergrating Apple Sign in
import AuthenticationServices
import GoogleSignIn
import GoogleSignInSwift
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct Login: View {
    @StateObject var loginModel: LoginViewModel = .init()
    
    //로딩
    @AppStorage("isLoading") var isLoading: Bool = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 15) {
                Image(systemName: "triangle")
                    .font(.system(size: 38))
                    .foregroundColor(.indigo)
                
                (Text("Welcome,")
                    .foregroundColor(.black) +
                 Text("\nLogin to continue")
                    .foregroundColor(.gray)
                )
                .font(.title)
                .fontWeight(.semibold)
                .lineSpacing(10)
                .padding(.top, 20)
                .padding(.trailing, 15)
                .padding(.bottom, 150)
                
                
                VStack(spacing: 8) {
                    // MARK: Custom Apple Sign in Button
                    CustomButton()
                    .overlay {
                        SignInWithAppleButton { (request) in
                            // requesting paramertes from apple login...
                            loginModel.nonce = randomNonceString()
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = sha256(loginModel.nonce)
                        } onCompletion: { (result) in
                            switch result {
                            case .success(let user) :
                                print("success")
                                guard let credential = user.credential as?
                                        ASAuthorizationAppleIDCredential else {
                                    print("error with firebase")
                                    return
                                }
                                loginModel.appleAuthenticate(credential: credential)
                            case.failure(let error) :
                                print(error.localizedDescription)
                            }
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 55)
                        .blendMode(.overlay)
                    }
                    
                    .clipped()
                    
                    Text("(OR)")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 30)
                        .padding(.bottom, 30)
                        .padding(.horizontal)
                    
                    // MARK: Custom Google Sign in Button
                    CustomButton(isGooGle: true)
                    .overlay {
                        // MARK: We Have Navtive Google Sign in Button
                        // It's Simple to Integrate Now
                        if let clientID = FirebaseApp.app()?.options.clientID{
                            GoogleSignInButton{
                                GIDSignIn.sharedInstance.signIn(with: .init(clientID: clientID), presenting: UIApplication.shared.rootController()){user, error in
                                    if let error = error{
                                        print(error.localizedDescription)
                                        return
                                    }
                                    // MARK: Logging Google User into Firebase
                                    if let user{
                                        loginModel.logGoogleUser(user: user)
                                    }
                                }
                            }
                            .blendMode(.overlay)
                        }
                    }
                    .clipped()
                    
                }
                .padding(.leading, -60)
                .frame(maxWidth: .infinity)
            }
            .padding(.leading, 60)
            .padding(.vertical, 15)
        }
        .overlay(content: {
            LoadingView(show: $isLoading)
        })
//        .alert(loginModel.errorMessage, isPresented: $loginModel.showError) {
            
//        }
    }
    
    @ViewBuilder
    func CustomButton(isGooGle: Bool = false) -> some View {
        HStack{
            Group{
                if isGooGle {
                    Image("google")
                        .resizable()
                        .renderingMode(.template)   //이미지 컬러 지우기
                } else {
                    Image(systemName: "applelogo")
                        .resizable()
                }
            }
            .aspectRatio(contentMode: .fit)
            .frame(width: 40, height: 40)
            .frame(height: 80)
            
            Text("\(isGooGle ? "Google" : " Apple") Sign in")
                .font(.callout)
                .lineLimit(1)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 15)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.black)
        }
    }
    
}

struct Login_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
