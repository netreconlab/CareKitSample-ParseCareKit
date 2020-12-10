//
//  ContentView.swift
//  OCKWatchSample Extension
//
//  Created by Corey Baker on 6/25/20.
//  Copyright © 2020 Apple. All rights reserved.
//
import CareKit
import CareKitStore
import SwiftUI

class LoginViewModel: ObservableObject {
    
    private let watchDelegate = WKExtension.shared().delegate as! ExtensionDelegate
    
    var storeManager: OCKSynchronizedStoreManager {
        return watchDelegate.storeManager
    }
    
    var isLoggedIn = false {
        willSet {
            objectWillChange.send()
        }
    }
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(loginChanged(_:)), name: Notification.Name(rawValue: Constants.userLoggedIn), object: nil)
    }
    
    @objc private func loginChanged(_ notification: Notification) {
        isLoggedIn = true
    }
    
}

struct ContentView: View {

    @ObservedObject var loginViewModel = LoginViewModel()
    
    var body: some View {
        
        ScrollView {
            
            if loginViewModel.isLoggedIn {

                InstructionsTaskView(taskID: "stretch", eventQuery: OCKEventQuery(for: Date()), storeManager: loginViewModel.storeManager)
                
                SimpleTaskView(taskID: "kegels", eventQuery: OCKEventQuery(for: Date()), storeManager: loginViewModel.storeManager){ controller in
                    
                    .init(title: Text(controller.viewModel?.title ?? ""), detail: nil, isComplete: controller.viewModel?.isComplete ?? false, action: controller.viewModel?.action ?? {})
                }
            
            } else {
                Text("Please open the OCKSample app on your iPhone and login")
                    .multilineTextAlignment(.center)
                    .padding()
                Image(systemName: "apps.iphone")
                    .resizable()
                    .frame(width: 50, height: 50.0)
            }
            
        }.accentColor(Color(#colorLiteral(red: 0.8310135007, green: 0.8244097233, blue: 0.8242591023, alpha: 1)))
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
