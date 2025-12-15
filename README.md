# CareKitSample+ParseCareKit
![Swift](https://img.shields.io/badge/swift-6.1-brightgreen.svg) ![Xcode 16.0+](https://img.shields.io/badge/xcode-16.0%2B-blue.svg) ![iOS 18.0+](https://img.shields.io/badge/iOS-18.0%2B-blue.svg) ![watchOS 11.0+](https://img.shields.io/badge/watchOS-11.0%2B-blue.svg) ![visionOS 2.4+](https://img.shields.io/badge/visionOS-2.4%2B-blue.svg) ![CareKit 4.0+](https://img.shields.io/badge/CareKit-4.0%2B-red.svg) [![ci](https://github.com/netreconlab/CareKitSample-ParseCareKit/actions/workflows/ci.yml/badge.svg)](https://github.com/netreconlab/CareKitSample-ParseCareKit/actions/workflows/ci.yml)

An example application of [CareKit](https://github.com/carekit-apple/CareKit)'s OCKSample synchronizing CareKit data to the Cloud via [ParseCareKit](https://github.com/netreconlab/ParseCareKit). This project also depends on [CareKitEssentials](https://github.com/netreconlab/CareKitEssentials), which adds several cards and extensions for easier development with CareKit.

<img src="https://github.com/netreconlab/CareKitSample-ParseCareKit/assets/8621344/4e57796b-5c81-474d-bd8d-dfd9f18327e3" width="300"> <img src="https://github.com/netreconlab/CareKitSample-ParseCareKit/assets/8621344/d60d194a-87a5-41e9-8ae4-41a847e91ea3" width="300"> <img src="https://github.com/netreconlab/CareKitSample-ParseCareKit/assets/8621344/ca0ac2e0-d17d-4bae-88fd-f59b94812419" width="300"><img src="https://github.com/netreconlab/CareKitSample-ParseCareKit/assets/8621344/3be47269-cfde-4de2-94ae-25a60f06cac9" width="300">
<img src="https://github.com/user-attachments/assets/873c97a9-006d-4edf-a675-ffb1baeb29c8" width="600">

**Similar to the [What's New in CareKit](https://developer.apple.com/videos/play/wwdc2020/10151/) WWDC20 video, this app syncs data between iOS and an Apple Watch (setting the flag `isSyncingWithRemote` in `Constants.swift` to `isSyncingWithRemote = false.` Different from the video, setting `isSyncingWithRemote = true` (default behavior) in the aforementioned file syncs iOS and watchOS to a Parse Server.**

**If you want to populate random sample OCKOutcomes for events in the past, for example to view data in the InsightsView when testing, set 
`daysInThePastToGenerateSampleData` to a negative number in `Constants.swift`.**

ParseCareKit synchronizes the following entities to Parse tables/classes using [Parse-Swift](https://github.com/netreconlab/Parse-Swift):

- [x] OCKPatient <-> Patient
- [x] OCKCarePlan <-> CarePlan
- [x] OCKContact <-> Contact
- [x] OCKTask <-> Task
- [x] OCKHealthKitTask <-> HealthKitTask 
- [x] OCKOutcome <-> Outcome
- [x] OCKRevisionRecord <-> RevisionRecord

**Use at your own risk. There is no promise that this is HIPAA compliant and we are not responsible for any mishandling of your data**

## Setup Your Parse Server

### Heroku
The easiest way to setup your server is using the [one-button-click](https://github.com/netreconlab/parse-hipaa#heroku) deployment method for [parse-hipaa](https://github.com/netreconlab/parse-hipaa).

### Docker
You can setup your [parse-hipaa](https://github.com/netreconlab/parse-hipaa) using Docker. Simply type the following to get parse-hipaa running with postgres locally:

1. Fork [parse-hipaa](https://github.com/netreconlab/parse-hipaa)
2. `cd parse-hipaa`
3.  `docker-compose up` - this will take a couple of minutes to setup as it needs to initialize postgres, but as soon as you see `parse-server running on port 1337.`, it's ready to go. See [here](https://github.com/netreconlab/parse-hipaa#getting-started) for details
4. If you would like to use mongo instead of postgres, in step 3, type `docker-compose -f docker-compose.mongo.yml up` instead of `docker-compose up`

## Fork this repo to get the modified OCKSample app

1. Fork [CareKitSample-ParseCareKit](https://github.com/netreconlab/CareKitSample-ParseCareKit)
2. Open `OCKSample.xcodeproj` in Xcode
3. You may need to configure your "Team" and "Bundle Identifier" in "Signing and Capabilities"
4. Run the app and data will synchronize with parse-hipaa via http://localhost:1337/parse automatically
5. You can edit Parse server setup in the ParseCareKit.plist file under "Supporting Files" in the Xcode browser

## View your data in Parse Dashboard

### Heroku
The easiest way to setup your dashboard is using the [one-button-click](https://github.com/netreconlab/parse-hipaa-dashboard#heroku) deployment method for [parse-hipaa-dashboard](https://github.com/netreconlab/parse-hipaa-dashboard).

### Docker
Parse Dashboard is the easiest way to view your data in the Cloud (or local machine in this example) and comes with [parse-hipaa](https://github.com/netreconlab/parse-hipaa). To access:
1. Open your browser and go to http://localhost:4040/dashboard
2. Username: `parse`
3. Password: `1234`
4. Be sure to refresh your browser to see new changes synched from your CareKitSample app

Note that CareKit data is extremely sensitive and you are responsible for ensuring your parse-server meets HIPAA compliance.

## Transitioning the sample app to a production app
If you plan on using this app as a starting point for your produciton app. Once you have your parse-hipaa server in the Cloud behind ssl, you should open `ParseCareKit.plist` in Xcode and change the value for `Server` to point to your server(s) in the Cloud. You should also open `Info.plist` in Xcode and remove `App Transport Security Settings` and any key/value pairs under it as this was only in place to allow you to test the sample app to connect to a server setup on your local machine. iOS apps do not allow non-ssl connections in production, and even if you find a way to connect to non-ssl servers, it would not be HIPAA compliant.

### Extra scripts for optimized Cloud queries
You should run the extra scripts outlined on parse-hipaa [here](https://github.com/netreconlab/parse-hipaa#running-in-production-for-parsecarekit).
