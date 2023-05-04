//
//  MemberProfileView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/05/04.
//

import SwiftUI
import SDWebImageSwiftUI

struct MemberProfileView: View {
    var member: Members
    @State var showMessage: Bool = false
    @State var message: String = ""
    
    var body: some View {
        ZStack{
            VStack{
                HStack(spacing: 12){
                    WebImage(url: member.memberImage).placeholder{
                        // MARK: Placeholder Image
                        Image("NullProfile")
                            .resizable()
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    
                    Text(member.memberName)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                        .hAlign(.leading)
                }
                Spacer()
                Button {
                    showPopupMessage(message: "친구추가 완료!(미구현)", duration: 3)
                } label: {
                    Text("친구추가")
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding(.horizontal,30)
                        .padding(.vertical,10)
                        .background(.blue,in: Capsule())
                }
            }
            if showMessage{
                ShowMessage(message: message)
            }
        }
        .padding(30)
    }
    
    func showPopupMessage(message: String, duration: TimeInterval) {
        // Show the message
        withAnimation {
            self.message = message
            showMessage = true
        }
        // Hide the message after the specified duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation {
                showMessage = false
                self.message = ""
            }
        }
    }
}
