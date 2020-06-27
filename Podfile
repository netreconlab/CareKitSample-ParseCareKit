def shared_pods
  # All of these are required to run ParseCareKit
  pod 'CareKitUI', :git => 'https://github.com/cbaker6/CareKit.git', :branch => 'pod-2.1'
  pod 'CareKitStore', :git => 'https://github.com/cbaker6/CareKit.git', :branch => 'pod-2.1'
  pod 'CareKit', :git => 'https://github.com/cbaker6/CareKit.git', :branch => 'pod-2.1'
  pod 'ParseCareKit', :git => 'https://github.com/netreconlab/ParseCareKit.git', :branch => 'main'
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
    platform :watchos, '6.0'
    # Comment the next line if you don't want to use dynamic frameworks
    use_frameworks!
    
    shared_pods
end
