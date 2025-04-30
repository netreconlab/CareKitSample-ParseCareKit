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
			ForEach(patients.latest) { patient in
				if let patient = patient.result as? OCKPatient {
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
						}
						.padding()
					}
				}
			}
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
	}

	static func query() -> OCKPatientQuery {
		OCKPatientQuery(for: Date())
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
		do {
			try await User.logout()
		} catch {
			Logger.profile.error("Error logging out: \(error)")
		}
		AppDelegateKey.defaultValue?.resetAppToInitialState()
		PCKUtility.removeCache()
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
