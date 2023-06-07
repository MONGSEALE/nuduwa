//
//  MemberReviewView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/06/05.
//

import SwiftUI
import SDWebImageSwiftUI
/*
struct MemberReviewView: View {
    @StateObject var viewModel: MeetingViewModel = .init()
    
    let meetingID : String
    let meetingTitle: String
    let hostUID: String
    let members: [Member]
    @Binding var showReview: Bool
    
    var body: some View {
        NavigationView{
            ScrollView{
                ForEach(members) { member in
                    if member.memberUID != viewModel.currentUID{
                        MemberCardView(member: member)
                        Divider()
                    }
                }
            }
            .navigationBarTitle("\(meetingTitle)", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button{
                        showReview = false
                    } label: {
                        HStack {
                            Image(systemName: "arrow.left")
                            Text("뒤로")
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

struct MemberCardView: View {
    let member: Member
    
    @State var showSheet: Bool = false
    @State var reviewText: String?
    
    var body: some View {
        Button{
            showSheet = true
        } label: {
            HStack(spacing: 10){
                WebImage(url: member.memberImage).placeholder{ProgressView()}
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 5){
                    Text(member.memberName ?? "")
                        .font(.title)
                        .foregroundColor(.black)
                    Text("\(member.joinDate.formatted(date: .abbreviated, time: .shortened))에 참여함")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .sheet(isPresented: $showSheet) {
            MemberReviewSheet(memberImage: member.memberImage, memberName: member.memberName, showSheet: $showSheet){ reviewText, progress in
                //
            }
        }
    }
}
*/
struct MemberReviewSheet: View {
    let memberImage: URL?
    let memberName: String?
    @State var reviewText: String = ""
    @State var progress: CGFloat = 1
    @Binding var showSheet: Bool
    
    var createReview: (String,CGFloat)->()
    
    var body: some View {
        VStack{
            VStack(alignment: .leading){
                HStack{
                    WebImage(url: memberImage).placeholder{ProgressView()}
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    Text(memberName ?? "")
                        .font(.title)
                        .foregroundColor(.black)
                }
            }
            
            GaugeView(progress: $progress)
                .frame(width: 200, height: 200)
                .padding(.top, 30)
                
            Slider(value: $progress)
                .padding(.top, -50)
            
            ZStack(alignment: .topLeading){
                TextEditor(text: $reviewText)
                if reviewText.isEmpty {
                    Text("\(memberName ?? "")님의 리뷰를 작성해주세요")
                        .foregroundColor(.gray)
                        .padding(8)
                }
            }
            
            HStack(spacing: 15){
                Button{
                    if !reviewText.isEmpty{
                        createReview(reviewText,progress)
                        showSheet = false
                    }
                } label: {
                    Text("저장")
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding(.horizontal,50)
                        .padding(.vertical,10)
                        .background(reviewText.isEmpty ? .gray : .blue,in: RoundedRectangle(cornerRadius: 10))
                }
                Button{
                    showSheet = false
                } label: {
                    Text("취소")
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding(.horizontal,50)
                        .padding(.vertical,10)
                        .background(.red,in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(20)
    }
}
