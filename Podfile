def shared_pods
  # All of these are required to run ParseCareKit
  pod 'CareKitUI', :git => 'https://github.com/cbaker6/CareKit.git', :branch => 'pod'
  pod 'CareKitStore', :git => 'https://github.com/cbaker6/CareKit.git', :branch => 'pod'
  pod 'CareKit', :git => 'https://github.com/cbaker6/CareKit.git', :branch => 'pod'
  pod 'ParseLiveQuery', :git => 'https://github.com/cbaker6/ParseLiveQuery-iOS-OSX.git', :branch => 'latest'
  pod 'ParseCareKit', :git => 'https://github.com/netreconlab/ParseCareKit.git', :branch => 'parse-objc'
end

target 'OCKSample' do
  platform :ios, '13.0'
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  
  shared_pods
end

target 'OCKSampleUITests' do
  platform :ios, '13.0'
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  
  shared_pods
end

target 'OCKWatchSample Extension' do
    platform :watchos, '7.0'
    # Comment the next line if you don't want to use dynamic frameworks
    use_frameworks!
    
    shared_pods
end
