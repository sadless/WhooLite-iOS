source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '9.0'

target 'WhooLite' do
  use_frameworks!

  # Pods for WhooLite
  pod 'RealmSwift'
  pod 'Firebase/Core'
  pod 'Firebase/AdMob'
  pod 'SVProgressHUD'

  target 'WhooLiteTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'WhooLiteUITests' do
    inherit! :search_paths
    # Pods for testing
  end

    post_install do |installer|
        installer.pods_project.targets.each do |target|
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = '3.0'
            end
        end
    end
end
