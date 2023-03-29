//
//  PostCardView.swift
//  Nudowa
//
//  Created by DaelimCI00007 on 2023/03/28.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseStorage

struct PostCardView: View {
    var post: Post
    /// - Callbacks
    var onUpdate: (Post)->()
    var onDelete: ()->()
    /// - View
    @State private var docListner: ListenerRegistration?
    
    var body: some View {
        HStack(alignment: .top, spacing: 12){
            WebImage(url: post.userImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 35, height: 35)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6){
                Text(post.userName)
                    .font(.callout)
                    .fontWeight(.semibold)
                Text(post.publishedDate.formatted(date: .numeric, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text(post.text)
                    .textSelection(.enabled)
                    .padding(.vertical,8)
                
                if let postImageURL = post.imageURL{
                    GeometryReader{
                        let size = $0.size
                        WebImage(url: postImageURL)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .frame(height: 200)
                }
            }
        }
        .hAlign(.leading)
        .onAppear {
            /// - Adding Only Once
            if docListner == nil{
                
            }
        }
    }
}
