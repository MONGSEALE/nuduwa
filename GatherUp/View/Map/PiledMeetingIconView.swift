//
//  MeetingIconView.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/04/05.
//

import SwiftUI
import CoreLocation
import SDWebImageSwiftUI


struct PiledMeetingIconView: View {

    // 나중에 이 두개 변수 통합 고려
    @State private var showSheet = false        // 클릭시 시트 보임
    @State var isClicked: Bool = false        // 클릭시 커짐
    
    @Binding var showAnnotation: Bool           // 모임생성할때 아이콘 클릭 안되게
    
    let meetings: [Meeting]                     // 중첩된 모임들
    var onLocate: (CLLocationCoordinate2D)->()  // 클릭시 모임 위치로 지도 옮기기
    
    var body: some View {
        VStack(spacing:0){
            ZStack{
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width:40,height: 40)
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color(.blue))
                    .clipShape(Circle())
                Text("\(meetings.count)")
            }
            
            Image(systemName: "triangle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 15,height: 15)
                .foregroundColor(.blue)
                .rotationEffect(Angle(degrees: 180))
                .offset( y : -3)
                .padding(.bottom , 40)
        }
        .onTapGesture {
            if(showAnnotation==false){
                showSheet = true
                onLocate(CLLocationCoordinate2D(latitude: meetings.last!.latitude, longitude: meetings.last!.longitude))
            }
        }
        .sheet(isPresented: $showSheet){
            PiledMeetingsListView(meetings: meetings)
                .presentationDetents([.fraction((CGFloat(meetings.count)*0.1)+0.03),.height(700)])
                .onAppear{
                    withAnimation(.easeInOut(duration: 0.25)){
                        isClicked = true
                    }
                }
                .onDisappear{
                    withAnimation(.easeInOut(duration: 0.25)){
                        isClicked = false
                    }
                }
        }
        .scaleEffect(isClicked ? 1.7: 1.0)
    }

    
}
struct PiledMeetingsListView: View {
    let meetings: [Meeting]
    
    var body: some View {
        NavigationStack {
            ForEach(meetings) { meeting in
                NavigationLink(value: meeting){
                    PiledMeetingCardView(meeting: meeting)
                }
                Divider()
            }
            .navigationDestination(for: Meeting.self) { meeting in
                MeetingInfoSheetView(meeting: meeting)
                    .navigationBarBackButtonHidden(true)
            }
        }
        .padding(15)
    }
}


