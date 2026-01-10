//
//  ProfileView.swift
//  OCKSample
//
//  Created by Corey Baker on 4/15/25.
//  Copyright © 2025 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitStore
import CareKitUI
import os.log
import ParseCareKit
import ParseSwift
import SwiftUI

struct ProfileView: View {
	@CareStoreFetchRequest(query: query()) private var patients
	@State private var isLoggedOut = false

	var body: some View {
		ScrollView {
			// Assumes app only supports 1 patient.
			if let patient = patients.latest.last?.result as? OCKPatient {
				CardView {
					VStack {
						HStack {
							Image(systemName: "person.crop.circle")
								.resizable()
								.aspectRatio(contentMode: .fit)
								.frame(width: 50, height: 50, alignment: .center)
								.clipShape(Circle())
								.shadow(radius: 10)
								.overlay(Circle().stroke(Color.accentColor, lineWidth: 5))
							Spacer()
							Group {
								VStack {
									Text(name(patient.name))
										.multilineTextAlignment(.leading)
										.font(.headline)
									Text("ID: \(patient.uuid)")
										.multilineTextAlignment(.leading)
										.font(.footnote)
								}
							}
						}
						Divider()
							.background(Color.accentColor)
							.padding(.bottom)
						Spacer()
						logoutButton
					}
					.padding()
				}
			} else {
				logoutButton
			}
		}
	}

	static func query() -> OCKPatientQuery {
		OCKPatientQuery(for: Date())
	}

	private var logoutButton: some View {
		Button(action: {
			Task {
				do {
					try await logout()
				} catch {
					Logger.profile.error("Error logging out: \(error)")
				}
			}
		}) {
			RectangularCompletionView(isComplete: isLoggedOut) {
				Spacer()
				Text("LOG_OUT")
					.foregroundColor(.white)
					.frame(maxWidth: .infinity)
					.padding()
				Spacer()
			}
		}
		.background(Color.accentColor)
		.buttonStyle(NoHighlightStyle())
	}

	private func name(_ nameComponents: PersonNameComponents) -> String {
		var currentName = ""
		if let firstName = nameComponents.givenName {
			currentName = firstName
		}
		if let lastName = nameComponents.familyName {
			if currentName != "" {
				currentName += " \(lastName)"
			} else {
				currentName = lastName
			}
		}
		return currentName
	}

	private func logout() async throws {
		await Utility.logoutAndResetAppState()
		isLoggedOut = true
	}
}

struct ProfileView_Previews: PreviewProvider {
	static var previews: some View {
		ProfileView()
			.environment(\.careStore, Utility.createPreviewStore())
			.careKitStyle(Styler())
	}
}
