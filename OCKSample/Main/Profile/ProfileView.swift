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
import os.log

struct ProfileView: View {
    @StateObject var viewModel = ProfileViewModel()
    @ObservedObject var loginViewModel: LoginViewModel
    @CareStoreFetchRequest(query: OCKPatientQuery(for: Date())) private var patients

    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                TextField("First Name",
                          text: $viewModel.firstName)
                    .padding()
                    .cornerRadius(20.0)
                    .shadow(radius: 10.0, x: 20, y: 10)

                TextField("Last Name",
                          text: $viewModel.lastName)
                    .padding()
                    .cornerRadius(20.0)
                    .shadow(radius: 10.0, x: 20, y: 10)

                DatePicker("Birthday",
                           selection: $viewModel.birthday,
                           displayedComponents: [DatePickerComponents.date])
                    .padding()
                    .cornerRadius(20.0)
                    .shadow(radius: 10.0, x: 20, y: 10)
            }

            Button(action: {
                Task {
                    do {
                        try await viewModel.saveProfile()
                    } catch {
                        Logger.profile.error("Error saving profile: \(error)")
                    }
                }
            }, label: {
                Text("Save Profile")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 300, height: 50)
            })
            .background(Color(.green))
            .cornerRadius(15)

            // Notice that "action" is a closure (which is essentially
            // a function as argument like we discussed in class)
            Button(action: {
                Task {
                    await loginViewModel.logout()
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
        }
        .onReceive(patients.publisher) { publishedPatient in
            viewModel.updatePatient(publishedPatient.result)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(viewModel: .init(),
                    loginViewModel: .init())
            .accentColor(Color(TintColorKey.defaultValue))
            .environment(\.careStore, Utility.createPreviewStore())
    }
}
