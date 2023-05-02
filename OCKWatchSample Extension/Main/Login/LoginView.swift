//
//  LoginView.swift
//  OCKWatchSample
//
//  Created by Corey Baker on 9/23/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: LoginViewModel

    var body: some View {
        Text("Please open the OCKSample app on your iPhone")
            .multilineTextAlignment(.center)
            .padding()
        Image(systemName: "apps.iphone")
            .resizable()
            .frame(width: 50, height: 50.0)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(viewModel: .init())
            .accentColor(Color(TintColorKey.defaultValue))
    }
}
