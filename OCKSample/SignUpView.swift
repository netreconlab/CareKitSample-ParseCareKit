//
//  SignUpView.swift
//  OCKSample
//
//  Created by Corey Baker on 10/29/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import SwiftUI

struct SignUpView: View {
    
    @State private var username = ""
    @State private var password = ""
    
    var body: some View {
        
        VStack(content: {
            Text("CareKit Sample App")
            TextField("Username", text: self.$username)
            TextField("Password", text: self.$password)
        })
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
