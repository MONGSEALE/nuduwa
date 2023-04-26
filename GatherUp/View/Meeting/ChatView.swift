//
//  ChatView.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/04/25.
//

import SwiftUI
import Firebase
import SDWebImageSwiftUI

struct ChatView: View {
    
    
    @StateObject var viewModel: FirebaseViewModel = .init()
    var meeting: Meeting
    @StateObject var userViewModel: UserViewModel = .init()
    
    var body: some View {
        VStack {
                    ForEach(viewModel.members, id: \.id) { member in
                        HStack {
                            WebImage(url: member.memberImage)
                                .resizable()
                                .frame(width: 30, height: 30)
                                .scaledToFit()
                                .cornerRadius(60)
                                .clipShape(Circle())
                                .padding(4)
                                .background(Circle().fill(Color.blue))
                                .onAppear {
                                    userViewModel.userListener(userUID: meeting.hostUID)
                                }
                        }
                    }
                }
    }
}





