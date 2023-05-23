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
            HStack(){
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
                }
                .padding(10)
                Spacer()
                if hostUID == viewModel.currentUID {
                    RibbonView(text: "MINE", width: 70, height: 70)

//                    Text("MINE")
//                        .font(.caption)
//                        .fontWeight(.bold)
//                        .padding(.horizontal, 36)
//                        .padding(.vertical, 8)
//                        .padding(.leading, 10)
//                        .background(
//                            RibbonShape()
//                                .fill(Color.blue)
//                        )
//                        .foregroundColor(.black)
//                        .rotationEffect(Angle(degrees: 45), anchor: .center)
//                        .offset(x: 28)
                }
            }
        }
        
        .onAppear {
            viewModel.fetchUser(hostUID)
            viewModel.meetingListener(meetingID: meetingID)
        }
        .onDisappear {
            viewModel.removeListeners()
        }
    }
}

struct RibbonView: View {
    let text: String
    let width: Double
    let height: Double
    
    var body: some View {
        ZStack{
            RibbonShape()
                .fill(.blue)
            Text(text)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                // 45도 돌리기
                .rotationEffect(Angle(degrees: 45), anchor: .center)
                // 정중앙에서 x만큼 왼쪽으로 y만큼 밑으로 이동
                .offset(x: 12, y: -7)
        }
        .frame(width: width, height: height)
    }
}
struct RibbonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // 사다리꼴의 네 점을 정의합니다
        // 왼쪽 끝, 위쪽 끝 좌표
        let leftTopPoint = CGPoint(x: rect.minX, y: rect.minY)
        // 좌우 중앙, 위쪽 끝 좌표
        let topPoint = CGPoint(x: rect.midX+5, y: rect.minY)
        // 오른쪽 끝, 위아래 중앙 좌표
        let rightPoint = CGPoint(x: rect.maxX, y: rect.midY-5)
        // 오른쪽 끝, 밑쪽 끝 좌표
        let rightBottomPoint = CGPoint(x: rect.maxX, y: rect.maxY)
        
        // 사다리꼴의 경로를 그립니다
        path.move(to: leftTopPoint)
        path.addLine(to: topPoint)
        path.addLine(to: rightPoint)
        path.addLine(to: rightBottomPoint)
        path.closeSubpath()
        
        return path
    }
}


//struct RibbonShape: Shape {
//    func path(in rect: CGRect) -> Path {
//        var path = Path()
//
//        // 사다리꼴의 좌측 상단 점으로 이동합니다. 이때, 사다리꼴 모양을 만들기 위해 x좌표를 수정합니다.
//           path.move(to: CGPoint(x: rect.minX + rect.width * 0.28, y: rect.minY))
//           // 사다리꼴의 우측 상단 점으로 선을 그립니다. 이때, 사다리꼴 모양을 만들기 위해 x좌표를 수정합니다.
//           path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.27, y: rect.minY))
//           // 사다리꼴의 우측 하단 점으로 선을 그립니다.
//           path.addLine(to: CGPoint(x: rect.maxX , y: rect.maxY))
//           // 사다리꼴의 좌측 하단 점으로 선을 그립니다.
//           path.addLine(to: CGPoint(x: rect.minX , y: rect.maxY))
//           // 사다리꼴의 좌측 상단 점으로 돌아가 도형을 완성합니다.
//           path.closeSubpath()
//
//        return path
//    }
//}

