//
//  InputView.swift
//  HauteVision
//
//  Created by romi bonomo on 2025-02-10.
//

import SwiftUI

struct InputView: View {
    @Binding var text: String
    let title: String
    let placeholder: String
    var isSecureField = false
    var showToggle = true
    @State private var showPassword = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12){
            Text(title)
                .foregroundColor(Color(.darkGray))
                .fontWeight(.semibold)
                .font(.footnote)
            
            HStack(spacing: 16) {
                Group {
                    if isSecureField && !showPassword {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(.system(size: 14))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        .accessibilityLabel(title)
        .accessibilityValue(text.isEmpty ? "empty".localized() : text)
                
                if isSecureField && showToggle {
                    Button(action: {
                        showPassword.toggle()
                    }) {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.gray)
                            .frame(width: 20, height: 20)
                    }
                    .padding(.trailing, 8)
        .accessibilityLabel(showPassword ? "hide_password".localized() : "show_password".localized())
        .accessibilityHint("double_tap_toggle_password".localized())
                }
            }
            
            Divider()
        }
    }
}

struct InputView_Previews: PreviewProvider{
    static var previews: some View{
        VStack(spacing: 20) {
            InputView(text: .constant(""), title: "Email Address", placeholder: "name@example.com")
            InputView(text: .constant(""), title: "Password", placeholder: "Enter your password", isSecureField: true)
        }
        .padding()
    }
}
