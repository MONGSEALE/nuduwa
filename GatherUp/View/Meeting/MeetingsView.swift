//
//  MeetingsView.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/03/17.
//

import SwiftUI

struct MeetingsView: View {
    @Binding var receiverID: String?
    @Binding var showDMView: Bool
    var body: some View {
        ReusableMeetingsView(title: "내 모임",receiverID: $receiverID, showDMView: $showDMView)
    }
}
