//
//  LoginView.swift
//  OCKSample
//
//  Created by Corey Baker on 10/29/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import SwiftUI

struct LoginView: View {
    
    @State var usersname = ""
    @State var password = ""
    
    var body: some View {
        VStack(content: {
            Text("CareKit Sample App")
                .font(.largeTitle).foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                .padding([.top, .bottom], 40)
            VStack {
                TextField("Username", text: $usersname)
                SecureField("Password", text: $password)
            }
        })
    }
}







struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
