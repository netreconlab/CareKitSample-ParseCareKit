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
    private(set) var storeManager: OCKSynchronizedStoreManager {
        didSet {
            reloadViewModel()
        }
    }

    // MARK: Private read/write properties
    private var cancellables: Set<AnyCancellable> = []

    init(storeManager: OCKSynchronizedStoreManager? = nil) {
        self.storeManager = storeManager ?? StoreManagerKey.defaultValue
    }

    // MARK: Helpers (private)
    private func clearSubscriptions() {
        cancellables = []
    }

    private func reloadViewModel() {
        Task {
            _ = await findAndObserveCurrentProfile()
        }
    }

    func updateStoreManager(_ storeManager: OCKSynchronizedStoreManager? = nil) {
        guard let storeManager = storeManager else {
            guard let appDelegateStoreManager = AppDelegateKey.defaultValue?.storeManager else {
                Logger.profile.error("Missing AppDelegate storeManager")
                return
            }
            self.storeManager = appDelegateStoreManager
            return
        }
        self.storeManager = storeManager
    }

    @MainActor
    private func findAndObserveCurrentProfile() async {
        guard let uuid = try? await Utility.getRemoteClockUUID() else {
            Logger.profile.error("Could not get remote uuid for this user")
            return
        }
        clearSubscriptions()

        // Build query to search for OCKPatient
        // swiftlint:disable:next line_length
        var queryForCurrentPatient = OCKPatientQuery(for: Date()) // This makes the query for the current version of Patient
        queryForCurrentPatient.ids = [uuid.uuidString] // Search for the current logged in user

        do {
            let foundPatient = try await storeManager.store.fetchAnyPatients(query: queryForCurrentPatient)
            guard let currentPatient = foundPatient.first as? OCKPatient else {
                // swiftlint:disable:next line_length
                Logger.profile.error("Could not find patient with id \"\(uuid)\". It's possible they have never been saved")
                return
            }
            self.observePatient(currentPatient)
        } catch {
            // swiftlint:disable:next line_length
            Logger.profile.error("Could not find patient with id \"\(uuid)\". It's possible they have never been saved. Query error: \(error)")
        }
    }

    @MainActor
    private func observePatient(_ patient: OCKPatient) {
        storeManager.publisher(forPatient: patient,
                               categories: [.add, .update, .delete])
            .sink { [weak self] in
                self?.patient = $0 as? OCKPatient
            }
            .store(in: &cancellables)
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
                let updated = try await storeManager.store.updateAnyPatient(patientToUpdate)
                Logger.profile.info("Successfully updated patient")
                guard let updatedPatient = updated as? OCKPatient else {
                    return
                }
                self.patient = updatedPatient
            }

        } else {
            guard let remoteUUID = try? await Utility.getRemoteClockUUID().uuidString else {
                Logger.profile.error("The user currently is not logged in")
                return
            }

            var newPatient = OCKPatient(id: remoteUUID, givenName: first, familyName: last)
            newPatient.birthday = birth

            // This is new patient that has never been saved before
            let addedPatient = try await storeManager.store.addAnyPatient(newPatient)
            Logger.profile.info("Succesffully saved new patient")
            guard let addedOCKPatient = addedPatient as? OCKPatient else {
                Logger.profile.error("Could not cast to OCKPatient")
                return
            }
            self.patient = addedOCKPatient
        }
    }
}
