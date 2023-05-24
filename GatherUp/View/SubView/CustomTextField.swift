//
//  CustomTextField.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/04/07.
//

import SwiftUI

struct CustomTextField: View {
    var text: String
    @Binding var editText: String
    @FocusState var isEnabled: Bool
    //var contnetType: UITextContentType =
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            TextField(text, text: $editText)
                .focused($isEnabled)
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.black.opacity(0.2))
                
                Rectangle()
                    .fill(.black)
                    .frame(width: isEnabled ? nil : 0, alignment: .leading)
                    .animation(.easeInOut(duration: 0.3), value: isEnabled)
            }
            .frame(height: 2)
        }
    }
}
