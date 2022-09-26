//
//  LoginView.swift
//  OCKSample
//
//  Created by Corey Baker on 10/29/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

/*
 This is a variation of the tutorial found here:
 https://www.iosapptemplates.com/blog/swiftui/login-screen-swiftui
 */

import SwiftUI
import ParseSwift
import UIKit

/*
 Anything is @ is a wrapper that subscribes and refreshes
 the view when a change occurs. List to the last lecture
 in Section 2 for an explanation
 */
struct LoginView: View {
    @Environment(\.tintColor) var tintColor
    @Environment(\.tintColorFlip) var tintColorFlip
    @ObservedObject var viewModel: LoginViewModel
    @State var usersname = ""
    @State var password = ""
    @State var firstName: String = ""
    @State var lastName: String = ""
    @State var signupLoginSegmentValue = 0

    var body: some View {
        VStack {
            // Change the title to the name of your application
            Text("CareKit Sample App")
                .font(.largeTitle)
                .foregroundColor(.white)
                .padding()
            // Change this image to something that represents your application
            Image("exercise.jpg")
                .resizable()
                .frame(width: 150, height: 150, alignment: .center)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color(.white), lineWidth: 4))
                .shadow(radius: 10)
                .padding()

            /*
             Example of how to do the picker here:
             https://www.swiftkickmobile.com/creating-a-segmented-control-in-swiftui/
             */
            Picker(selection: $signupLoginSegmentValue,
                   label: Text("Login Picker")) {
                Text("Login").tag(0)
                Text("Sign Up").tag(1)
            }
            .pickerStyle(.segmented)
            .background(Color(tintColorFlip))
            .cornerRadius(20.0)
            .padding()

            VStack(alignment: .leading) {
                TextField("Username", text: $usersname)
                    .padding()
                    .background(.white)
                    .cornerRadius(20.0)
                    .shadow(radius: 10.0, x: 20, y: 10)
                SecureField("Password", text: $password)
                    .padding()
                    .background(.white)
                    .cornerRadius(20.0)
                    .shadow(radius: 10.0, x: 20, y: 10)

                switch signupLoginSegmentValue {
                case 1:
                    TextField("First Name", text: $firstName)
                        .padding()
                        .background(.white)
                        .cornerRadius(20.0)
                        .shadow(radius: 10.0, x: 20, y: 10)

                    TextField("Last Name", text: $lastName)
                        .padding()
                        .background(.white)
                        .cornerRadius(20.0)
                        .shadow(radius: 10.0, x: 20, y: 10)
                default:
                    EmptyView()
                }
            }.padding()

            /*
             Notice that "action" and "label" are closures
             (which is essentially afunction as argument
             like we discussed in class)
             */
            Button(action: {
                switch signupLoginSegmentValue {
                case 1:
                    Task {
                        await viewModel.signup(.patient,
                                               username: usersname,
                                               password: password,
                                               firstName: firstName,
                                               lastName: lastName)
                    }
                default:
                    Task {
                        await viewModel.login(username: usersname,
                                              password: password)
                    }
                }
            }, label: {
                switch signupLoginSegmentValue {
                case 1:
                    Text("Sign Up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 300)
                default:
                    Text("Login")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 300)
                }
            })
            .background(Color(.green))
            .cornerRadius(15)

            Button(action: {
                Task {
                    await viewModel.loginAnonymously()
                }
            }, label: {
                switch signupLoginSegmentValue {
                case 0:
                    Text("Login Anonymously")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 300)
                default:
                    EmptyView()
                }
            })
            .background(Color(.lightGray))
            .cornerRadius(15)

            // If an error occurs show it on the screen
            if let error = viewModel.loginError {
                Text("Error: \(error.message)")
                    .foregroundColor(.red)
            }
            Spacer()
        }
        .background(LinearGradient(gradient: Gradient(colors: [Color(tintColorFlip),
                                                               Color(tintColor)]),
                                   startPoint: .top,
                                   endPoint: .bottom))
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(viewModel: .init())
            .accentColor(Color(TintColorKey.defaultValue))
    }
}
