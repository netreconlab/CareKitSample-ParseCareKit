//
//  ProfileView.swift
//  OCKSample
//
//  Created by Corey Baker on 11/24/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI
import CareKitUI
import CareKitStore
import CareKit

struct ProfileView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var profileViewModel = Profile()
    @State private var isLoggedOut = false
    @State var firstName = ""
    @State var lastName = ""
    @State var birthday = Calendar.current.date(byAdding: .year, value: -20, to: Date())!
    
    var body: some View {
        
        VStack {
            VStack(alignment: .leading) {
                TextField("First Name", text: $firstName)
                    .padding()
                    .cornerRadius(20.0)
                    .shadow(radius: 10.0, x: 20, y: 10)
            
                TextField("Last Name", text: $lastName)
                    .padding()
                    .cornerRadius(20.0)
                    .shadow(radius: 10.0, x: 20, y: 10)
                
                DatePicker("Birthday", selection: $birthday, displayedComponents: [DatePickerComponents.date])
                    .padding()
                    .cornerRadius(20.0)
                    .shadow(radius: 10.0, x: 20, y: 10)
            }
            
            //Notice that "action" is a closure (which is essentially a function as argument like we discussed in class)
            Button(action: {

                profileViewModel.saveProfile(firstName, last: lastName, birth: birthday)

            }, label: {
                
                Text("Save Profile")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 300, height: 50)
            })
            .background(Color(.green))
            .cornerRadius(15)
            
            if #available(iOS 14.0, *) {
                
                //Notice that "action" is a closure (which is essentially a function as argument like we discussed in class)
                Button(action: {
                    do {
                        try profileViewModel.logout()
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
                        try profileViewModel.logout()
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
        }.onReceive(profileViewModel.$patient, perform: { patient in
            if let currentFirstName = patient?.name.givenName {
                firstName = currentFirstName
            }
            
            if let currentLastName = patient?.name.familyName {
                lastName = currentLastName
            }
            
            if let currentBirthday = patient?.birthday {
                birthday = currentBirthday
            }
        })
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
