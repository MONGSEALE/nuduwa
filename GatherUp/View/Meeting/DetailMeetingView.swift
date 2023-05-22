//
//  DetailMeetingView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/04/04.
//

import SwiftUI
import SDWebImageSwiftUI

struct DetailMeetingView: View {
    // @StateObject var viewModel: MeetingViewModel = .init()
    @ObservedObject var viewModel: MeetingViewModel //수정

    // var meeting: Meeting
    let meetingID: String
    // @Environment(\.dismiss) private var dismiss
    
    @State private var isEdit: Bool = false
    @State private var editTitle: String? = nil
    @State private var editDescription: String? = nil
    @State private var editPlace: String? = nil
    @State private var editNumbersOfMembers: Int? = nil
    @State private var editMeetingDate: Date? = nil
    
    @State private var toChatView: Bool = false
    
    /// 시간 설정 제한 범위
    var dateRange: ClosedRange<Date>{
        let min = Calendar.current.date(byAdding: .minute, value: 0, to: viewModel.meeting?.publishedDate ?? Date())!
        let max = Calendar.current.date(byAdding: .day, value: 6, to: viewModel.meeting?.publishedDate ?? Date())!
        
        return min...max
    }
  
    var body: some View {
        let isHost = viewModel.meeting?.hostUID == viewModel.currentUID
        let meeting = viewModel.meeting ?? Meeting.updateMeeting()  //nil이면 텅빈 모임

        NavigationStack{
            if viewModel.isLoading {
                ProgressView()
                    .padding(.top,30)
            }else{
                ScrollView(.vertical, showsIndicators: false){
                    LazyVStack{
                        HStack(spacing: 12){
                            WebImage(url: viewModel.user?.userImage ?? meeting.hostImage).placeholder{ProgressView()}
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 6){
                                EditText(text: meeting.title, editText: $editTitle, item: "모임 제목",isEditable: isEdit)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Text(viewModel.user?.userName ?? meeting.hostName ?? "")
                                    .font(.callout)
                                Text(meeting.meetingDate.formatted(date: .numeric, time: .shortened))
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            .hAlign(.leading)
                        }
                        EditText(text: meeting.description, editText: $editDescription, item: "모임 내용", isEditable: isEdit)
                            .textSelection(.enabled)
                            .padding(.vertical,8)
                            .hAlign(.leading)
                        if isHost && isEdit {
                            Section(header:Text("시간 설정")){
                                DatePicker("",selection: Binding<Date>(
                                    get: { self.editMeetingDate ?? meeting.meetingDate },
                                    set: { self.editMeetingDate = $0 }
                                ), in:dateRange)
                                    .datePickerStyle(GraphicalDatePickerStyle())
                            }
                        }
                        HStack{
                            Text("참여자:")
                                .font(.caption2)
                            ForEach(Array(viewModel.dicMembers.values)){ member in
                                MemberImageButton(member: member, isCurrent: member.memberUID == viewModel.currentUID)
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
                    ChatView(meetingID:meeting.id!,meetingTitle: meeting.title, hostUID: meeting.hostUID, members: $viewModel.dicMembers)
                }
                
                /// Host 여부에 따라 버튼 보이기
                Group{
                    if isHost {
                        EditButtonStack(isEdit: $isEdit) {
                            if viewModel.meeting != nil{
                                viewModel.editMeeting(title: editTitle, description: editDescription, place: editPlace, numbersOfMembers: editNumbersOfMembers, meetingDate: editMeetingDate)
                            }
                        } onCancle: {
                            editTitle = meeting.title
                            editDescription = meeting.description
                            editMeetingDate = meeting.meetingDate
                        } onDelete: {
                            viewModel.deleteMeeting(meetingID: meeting.id!)
                        }
                    } else {
                        Button(action: {
                            viewModel.leaveMeeting(meetingID: meeting.id!, memberUID: viewModel.currentUID)
                            // dismiss()
                        }){
                            CustomButtonText(text: "모임 나가기", backgroundColor: .red)
                        }
                    }
                }
                .padding(.bottom, 15)
            }
            
        }
        .onAppear{
            // editMeetingDate = meeting.meetingDate
            // viewModel.fetchUser(meeting.hostUID)
            // viewModel.meetingListener(meetingID: meeting.id!)
            // viewModel.membersListener(meetingID: meeting.id!)
            viewModel.fetchUser(meeting.hostUID)
            viewModel.meetingListener(meetingID: meeting.id!)
            viewModel.membersListener(meetingID: meeting.id!)
        }
        .onDisappear{
            viewModel.removeListeners()
            viewModel.detailViewDisappear()
        }
        // .onChange(of: viewModel.deletedMeeting) { _ in
        //     dismiss()
        // }
    }
}

struct EditText: View {
    let text: String
    @Binding var editText: String?
    let item: String
    let isEditable: Bool
    
    var body: some View {
      if isEditable {
          TextField(item, text: Binding<String>(
                            get: { self.editText ?? ""
                            },
                            set: { self.editText = $0.isEmpty ? nil : $0 }
                        ))
              .textFieldStyle(RoundedBorderTextFieldStyle())
              .padding()
              .onAppear{
                  editText = text
              }
              .onDisappear{
                if editText == text{
                    editText = nil
                }
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

struct MemberImageButton: View {
    let member: Member
    let isCurrent: Bool
    @State var showProfile: Bool = false
    
    var body: some View {
        Button{
            showProfile = true
        } label: {
            WebImage(url: member.memberImage).placeholder{ProgressView()}
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 30, height: 30)
                .clipShape(Circle())
                .sheet(isPresented: $showProfile){
                    MemberProfileView(member: member, isCurrent: isCurrent)
                }

        }
            
    }
}
