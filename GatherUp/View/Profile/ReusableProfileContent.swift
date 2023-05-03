//
//  ReusableProfileContent.swift
//  Nudowa
//
//  Created by DaelimCI00007 on 2023/03/28.
//

import SwiftUI
import SDWebImageSwiftUI

struct ReusableProfileContent: View {
    var user: User
    var body: some View {
        NavigationView{
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack{
                    HStack(spacing: 12){
                        WebImage(url: user.userImage).placeholder{
                            // MARK: Placeholder Image
                            Image("NullProfile")
                                .resizable()
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 6){
                            Text(user.userName)
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text(user.userEmail ?? "")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(3)
                        }
                        .hAlign(.leading)
                    }
                    HStack{
                        VStack{
                            Text("172")
                                .font(.title)
                                .font(.system(size:17))
                                .fontWeight(.bold)
                            Text("만든 모임")
                                .font(.system(size:15))
                                .fontWeight(.light)
                                .foregroundColor(.gray)
                        }
                        VStack{
                            Text("15")
                                .font(.title)
                                .font(.system(size:17))
                                .fontWeight(.bold)
                            Text("친구 목록")
                                .font(.system(size:15))
                                .fontWeight(.light)
                                .foregroundColor(.gray)
                        }
                        VStack{
                            
                        }
                    }
                }
                .padding(15)
            }
        }
    }
}


