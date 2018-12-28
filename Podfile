workspace 'MongoMobile.xcworkspace'
# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'

target 'MongoMobile' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for MongoMobile
  pod 'MongoSwift', '~> 0.0.7'
  pod 'mongoc_embedded', '~> 4.0.4'
  pod 'mongo_embedded', '~> 4.0.4'
  
  target 'MongoMobileTests' do
    inherit! :search_paths
    # Pods for testing

    # Pods for MongoMobile
    pod 'MongoSwift', '~> 0.0.7'
    pod 'mongoc_embedded', '~> 4.0.4'
    pod 'mongo_embedded', '~> 4.0.4'
  end

end

target 'MongoMobileExample' do
    project 'MongoMobileExample/MongoMobileExample.xcodeproj'
    # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
    use_frameworks!

    # Pods for MongoMobile
    pod 'MongoSwift', '~> 0.0.7'
    pod 'mongoc_embedded', '~> 4.0.4'
    pod 'mongo_embedded', '~> 4.0.4'
end
