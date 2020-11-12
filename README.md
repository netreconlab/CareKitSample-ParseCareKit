# CareKitSample+ParseCareKit
![Swift](https://img.shields.io/badge/swift-5.3-brightgreen.svg) ![Xcode 12.0+](https://img.shields.io/badge/xcode-12.0%2B-blue.svg) ![iOS 13.0+](https://img.shields.io/badge/iOS-13.0%2B-blue.svg) ![watchOS 7.0+](https://img.shields.io/badge/watchOS-7.0%2B-blue.svg) ![CareKit 7.0+](https://img.shields.io/badge/CareKit-2.1%2B-red.svg)

An example application of [CareKit](https://github.com/carekit-apple/CareKit)'s OCKSample synchronizing with [ParseCareKit](https://github.com/netreconlab/ParseCareKit/tree/parse-objc). 

***NEW - Just like the [What's New in CareKit](https://developer.apple.com/videos/play/wwdc2020/10151/) WWDC20 video, this app syncs between the AppleWatch (setting the flag in `ExtensionDelegate.swift` and `AppDelegate.swift` to  `syncWithCloud = false`. Different from the video, setting `syncWithCloud = true` (default behavior) in the aforementioned files syncs iOS and watchOS to a Parse Server.***

This branch uses a cocoapod version of CareKit that mirrors the CareKit main branch. The differences between the pod branch and CareKits main branch can be seen [here](https://github.com/carekit-apple/CareKit/compare/main...cbaker6:pod).

The following CareKit Entities are synchronized with Parse tables/classes:
- [x] OCKPatient <-> Patient
- [x] OCKCarePlan <-> CarePlan
- [x] OCKTask <-> Task
- [x] OCKContact <-> Contact
- [x] OCKOutcome <-> Outcome
- [x] OCKOutcomeValue <-> OutcomeValue
- [x] OCKScheduleElement <-> ScheduleElement
- [x] OCKNote <-> Note
- [x] OCKRevisionRecord.KnowledgeVector <-> Clock

**Use at your own risk. There is no promise that this is HIPAA compliant and we are not responsible for any mishandling of your data**

## Setup Your Parse Server
You can setup your parse-server locally to test using [parse-hipaa](https://github.com/netreconlab/parse-hipaa). Simply type the following to get your parse-server running with postgres locally:

1. Fork [parse-hipaa](https://github.com/netreconlab/parse-hipaa/tree/parse-obj-sdk)(be sure to use the `parse-obj-sdk`)
2. `cd parse-hipaa`
3.  `docker-compose up` - this will take a couple of minutes to setup as it needs to initialize postgres, but as soon as you see `parse-server running on port 1337.`, it's ready to go. See [here](https://github.com/netreconlab/parse-hipaa#getting-started) for details
4. If you would like to use mongo instead of postgres, in step 3, type `docker-compose -f docker-compose.mongo.yml up` instead of `docker-compose up`

## Fork this repo to get the modified OCKSample app. 

1. Fork [CareKitSample-ParseCareKit](https://github.com/netreconlab/CareKitSample-ParseCareKit/tree/parse-objc) (Be sure to use the `parse-objc` branch.)
2. Open `OCKSample.xcodeproj` in Xcode
3. You may need to configure your "Team" and "Bundle Identifier" in "Signing and Capabilities"
4. Run the app and data will synchronize with parse-hipaa via http://localhost:1337/parse automatically
5. You can edit Parse server setup in the ParseCareKit.plist file under "Supporting Filles" in the Xcode browser

## View your data in Parse Dashboard
Parse Dashboard is the easiest way to view your data in the Cloud (or local machine in this example) and comes with [parse-hipaa](https://github.com/netreconlab/parse-hipaa/tree/parse-obj-sdk). To access:
1. Open your browser and go to http://localhost:4040/dashboard
2. Username: `parse`
3. Password: `1234`
4. Be sure to refresh your browser to see new changes synched from your CareKitSample app

Note that CareKit data is extremely sensitive and you are responsible for ensuring your parse-server meets HIPAA compliance.

## Transitioning the sample app to a production app
If you plan on using this app as a starting point for your produciton app. Once you have your parse-hipaa server in the Cloud behind ssl, you should open `ParseCareKit.plist` in Xcode and change the value for `Server` to point to your server(s) in the Cloud. You should also open `Info.plist` in Xcode and remove `App Transport Security Settings` and any key/value pairs under it as this was only in place to allow you to test the sample app to connect to a server setup on your local machine. iOS apps don't allow non-ssl connections in production, and even if you find a way to connect to non-ssl servers, it wouldn't be HIPAA compliant.

### Extra scripts for optimized Cloud queries
You should run the extra scripts outlined on parse-hipaa [here](https://github.com/netreconlab/parse-hipaa/tree/parse-obj-sdk#running-in-production-for-parsecarekit).
