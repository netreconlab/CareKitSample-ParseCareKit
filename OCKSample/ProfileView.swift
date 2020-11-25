//
//  ProfileView.swift
//  OCKSample
//
//  Created by Corey Baker on 11/24/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import SwiftUI
import CareKitUI

struct ProfileView: View {
    
    @ObservedObject private var viewModel = LoginViewModel()
    @State private var isLoggedOut = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        
        if #available(iOS 14.0, *) {
            
            //Notice that "action" is a closure (which is essentially a function as argument like we discussed in class)
            Button(action: {
                do {
                    try viewModel.logout()
                    isLoggedOut = true
                    presentationMode.wrappedValue.dismiss()
                } catch {
                    print("Error logging out: \(error)")
                }
                
            }, label: {
                
                Text("Log Out")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 300, height: 50)
            })
            .background(Color(.red))
            .cornerRadius(15)
            .fullScreenCover(isPresented: $isLoggedOut, content: {
                LoginView()
            })
        } else {
            // Fallback on earlier versions
            Button(action: {
                do {
                    try viewModel.logout()
                    isLoggedOut = true
                    presentationMode.wrappedValue.dismiss()
                } catch {
                    print("Error logging out: \(error)")
                }
                
            }, label: {
                
                Text("Log Out")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 300, height: 50)
            })
            .background(Color(.red))
            .cornerRadius(15)
            .sheet(isPresented: $isLoggedOut, content: {
                LoginView()
            })
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
