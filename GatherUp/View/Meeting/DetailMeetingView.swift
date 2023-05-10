//
//  DetailMeetingView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/04/04.
//

import SwiftUI
import SDWebImageSwiftUI

struct DetailMeetingView: View {
    @StateObject var viewModel: MeetingViewModel = .init()

    var meeting: Meeting
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEdit: Bool = false
    @State private var title: String = ""
    @State private var description: String = ""
    @State var meetingDate: Date = Date()
    
    @State private var toChatView: Bool = false
    
    /// 시간 설정 제한 범위
    var dateRange: ClosedRange<Date>{
        let min = Calendar.current.date(byAdding: .minute, value: 0, to: meeting.publishedDate)!
        let max = Calendar.current.date(byAdding: .day, value: 6, to: meeting.publishedDate)!
        
        return min...max
    }
  
    var body: some View {
        let isHost = meeting.hostUID == viewModel.currentUID()
        NavigationStack{
            if viewModel.isLoading {
                ProgressView()
                    .padding(.top,30)
            }else{
                ScrollView(.vertical, showsIndicators: false){
                    LazyVStack{
                        HStack(spacing: 12){
                            WebImage(url: viewModel.user?.userImage).placeholder{ProgressView()}
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 6){
                                EditText(text: viewModel.meeting.title, editText: $title, item: "모임 제목",isEditable: isEdit)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Text(viewModel.user?.userName ?? "")
                                    .font(.callout)
                                Text(viewModel.meeting.meetingDate.formatted(date: .numeric, time: .shortened))
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            .hAlign(.leading)
                        }
                        EditText(text: viewModel.meeting.description, editText: $description, item: "모임 내용", isEditable: isEdit)
                            .textSelection(.enabled)
                            .padding(.vertical,8)
                            .hAlign(.leading)
                        if isHost && isEdit {
                            Section(header:Text("시간 설정")){
                                DatePicker("",selection: $meetingDate, in:dateRange)
                                    .datePickerStyle(GraphicalDatePickerStyle())
                            }
                        }
                        HStack{
                            Text("참여자ID:")
                                .font(.caption2)
                            ForEach(viewModel.members){ member in
                                Text(" \(member.memberUID),")
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .padding(20)
                
                Button{
                    toChatView = true
                } label: {
                    Text("채팅 참가")
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding(.horizontal,30)
                        .padding(.vertical,10)
                        .background(.blue,in: Capsule())
                }
                .sheet(isPresented: $toChatView){
                    ChatView(meetingID:meeting.id!,meetingTitle: meeting.title, hostUID: meeting.hostUID, members: $viewModel.members)
                }
                
                /// Host 여부에 따라 버튼 보이기
                Group{
                    if isHost {
                        EditButtonStack(isEdit: $isEdit) {
                            viewModel.editMeeting(title: title, description: description, meetingDate: meetingDate)
                        } onCancle: {
                            title = viewModel.meeting.title
                            description = viewModel.meeting.description
                            meetingDate = viewModel.meeting.meetingDate
                        } onDelete: {
                            viewModel.deleteMeeting(meetingID: viewModel.meeting.id!)
                        }
                    } else {
                        Button(action: {
                            viewModel.leaveMeeting(meetingID: viewModel.meeting.id!, memberUID: viewModel.currentUID())
                            dismiss()
                        }){
                            CustomButtonText(text: "모임 나가기", backgroundColor: .red)
                        }
                    }
                }
                
            }
        }
        .onAppear{
            viewModel.meeting = meeting
            viewModel.fetchUser(userUID: meeting.hostUID)
            viewModel.meetingListener(meetingID: meeting.id!)
            viewModel.membersListener(meetingID: meeting.id!)
            meetingDate = meeting.meetingDate
        }
        .onDisappear{
            viewModel.removeListener()
        }
        .onChange(of: viewModel.deletedMeeting) { _ in
            dismiss()
        }
    }
}

struct EditText: View {
    let text: String
    @Binding var editText: String
    let item: String
    let isEditable: Bool
    
    var body: some View {
      if isEditable {
          TextField(item, text: $editText)
              .textFieldStyle(RoundedBorderTextFieldStyle())
              .padding()
              .onAppear{
                  editText = text
              }
      } else {
          Text(text)
              .font(.title)
              .fontWeight(.bold)
              .padding()
      }
    }
}
struct EditButtonStack: View {
    
    @Binding var isEdit: Bool
    
    var onEdit: ()->()
    var onCancle: ()->()
    var onDelete: ()->()
    
    var body: some View {
        HStack{
            if isEdit{
                Button(action: {
                    onEdit()
                    isEdit.toggle()
                }){
                    CustomButtonText(text: "수정 완료", backgroundColor: .blue)
                }
//                .disabled((title == "")||(description == ""))
                Button(action: {
                    onCancle()
                    isEdit.toggle()
                }){
                    CustomButtonText(text: "수정 취소", backgroundColor: .red)
                }
            } else {
                Button(action: {
                    isEdit.toggle()
                }){
                    CustomButtonText(text: "모임 수정", backgroundColor: .blue)
                }
                Button(action: {
                    onDelete()
                }){
                    CustomButtonText(text: "모임 삭제", backgroundColor: .red)
                }
            }
        }
    }
}


struct CustomButtonText: View {
    let text: String
    let backgroundColor: Color
    
    var body: some View {
      Text(text)
        .font(.callout)
        .foregroundColor(.white)
        .padding(.horizontal,30)
        .padding(.vertical,10)
        .background(backgroundColor,in: Capsule())
    }
}


