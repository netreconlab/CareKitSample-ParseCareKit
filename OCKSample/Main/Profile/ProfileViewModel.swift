//
//  Profile.swift
//  OCKSample
//
//  Created by Corey Baker on 11/25/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKit
import CareKitStore
import CareKitUtilities
import SwiftUI
import ParseCareKit
import os.log
import Combine

class ProfileViewModel: ObservableObject {
    // MARK: Public read/write properties
    var firstName = ""
    var lastName = ""
    var birthday = Date()
    var patient: OCKPatient? {
        willSet {
            if let currentFirstName = newValue?.name.givenName {
                firstName = currentFirstName
            }
            if let currentLastName = newValue?.name.familyName {
                lastName = currentLastName
            }
            if let currentBirthday = newValue?.birthday {
                birthday = currentBirthday
            }
        }
    }

    // MARK: User intentional behavior
    @MainActor
    func saveProfile() async throws {

        if var patientToUpdate = patient {
            // If there is a currentPatient that was fetched, check to see if any of the fields changed
            var patientHasBeenUpdated = false

            if patient?.name.givenName != firstName {
                patientHasBeenUpdated = true
                patientToUpdate.name.givenName = firstName
            }

            if patient?.name.familyName != lastName {
                patientHasBeenUpdated = true
                patientToUpdate.name.familyName = lastName
            }

            if patient?.birthday != birthday {
                patientHasBeenUpdated = true
                patientToUpdate.birthday = birthday
            }

            if patientHasBeenUpdated {
                let updated = try await AppDelegateKey.defaultValue?.store.updatePatient(patientToUpdate)
                Logger.profile.info("Successfully updated patient")
                self.patient = updated
            }

        } else {
            guard let remoteUUID = try? await Utility.getRemoteClockUUID().uuidString else {
                Logger.profile.error("The user currently is not logged in")
                return
            }

            var newPatient = OCKPatient(id: remoteUUID,
                                        givenName: firstName,
                                        familyName: lastName)
            newPatient.birthday = birthday

            // This is new patient that has never been saved before
            let addedPatient = try await AppDelegateKey.defaultValue?.store.addPatient(newPatient)
            Logger.profile.info("Succesffully saved new patient")
            self.patient = addedPatient
        }
    }
}
