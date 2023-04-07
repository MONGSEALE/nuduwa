//
//  ProfileView.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/03/17.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct ProfileView: View {
    
    @StateObject var viewModel: ProfileViewModel = .init()
    
    var body: some View {
        NavigationStack{
            VStack{
                if (viewModel.myProfile != nil) {
                    ReusableProfileContent(user: viewModel.myProfile!)
                        .refreshable {
                            // MARK: Refresh User Data
                            viewModel.myProfile = nil
                            await viewModel.fetchUserData()
                        }
                }else{
                    ProgressView()
                }
            }
            
            .navigationTitle("마이페이지")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // MARK: Two Action's
                        // 1. Logout
                        Button("로그아웃", action: viewModel.logOutUser)
                        // 2. Delete Account
                        Button("계정 삭제", role: .destructive, action: viewModel.deleteAccount)
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.init(degrees: 90))
                            .tint(.black)
                            .scaleEffect(0.8)
                    }
                }
            }
            .overlay {
                LoadingView(show: $viewModel.isLoading)
            }
            .alert(viewModel.errorMessage, isPresented: $viewModel.showError) {
                
            }
            .task {
                // This Modifer is like onAppear
                // So Fetching for the First Time Only
                if viewModel.myProfile != nil{return }
                // MARK: Initial Fetch
                await viewModel.fetchUserData()
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
