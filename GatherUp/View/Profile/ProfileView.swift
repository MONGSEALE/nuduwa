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
            .overlay {
                LoadingView(show: $viewModel.isLoading)
            }
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
