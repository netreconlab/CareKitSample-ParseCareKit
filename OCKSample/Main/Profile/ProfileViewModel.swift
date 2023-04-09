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
    // MARK: Public read, private write properties
    @Published private(set) var patient: OCKPatient?
    private(set) var store: OCKStore {
        didSet {
            reloadViewModel()
        }
    }

    // MARK: Private read/write properties
    private var cancellables: Set<AnyCancellable> = []

    init(store: OCKStore? = nil) {
        self.store = store ?? AppDelegateKey.defaultValue?.store
            ?? .init(name: Constants.noCareStoreName, type: .inMemory)
    }

    // MARK: Helpers (private)

    func updateStore(_ store: OCKStore? = nil) {
        guard let store = store else {
            guard let appDelegateStore = AppDelegateKey.defaultValue?.store else {
                Logger.profile.error("Missing AppDelegate store")
                return
            }
            self.store = appDelegateStore
            return
        }
        self.store = store
    }

    private func reloadViewModel() {
        Task {
            _ = await findAndObserveCurrentProfile()
        }
    }

    @MainActor
    private func findAndObserveCurrentProfile() async {
        guard let uuid = try? await Utility.getRemoteClockUUID() else {
            Logger.profile.error("Could not get remote uuid for this user")
            return
        }

        // Build query to search for OCKPatient
        // swiftlint:disable:next line_length
        var queryForCurrentPatient = OCKPatientQuery(for: Date()) // This makes the query for the current version of Patient
        queryForCurrentPatient.ids = [uuid.uuidString] // Search for the current logged in user

        do {
            var stream = store.patients(matching: queryForCurrentPatient)
            let patients = try await stream.next()
            self.patient = patients?.first
        } catch {
            // swiftlint:disable:next line_length
            Logger.profile.error("Could not find patient with id \"\(uuid)\". It's possible they have never been saved. Query error: \(error)")
        }
    }

    // MARK: User intentional behavior
    @MainActor
    func saveProfile(_ first: String, last: String, birth: Date) async throws {

        if var patientToUpdate = patient {
            // If there is a currentPatient that was fetched, check to see if any of the fields changed
            var patientHasBeenUpdated = false

            if patient?.name.givenName != first {
                patientHasBeenUpdated = true
                patientToUpdate.name.givenName = first
            }

            if patient?.name.familyName != last {
                patientHasBeenUpdated = true
                patientToUpdate.name.familyName = last
            }

            if patient?.birthday != birth {
                patientHasBeenUpdated = true
                patientToUpdate.birthday = birth
            }

            if patientHasBeenUpdated {
                let updated = try await store.updatePatient(patientToUpdate)
                Logger.profile.info("Successfully updated patient")
                self.patient = updated
            }

        } else {
            guard let remoteUUID = try? await Utility.getRemoteClockUUID().uuidString else {
                Logger.profile.error("The user currently is not logged in")
                return
            }

            var newPatient = OCKPatient(id: remoteUUID, givenName: first, familyName: last)
            newPatient.birthday = birth

            // This is new patient that has never been saved before
            let addedPatient = try await store.addPatient(newPatient)
            Logger.profile.info("Succesffully saved new patient")
            self.patient = addedPatient
        }
    }
}
