//
//  MemberProfileView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/05/04.
//

import SwiftUI
import SDWebImageSwiftUI

struct MemberProfileView: View {
    let member: Member
    @State var showMessage: Bool = false
    @State var message: String = ""
    @State private var isDMViewPresented: Bool = false
    @State var selectedTab : Int = 2
    let userUID: String
    
    var body: some View {
        ZStack{
            VStack{
                HStack(spacing: 12){
                    WebImage(url: member.memberImage).placeholder{ProgressView()}
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                    
                    Text(member.memberName ?? "")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                        .hAlign(.leading)
                }
                Spacer()
                Button {
                    isDMViewPresented = true
                } label: {
                    Text("1:1 메시지")
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        .background(.blue, in: Capsule())
                }
            }
            if isDMViewPresented {
                DMView(receiverID: member.memberUID,isDMViewPresented: $isDMViewPresented)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.move(edge: .trailing))
                    .animation(.easeInOut(duration: 0.3))
            }
        }
        .padding(30)
    }
}
