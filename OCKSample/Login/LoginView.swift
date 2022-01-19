//
//  LoginView.swift
//  OCKSample
//
//  Created by Corey Baker on 10/29/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

// This is a variation of the tutorial found here: https://www.iosapptemplates.com/blog/swiftui/login-screen-swiftui

import SwiftUI
import ParseSwift
import UIKit

struct LoginView: View {
    // swiftlint:disable:next line_length
    // Anything is @ is a wrapper that subscribes and refreshes the view when a change occurs. List to the last lecture in Section 2 for an explanation
    @Environment(\.tintColor) private var tintColor
    @Environment(\.userProfileViewModel) private var userProfileViewModel
    @EnvironmentObject var userStatus: UserStatus
    @ObservedObject private var viewModel = LoginViewModel()
    @State private var usersname = ""
    @State private var password = ""
    @State var firstName: String = ""
    @State var lastName: String = ""
    @State private var signupLoginSegmentValue = 0
    @State private var presentMainScreen = false

    var body: some View {

        VStack {

            Text("CareKit Sample App")
                .font(.largeTitle) // These are modifiers of the text view
                .foregroundColor(.white)
                .padding([.top], 40)

            Image("exercise.jpg") // Change this image to something that represents your application
                .resizable()
                .frame(width: 150, height: 150, alignment: .center)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color(.white), lineWidth: 4))
                .shadow(radius: 10)
                .padding()
                .layoutPriority(-100)
            // swiftlint:disable:next line_length
            // Example of how to do the picker here: https://www.swiftkickmobile.com/creating-a-segmented-control-in-swiftui/
            Picker(selection: $signupLoginSegmentValue, label: Text("Login Picker"), content: {
                Text("Login").tag(0)
                Text("Sign Up").tag(1)
            })
            .pickerStyle(SegmentedPickerStyle())
            .background(Color.white)
            .cornerRadius(20.0)
            .padding()

            VStack(alignment: .leading) {
                TextField("Username", text: $usersname)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20.0)
                    .shadow(radius: 10.0, x: 20, y: 10)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20.0)
                    .shadow(radius: 10.0, x: 20, y: 10)

                if signupLoginSegmentValue == 1 {
                    TextField("First Name", text: $firstName)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(20.0)
                        .shadow(radius: 10.0, x: 20, y: 10)

                    TextField("Last Name", text: $lastName)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(20.0)
                        .shadow(radius: 10.0, x: 20, y: 10)

                }
            }.padding([.leading, .trailing], 27.5)
            // swiftlint:disable:next line_length
            // Notice that "action" is a closure (which is essentially a function as argument like we discussed in class)
            Button(action: {

                if signupLoginSegmentValue == 1 {
                    Task {
                        await viewModel.signup(.patient,
                                               username: usersname,
                                               password: password,
                                               firstName: firstName,
                                               lastName: lastName)
                    }
                } else {
                    Task {
                        await viewModel.login(username: usersname,
                                              password: password)
                    }
                }

            }, label: {

                if signupLoginSegmentValue == 1 {
                    Text("Sign Up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 300, height: 50)
                } else {
                    Text("Login")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 300, height: 50)
                }
            })
            .background(Color(.green))
            .cornerRadius(15)

            Button(action: {
                Task {
                    await viewModel.loginAnonymously()
                }
            }, label: {

                if signupLoginSegmentValue == 0 {
                    Text("Login Anonymously")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 300, height: 50)
                }
            })
            .background(Color(.lightGray))
            .cornerRadius(15)
            // If error occurs show it on the screen
            if let error = viewModel.loginError {
                Text("Error: \(error.message)")
                    .foregroundColor(.red)
            }

            Spacer()
        }
        .onReceive(viewModel.$isLoggedOut, perform: { value in
            if self.userStatus.isLoggedOut != value {
                self.userStatus.check()
            }
        })
        .onAppear(perform: {
            UISegmentedControl.appearance().selectedSegmentTintColor = .blue
            UISegmentedControl.appearance().backgroundColor = .lightGray
        })
        .background(LinearGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.06253327429, green: 0.6597633362, blue: 0.8644603491, alpha: 1)),
                                                               Color(#colorLiteral(red: 0, green: 0.2858072221, blue: 0.6897063851, alpha: 1))]),
                                   startPoint: .top,
                                   endPoint: .bottom))
        .edgesIgnoringSafeArea(.all)
        .navigationBarHidden(true)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(UserStatus(isLoggedOut: false))
    }
}
