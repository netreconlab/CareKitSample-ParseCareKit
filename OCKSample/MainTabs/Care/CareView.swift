//
//  CareView.swift
//  OCKSample
//
//  Created by Corey Baker on 11/24/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

// This file embeds a UIKit View Controller inside of a SwiftUI view. I used this tutorial to figure this out https://developer.apple.com/tutorials/swiftui/interfacing-with-uikit

import SwiftUI
import UIKit
import CareKit
import os.log

struct CareView: UIViewControllerRepresentable {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    func makeUIViewController(context: Context) -> some UIViewController {
        
        //The code below is setupTabBarController from SceneDelegate.swift
        guard let manager = StoreManagerKey.defaultValue else {
            Logger.feed.error("Couldn't unwrap storeManager")
            return UINavigationController()
        }
        let care = CareViewController(storeManager: manager)
        let careViewController = UINavigationController(rootViewController: care)
        careViewController.navigationBar.backgroundColor = UIColor { $0.userInterfaceStyle == .light ? #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1): #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) }
        
        return careViewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}

struct CareView_Previews: PreviewProvider {
    static var previews: some View {
        CareView()
    }
}
