//
//  ProfileViewModel.swift
//  OCKSample
//
//  Created by Corey Baker on 11/25/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import CareKit
import CareKitStore
import SwiftUI

class ProfileViewModel: ObservableObject {
    
    @Published private(set) var manager: OCKSynchronizedStoreManager
    @Published private(set) var patient: OCKPatient? = nil {
        willSet {
            objectWillChange.send()
        }
    }
    
    var firstName: String {
        guard let name = patient?.name.givenName else {
            return ""
        }
        return name
    }
    
    var lastName: String {
        guard let name = patient?.name.familyName else {
            return ""
        }
        return name
    }
    
    var birthday: Date {
        guard let birthday = patient?.birthday else {
            return Calendar.current.date(byAdding: .year, value: -20, to: Date())!
        }
        return birthday
    }
    
    init(synchronizedStoreManager: OCKSynchronizedStoreManager) {
        manager = synchronizedStoreManager
        
        //Find this patient
        findCurrentPatient { foundPatient in
            self.patient = foundPatient
        }
    }
    
    private func findCurrentPatient(completion: @escaping (OCKPatient?)-> Void) {
        guard let remoteUUID = UserDefaults.standard.object(forKey: "remoteUUID") as? String else {
            print("Error: The user currently isn't logged in")
            return
        }
        
        //Build query to search for OCKPatient
        var queryForCurrentPatient = OCKPatientQuery(for: Date()) //This makes the query for the current version of Patient
        queryForCurrentPatient.ids = [remoteUUID] //Search for the current logged in user
        
        manager.store.fetchAnyPatients(query: queryForCurrentPatient, callbackQueue: .main) { result in
            switch result {
            
            case .success(let foundPatient):
                guard let currentPatient = foundPatient.first as? OCKPatient else {
                    completion(nil)
                    return
                }
                completion(currentPatient)
                
            case .failure(let error):
                print("Error: Couldn't find patient with id \"\(remoteUUID)\". It's possible they have never been saved. Query error: \(error)")
                completion(nil)
            }
        }
    }
    
    //Mark: User intentions
    
    func savePatient(_ first: String, last: String, birth: Date) {
        
        if var patientToUpdate = patient {
            //If there is a currentPatient that was fetched, check to see if any of the fields changed
            
            var patientHasBeenUpdated = false
            
            if firstName != first {
                patientHasBeenUpdated = true
                patientToUpdate.name.givenName = first
            }
            
            if lastName != last {
                patientHasBeenUpdated = true
                patientToUpdate.name.familyName = last
            }
            
            if birthday != birth {
                patientHasBeenUpdated = true
                patientToUpdate.birthday = birth
            }
            
            if patientHasBeenUpdated {
                manager.store.updateAnyPatient(patientToUpdate, callbackQueue: .main) { result in
                    switch result {
                    
                    case .success(_):
                        print("Successfully updated patient")
                    case .failure(let error):
                        print("Error updating patient: \(error)")
                    }
                }
            }
            
        } else {
            
            guard let remoteUUID = UserDefaults.standard.object(forKey: "remoteUUID") as? String else {
                print("Error: The user currently isn't logged in")
                return
            }
            
            var newPatient = OCKPatient(id: remoteUUID, givenName: first, familyName: last)
            newPatient.birthday = birth
            
            //This is new patient that has never been saved before
            manager.store.addAnyPatient(newPatient, callbackQueue: .main) { result in
                switch result {
                
                case .success(_):
                    print("Succesffully saved new patient")
                case .failure(let error):
                    print("Error: \(error)")
                }
            }
        }
    }
}
