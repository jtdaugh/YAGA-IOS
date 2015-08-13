xcodeproj 'Yaga.xcodeproj'
source 'https://github.com/CocoaPods/Specs.git'

target 'Yaga', :exclusive => true do
    platform :ios, '7.0'
    pod 'Realm', '~> 0.93.2'
    pod 'AFNetworking', '~> 2.0'
    pod 'APAddressBook', '~> 0.0.7'
    pod 'libPhoneNumber-iOS', '~> 0.7'
    pod 'FrameAccessor', '~> 1.0'
    pod 'FLAnimatedImage', :git => 'https://github.com/yagainc/FLAnimatedImage.git'
    pod 'NSDate-Time-Ago', :inhibit_warnings => true
    pod 'SVPullToRefresh'
    pod 'UCZProgressView', :git => 'https://github.com/yagainc/UCZProgressView.git'
    pod 'OrderedDictionary'
    pod 'AFDownloadRequestOperation'
    pod 'MBProgressHUD', '~> 0.8'
    pod 'Mixpanel', '>= 2.8.2'
    pod 'Firebase', '>= 2.3.1'
    pod 'MSAlertController'
    pod 'GPUImage', :git => 'https://github.com/yagainc/GPUImage.git', :commit => '714beb8f3d8a477245d95b1610ccdd40f7867019'
    pod 'Harpy'
    pod 'SloppySwiper'
    pod 'FBSDKShareKit'
    pod 'BLKFlexibleHeightBar'
end

target 'YAVideoShareExtension', :exclusive => true do
	platform :ios, '8.0'
	pod 'AFNetworking', '~> 2.0'
    pod 'MBProgressHUD', '~> 0.8'
end

post_install do |installer_representation|
    installer_representation.project.targets.each do |target|
        if target.name == "Pods-YAVideoShareExtension-AFNetworking"
            target.build_configurations.each do |config|
                    config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)', 'AF_APP_EXTENSIONS=1']
            end
        end
    end
end
