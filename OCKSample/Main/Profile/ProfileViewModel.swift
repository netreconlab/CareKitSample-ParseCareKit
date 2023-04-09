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

    func saveProfile() async throws {

        guard var patientToUpdate = patient else {
            throw AppError.errorString("The profile is missing the Patient")
        }

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
            _ = try await AppDelegateKey.defaultValue?.store.updatePatient(patientToUpdate)
            Logger.profile.info("Successfully updated patient")
        }
    }

    func updatePatient(_ patient: OCKAnyPatient) {
        guard let patient = patient as? OCKPatient else {
            return
        }
        self.patient = patient
    }
}
