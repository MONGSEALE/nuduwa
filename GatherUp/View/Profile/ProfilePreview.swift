//
//  MemberProfileView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/05/04.
//

import SwiftUI
import SDWebImageSwiftUI

struct ProfilePreview: View {
    @StateObject var viewModel: ProfileViewModel = .init()
    let user: User
    let isCurrent: Bool
//    let meetingID: String?

    @State var showDMView: Bool = false
    @State var receiverUID: String?
    @State var showReview: Bool = false
    
    var showChatButton: Bool

    var body: some View {
        ZStack{
            VStack{
                HStack(spacing: 12){
                    WebImage(url: user.userImage).placeholder{ProgressView()}
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                    
                    Text(user.userName)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                        .hAlign(.leading)
                }
                GaugeView(progress: $viewModel.rating)
                        .frame(width: 200, height: 200)
                        .padding(.top, 30)
                List(viewModel.reviews){ review in
                    HStack{
                        Text(review.reviewText)
                    }
                }
                Spacer()
                HStack(spacing: 20){
                    if !isCurrent {
                        if !viewModel.isBlock {
                            Button {
                                viewModel.blockUser(user.id)
                                viewModel.isBlock = true
                            } label: {
                                Text("차단")
                                    .font(.callout)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 10)
                                    .background(.red, in: Capsule())
                            }
                        }
                        if showChatButton {
                            Button {
                                showDMView = true
                            } label: {
                                Text("1:1 메시지")
                                    .font(.callout)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 10)
                                    .background(.blue, in: Capsule())
                            }
                            .fullScreenCover(isPresented: $showDMView){
                                DMView(receiverUID: $receiverUID, showDMView: $showDMView)
                                    .edgesIgnoringSafeArea(.all)
                                    .transition(.move(edge: .trailing))
                                    .animation(.easeInOut(duration: 0.3))
                            }
                        }
                        if !viewModel.meetingsWithMemeberOfReview.isEmpty{
                            Button {
                                showReview = true
                            } label: {
                                Text("리뷰")
                                    .font(.callout)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 10)
                                    .background(.green, in: Capsule())
                            }
                            .sheet(isPresented: $showReview) {
                                MemberReviewListView(member: Member(memberUID: user.id ?? "", memberName: user.userName, memberImage: user.userImage), meetings: viewModel.meetingsWithMemeberOfReview){
                                    showReview = false
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(30)
        .onAppear{
            viewModel.fetchReview(user.id)
            viewModel.fetchBlockUser(user.id)
            viewModel.fetchReviewList(user.id)
            receiverUID = user.id
        }
    }
}
