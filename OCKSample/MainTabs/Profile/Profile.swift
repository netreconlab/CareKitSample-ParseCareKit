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
import SwiftUI
import ParseCareKit
import UIKit

class Profile: ObservableObject {
    
    @Published var patient: OCKPatient? = nil
    
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate //Importing UIKit gives us access here to get the OCKStore and ParseRemote
    
    init() {
        
        //Find this patient
        findCurrentProfile { foundPatient in
            self.patient = foundPatient
        }
    }
    
    private func findCurrentProfile(completion: @escaping (OCKPatient?)-> Void) {
        
        guard let uuid = getRemoteClockUUIDAfterLoginFromLocalStorage() else {
            completion(nil)
            return
        }

        //Build query to search for OCKPatient
        var queryForCurrentPatient = OCKPatientQuery(for: Date()) //This makes the query for the current version of Patient
        queryForCurrentPatient.ids = [uuid.uuidString] //Search for the current logged in user
        
        self.appDelegate.synchronizedStoreManager?.store.fetchAnyPatients(query: queryForCurrentPatient, callbackQueue: .main) { result in
            switch result {
            
            case .success(let foundPatient):
                guard let currentPatient = foundPatient.first as? OCKPatient else {
                    completion(nil)
                    return
                }
                completion(currentPatient)
                
            case .failure(let error):
                print("Error: Couldn't find patient with id \"\(uuid)\". It's possible they have never been saved. Query error: \(error)")
                completion(nil)
            }
        }
    }
    
    //Mark: User intentions
    
    func saveProfile(_ first: String, last: String, birth: Date) {
        
        if var patientToUpdate = patient {
            //If there is a currentPatient that was fetched, check to see if any of the fields changed
            
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
                appDelegate.synchronizedStoreManager?.store.updateAnyPatient(patientToUpdate, callbackQueue: .main) { result in
                    switch result {
                    
                    case .success(let updated):
                        print("Successfully updated patient")
                        guard let updatedPatient = updated as? OCKPatient else {
                            return
                        }
                        self.patient = updatedPatient
                    case .failure(let error):
                        print("Error updating patient: \(error)")
                    }
                }
            }
            
        } else {
            
            guard let remoteUUID = UserDefaults.standard.object(forKey: Constants.parseRemoteClockIDKey) as? String else {
                print("Error: The user currently isn't logged in")
                return
            }
            
            var newPatient = OCKPatient(id: remoteUUID, givenName: first, familyName: last)
            newPatient.birthday = birth
            
            //This is new patient that has never been saved before
            appDelegate.synchronizedStoreManager?.store.addAnyPatient(newPatient, callbackQueue: .main) { result in
                switch result {
                
                case .success(let new):
                    print("Succesffully saved new patient")
                    guard let newPatient = new as? OCKPatient else {
                        return
                    }
                    self.patient = newPatient
                case .failure(let error):
                    print("Error: \(error)")
                }
            }
        }
    }
    
    func savePatientAfterSignUp(_ first: String, last: String, completion: @escaping (Result<OCKPatient,Error>) -> Void) {
        
        let remoteUUID = UUID()
        
        //Because of the app delegate access above, we can place the initial data in the database
        self.appDelegate.setupRemotes(uuid: remoteUUID)
        self.appDelegate.coreDataStore.populateSampleData()
        self.appDelegate.healthKitStore.populateSampleData()
        self.appDelegate.parse.automaticallySynchronizes = true
        self.appDelegate.firstLogin = true
        
        //Post notification to sync
        NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.appDelegate.healthKitStore.requestHealthKitPermissionsForAllTasksInStore { error in

                if error != nil {
                    print(error!.localizedDescription)
                }
            }
        }
        
        //Save remote ID to local
        UserDefaults.standard.setValue(remoteUUID.uuidString, forKey: Constants.parseRemoteClockIDKey)
        UserDefaults.standard.synchronize()
        
        var newPatient = OCKPatient(id: remoteUUID.uuidString, givenName: first, familyName: last)
        newPatient.userInfo = [Constants.parseRemoteClockIDKey: remoteUUID.uuidString] //Save the remoteId String
        
        appDelegate.synchronizedStoreManager?.store.addAnyPatient(newPatient, callbackQueue: .main) { result in
            switch result {
            
            case .success(let savedPatient):
                
                guard let patient = savedPatient as? OCKPatient else {
                    completion(.failure(AppError.couldntCast))
                    return
                }
                self.patient = patient
                
                print("Successfully added a new Patient")
                completion(.success(patient))
            case .failure(let error):
                print("Error added patient: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    func getRemoteClockUUIDAfterLoginFromLocalStorage() -> UUID? {
        guard let uuid = UserDefaults.standard.object(forKey: Constants.parseRemoteClockIDKey) as? String else {
            return nil
        }
        
        return UUID(uuidString: uuid)
    }
    
    func getRemoteClockUUIDAfterLoginFromCloud(completion: @escaping (Result<UUID,Error>) -> Void) {
        
        let query = Patient.query()
        
        query.first(callbackQueue: .main) { result in
            switch result {
            
            case .success(let patient):
                guard let uuid = patient.userInfo?[Constants.parseRemoteClockIDKey],
                      let remoteClockId = UUID(uuidString: uuid) else {
                    completion(.failure(AppError.valueNotFoundInUserInfo))
                    return
                }
                completion(.success(remoteClockId))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func setupRemoteAfterLoginButtonTapped(completion: @escaping (Result<UUID,Error>) -> Void) {
        
        getRemoteClockUUIDAfterLoginFromCloud { result in
            switch result {
            
            case .success(let uuid):
                
                DispatchQueue.main.async {
                    self.appDelegate.setupRemotes(uuid: uuid)
                    self.appDelegate.parse.automaticallySynchronizes = true
                    self.appDelegate.firstLogin = true
                    
                    //Save remote ID to local
                    UserDefaults.standard.setValue(uuid.uuidString, forKey: Constants.parseRemoteClockIDKey)
                    UserDefaults.standard.synchronize()
                    
                    NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.appDelegate.healthKitStore.requestHealthKitPermissionsForAllTasksInStore { error in

                            if error != nil {
                                print(error!.localizedDescription)
                            }
                        }
                    }
                    
                    completion(.success(uuid))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    //You may not have seen "throws" before, but it's simple, this throws an error if one occurs, if not it behaves as normal
    //Normally, you've seen do {} catch{} which catches the error, same concept...
    func logout() throws {
        try User.logout()
        UserDefaults.standard.removeObject(forKey: Constants.parseRemoteClockIDKey)
        UserDefaults.standard.synchronize()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        try appDelegate.healthKitStore.reset()
        try appDelegate.coreDataStore.delete() //Delete data in local OCKStore database
    }
}
