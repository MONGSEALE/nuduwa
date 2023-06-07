//
//  PastMeetingListView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/06/05.
//

// 프로필뷰에서 지난 모임리스트 클릭시 보여질 뷰
// 추후 비슷하면 MeetingsView(ReusableMeetingsView)와 합칠예정

import SwiftUI

struct EndMeetingListView: View {
    @StateObject var viewModel: MeetingViewModel = .init()
    
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
                    Text("지난 모임이 없습니다")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top,30)
                }else{
                    ScrollView{
                        ForEach(viewModel.meetingList){ meeting in
                            NavigationLink(
                                destination: DetailMeetingView(meetingID: meeting.meetingID, hostUID: meeting.hostUID, isEnd: true){
                                    showPopupMessage()
                                }
                            ){
                                MeetingCardView(meetingID: meeting.meetingID, hostUID: meeting.hostUID)
                            }
                            .navigationTitle("지난 모임")
                            .navigationBarTitleDisplayMode(.inline)
                            .listStyle(.plain)
                            Divider()
                        }
                    }
                }
//                if showMessage{
//                    ShowMessage(message: "모임이 종료되었습니다")
//                }
            }
        }
        .onAppear{
            viewModel.meetingListListener(isEnd: true)
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
