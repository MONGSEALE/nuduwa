//
//  BlockListView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/06/02.
//

import SwiftUI

struct BlockListView: View {
    @StateObject var viewModel: ProfileViewModel = .init()
    
    var body: some View {
        List{
            ForEach(viewModel.blockList) { list in
                BlockCardView(block: list) { id in
                    viewModel.fetchBlockList()
                }
            }
        }
        .onAppear{
            viewModel.fetchBlockList()
        }
    }
}

struct BlockCardView: View {
    @StateObject var viewModel: ProfileViewModel = .init()
    let block: Block

    var unBlock: (String?)->()
    
    var body: some View {
        HStack{
            Text(viewModel.user?.userName ?? "")
            Spacer()
            Button{
                viewModel.unBlockUser(block.id)
                unBlock(block.id)
            } label: {
                Text("차단해제")
            }
        }
        .onAppear{
            viewModel.fetchUser(block.blockUID)
        }
    }
}
