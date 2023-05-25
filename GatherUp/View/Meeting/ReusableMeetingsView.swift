//
//  ReusableMeetingsView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/03/31.
//

import SwiftUI

struct ReusableMeetingsView: View {
    @StateObject var viewModel: MeetingViewModel = .init()
    let title: String
    
    @State var showMessage: Bool = false
    
    var body: some View {
        NavigationStack{
            if viewModel.isLoading{
                /// 모임데이터 가져오는 중일때
                ProgressView()
                    .padding(.top,30)
            } else {
                if viewModel.meetingList.isEmpty{
                    /// 모임 배열이 비어있을때
                    Text("가입한 모임이 없습니다")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top,30)
                }else{
                    ScrollView{
                        ForEach(viewModel.meetingList){ meeting in
                            //                            let itemViewModel: MeetingViewModel = .init() //수정
                            NavigationLink(
                                destination: DetailMeetingView(meetingID: meeting.meetingID, hostUID: meeting.hostUID){
                                    showPopupMessage()
                                }
                            ){
                                MeetingCardView(meetingID: meeting.meetingID, hostUID: meeting.hostUID)
                            }
                            .navigationTitle(title)
                            .navigationBarTitleDisplayMode(.inline)
                            .listStyle(.plain)
                            Divider()
                        }
                    }
                }
                if showMessage{
                    ShowMessage(message: "모임이 종료되었습니다")
                }
            }
        }
        .onAppear{
            viewModel.meetingListListener()
        }
    }
    func showPopupMessage() {
        // Show the message
        withAnimation {
            showMessage = true
        }
        // Hide the message after the specified duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showMessage = false
            }
        }
    }
}

