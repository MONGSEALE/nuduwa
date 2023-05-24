//
//  ProfileView.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/03/17.
//

import SwiftUI

struct ProfileView: View {
    
    @StateObject var viewModel: ProfileViewModel = .init()
    
    @State var isEdit: Bool = false
    @State var showPopup : Bool = false
    @State var errorMessage: String = ""
    
    var body: some View {
        ZStack{
            Text("d")
//            NavigationStack{
//                VStack{
//                    if (viewModel.user != nil && !viewModel.isLoading) {
//                        ReusableProfileContent(isEdit: $isEdit, user: viewModel.user!){ updateName, updateImage in
//                            if updateName != nil || updateImage != nil{
//                                viewModel.editUser(userName: updateName, userImage: updateImage)
//                            }
//                        } showPopup : { text in
//                            errorMessage = text
//                            withAnimation(.easeInOut){
//                                                  showPopup = true
//                                              }
//
//                                              DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                                                  withAnimation(.easeInOut){
//                                                      showPopup = false
//                                                  }
//                                              }
//
//                        }
//                    }else{
//                        ProgressView()
//                    }
//                }
//                .overlay {
//                    LoadingView(show: $viewModel.isLoading)
//                }
//                .alert(viewModel.errorMessage, isPresented: $viewModel.showError) {
//                    
//                }
//            }
//            if showPopup {
//                            Text(errorMessage)
//                                .fontWeight(.semibold)
//                                .foregroundColor(.white)
//                                .padding()
//                                .background(Color.black)
//                                .cornerRadius(10)
//                              //  .transition(.move(edge: .top))
//                                .zIndex(1)
//            }
//        }
//        .onAppear{
//            viewModel.userListener(viewModel.currentUID)
        }
    }
}




