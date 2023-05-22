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
    
    var body: some View {
        NavigationStack{
            VStack{
//                if (!viewModel.isLoading) {
                    if let user = viewModel.user {
                        ReusableProfileContent(isEdit: $isEdit, user: user){ updateName, updateImage in
                            if updateName != nil || updateImage != nil{
                                viewModel.editUser(userName: updateName, userImage: updateImage)
                            }
                        }
                    }
//                }else{
//                    ProgressView()
//                }
            }
            .navigationTitle("내 정보")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("프로필 편집", action: {isEdit = true})
                        Button("로그아웃", action: viewModel.logOutUser)
                        Button("계정 삭제", role: .destructive, action: viewModel.deleteAccount)
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.init(degrees: 90))
                            .tint(.black)
                            .scaleEffect(0.8)
                    }
                }
            }
            .toolbar{
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SearchUserView()
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .tint(.black)
                            .scaleEffect(0.9)
                    }
                }
            }
//            .overlay {
//                LoadingView(show: $viewModel.isLoading)
//            }
            .alert(viewModel.errorMessage, isPresented: $viewModel.showError) {
                
            }
        }
        .onAppear{
            viewModel.userListener(viewModel.currentUID)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
