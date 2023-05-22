//
//  MeetingCardView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/03/31.
//

import SwiftUI
import SDWebImageSwiftUI

struct MeetingCardView: View {
    
    @StateObject var viewModel: MeetingViewModel = .init()
    //    @ObservedObject var viewModel: MeetingViewModel //수정
    
    let meetingID: String
    let hostUID: String
    //    let isHost: Bool
    //    let meetingID: String
    //    let hostUID: String
    /// - Callbacks
    // var onUpdate: (Meeting)->()
    // var onDelete: ()->()
    
    var body: some View {
        ZStack(alignment: .topTrailing){
            HStack(alignment: .top, spacing: 8){
                WebImage(url: viewModel.user?.userImage).placeholder{ProgressView()}
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 35, height: 35)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 6){
                    Text(viewModel.user?.userName ?? "")
                        .font(.callout)
                        .foregroundColor(.black)
                    if let meeting = viewModel.meeting {
                        Text("\(meeting.publishedDate.formatted(date: .abbreviated, time: .shortened))에 생성됨")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text(meeting.title)
                            .font(.system(size: 20))
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                    } else {
                        ProgressView()
                    }
                }
                Spacer()
                Text("MINE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 8)
                    .padding(.leading, 10)
                    .background(
                        RibbonShape()
                            .fill(Color.blue)
                    )
                    .foregroundColor(.white)
                    .rotationEffect(Angle(degrees: 45), anchor: .center)
                    .offset(x: 28)
                    
                }
        }
        .hAlign(.leading)
        
        .onAppear {
            viewModel.fetchUser(hostUID)
            viewModel.meetingListener(meetingID: meetingID)
        }
        //        .onDisappear {
        //            // 클릭해서 DetailMeetingView가 보여질 때는 removeListener() 호출하지 않음
        //            viewModel.removeListeners()
        //
        //        }
    
    }
}

struct RibbonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // 사다리꼴의 좌측 상단 점으로 이동합니다. 이때, 사다리꼴 모양을 만들기 위해 x좌표를 수정합니다.
           path.move(to: CGPoint(x: rect.minX + rect.width * 0.28, y: rect.minY))
           // 사다리꼴의 우측 상단 점으로 선을 그립니다. 이때, 사다리꼴 모양을 만들기 위해 x좌표를 수정합니다.
           path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.27, y: rect.minY))
           // 사다리꼴의 우측 하단 점으로 선을 그립니다.
           path.addLine(to: CGPoint(x: rect.maxX , y: rect.maxY))
           // 사다리꼴의 좌측 하단 점으로 선을 그립니다.
           path.addLine(to: CGPoint(x: rect.minX , y: rect.maxY))
           // 사다리꼴의 좌측 상단 점으로 돌아가 도형을 완성합니다.
           path.closeSubpath()
        
        return path
    }
}
