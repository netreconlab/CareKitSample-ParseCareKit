//
//  CareSwiftUIView.swift
//  OCKSample
//
//  Created by Corey Baker on 11/24/20.
//  Copyright © 2020 Apple. All rights reserved.
//

// This file embeds a UIKit View Controller inside of a SwiftUI view. I used this tutorial to figure this out https://developer.apple.com/tutorials/swiftui/interfacing-with-uikit

import SwiftUI
import UIKit
import CareKit


struct CareSwiftUIView: UIViewControllerRepresentable {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    func makeUIViewController(context: Context) -> some UIViewController {
        
        //The code below is setupTabBarController from SceneDelegate.swift
        let manager = self.appDelegate.synchronizedStoreManager!
        let care = CareViewController(storeManager: manager)
        let careViewController = UINavigationController(rootViewController: care)
        
        return careViewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}

struct CareSwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        CareSwiftUIView()
    }
}
