//
//  DMListView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/05/11.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import SDWebImageSwiftUI

struct DMListView: View {
    
    @StateObject private var viewModel = DMViewModel()
    @State private var userImageURLs: [String: URL] = [:]
    @State private var tabBar : UITabBar! = nil
    @Binding var showDMView: Bool
    @Binding var selectedReceiverID: String
    @Binding var selectedReceiverName: String
    
    
    var body: some View {
        
        NavigationView{
            VStack{
                HStack(spacing:16){
                    Spacer()
                        .frame(width: 16)
                    Text("채팅")
                        .font(.system(size: 24,weight: .bold))
                    Spacer()
                    Button{
                        
                    } label: {
                        Image(systemName: "gear")
                    }
                }
                .padding()
                
                ScrollView {
                    ForEach(viewModel.recentMessages.keys.sorted(), id: \.self) { receiverID in
                        if let dm = viewModel.recentMessages[receiverID] {
                            VStack{
                                NavigationLink(
                                    destination: EmptyView(),
                                    isActive: $showDMView
                                ) {
                                    DMRowView(dm: dm, receiverID: receiverID)
                                        .onTapGesture {
                                            selectedReceiverID = receiverID
                                            showDMView = true
                                        }
                                    Divider()
                                        .padding(.vertical, 8)
                                }
                            }
                            .contextMenu {
                                  Button(action: {
//                                      viewModel.deleteRecentMessage(receiverID: receiverID)
                                  }) {
                                      Label("채팅방 나가기", systemImage: "trash")
                                  }
                              }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onAppear {
           viewModel.startListeningRecentMessages()
       }
    }
    private func userImageURL(for id: String) -> URL {
            if let url = userImageURLs[id] {
                return url
            } else {
                let userDocumentRef = Firestore.firestore().collection("Users").document(id)
                userDocumentRef.getDocument { documentSnapshot, error in
                    if let error = error {
                        print("Error retrieving user profile image URL: \(error.localizedDescription)")
                    } else if let documentSnapshot = documentSnapshot, let data = documentSnapshot.data() {
                        if let user = try? documentSnapshot.data(as: User.self), let url = user.userImage {
                            DispatchQueue.main.async { // make sure to update the UI on the main thread
                                self.userImageURLs[id] = url
                            }
                        }
                    }
                }
                return URL(string: "https://example.com/placeholder.jpg")! // Return a placeholder URL while fetching the actual URL
            }
        }
    struct DMRowView: View {
        let dm: DM
        let receiverID: String
        
        var body: some View{
            HStack(spacing: 16) {
                WebImage(url: URL(string: ""))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .overlay(RoundedRectangle(cornerRadius: 44)
                        .stroke(Color.black, lineWidth: 1))
                VStack(alignment: .leading) {
                    Text("dm.receiverName")
                        .font(.system(size: 16, weight: .bold))
                    Text(dm.message)
                        .font(.system(size: 14))
                        .foregroundColor(Color(.lightGray))
                }
                Spacer()
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}


