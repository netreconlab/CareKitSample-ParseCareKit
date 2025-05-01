//
//  SplashScreenView.swift
//  OCKSample
//
//  Created by Corey Baker on 4/30/25.
//  Copyright © 2025 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI

struct SplashScreenView: View {
	@State private var isAnimating = false

	var body: some View {
		VStack {
			ZStack {
				backgroundColorGradient
					.edgesIgnoringSafeArea(.all)
					.frame(
						maxWidth: .infinity,
						maxHeight: .infinity
					)
				Image("heart")
					.resizable()
					.scaledToFit()
					.clipShape(.circle)
					.frame(width: 100, height: 100)
					.scaleEffect(isAnimating ? 1.5 : 1.0)
					.onAppear {
						withAnimation(
							.easeInOut(
								duration: 0.5
							)
							.repeatForever(
								autoreverses: true
							)
						) {
							isAnimating = true
						}
					}
			}
		}
		.ignoresSafeArea()
		.background(backgroundColorGradient)
	}

	var careKitLogoColor: Color {
		Color(#colorLiteral(red: 0.9355412722, green: 0.245944649, blue: 0.3403989077, alpha: 1))
	}
	var backgroundColorGradient: LinearGradient {
		LinearGradient(
			gradient: Gradient(
				colors: [
					.white,
					careKitLogoColor.opacity(0.8)
				]
			),
			startPoint: .bottom,
			endPoint: .top
		)
	}
}

struct SplashScreenView_Previews: PreviewProvider {
	static var previews: some View {
		SplashScreenView()
	}
}
