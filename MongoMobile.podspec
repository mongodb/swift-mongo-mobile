Pod::Spec.new do |spec|
  spec.name       = "MongoMobile"
  spec.version    = "0.0.1"
  spec.summary    = "Some description"
  spec.homepage   = "https://github.com/mongodb/swift-mongo-mobile"
  spec.license    = 'AGPL 3.0'
  spec.author     = { "Matt Broadstone" => "mbroadst@mongodb.com" }
  spec.source     = {
    :git => "ssh://git@github.com/10gen/swift-mongo-mobile.git",
    :branch => "master"
  }

  spec.platform = :ios, "11.2"
  spec.requires_arc = true
  spec.source_files = ["Sources/MongoMobile/**/*.swift", "Sources/MongoSwift/**/*.swift"]
  spec.prepare_command = 'sh build.sh'
  spec.preserve_paths = [
    "Sources/mongo_embedded/*.{h,modulemap}",
    "Sources/libbson/*.{h,modulemap}",
    "Sources/libmongoc/*.{h,modulemap}",
    "MobileSDKs"
  ]

  spec.ios.vendored_library = "MobileSDKs/iphoneos/lib/*.dylib"
  spec.tvos.vendored_library = "MobileSDKs/appletvos/lib/*.dylib"

  spec.pod_target_xcconfig = {
    'OTHER_LDFLAGS[sdk=iphoneos*]' => '-rpath $(PODS_TARGET_SRCROOT)/MobileSDKs/iphoneos/lib',
    'OTHER_LDFLAGS[sdk=iphonesimulator*]' => '-rpath $(PODS_TARGET_SRCROOT)/MobileSDKs/iphoneos/lib',
    'OTHER_LDFLAGS[sdk=appletvos*]' => '-rpath $(PODS_TARGET_SRCROOT)/MobileSDKs/appletvos/lib',
    'OTHER_LDFLAGS[sdk=appletvsimulator*]' => '-rpath $(PODS_TARGET_SRCROOT)/MobileSDKs/appletvos/lib',
    'LIBRARY_SEARCH_PATHS[sdk=iphoneos*]'        => '$(PODS_TARGET_SRCROOT)/MobileSDKs/iphoneos/lib',
    'LIBRARY_SEARCH_PATHS[sdk=iphonesimulator*]' => '$(PODS_TARGET_SRCROOT)/MobileSDKs/iphoneos/lib',
    'LIBRARY_SEARCH_PATHS[sdk=appletvos*]'       => '$(PODS_TARGET_SRCROOT)/MobileSDKs/appletvos/lib',
    'LIBRARY_SEARCH_PATHS[sdk=appletvsimulator*]'=> '$(PODS_TARGET_SRCROOT)/MobileSDKs/appletvos/lib',

    'SWIFT_INCLUDE_PATHS' => [
      '"$(PODS_TARGET_SRCROOT)/MobileSDKs/include"',
      '"$(PODS_TARGET_SRCROOT)/MobileSDKs/include/mongo/embedded-v1/"',
      '"$(PODS_TARGET_SRCROOT)/MobileSDKs/include/libbson-1.0"',
      '"$(PODS_TARGET_SRCROOT)/MobileSDKs/include/libmongoc-1.0"',
      '"$(PODS_TARGET_SRCROOT)/Sources/mongo_embedded"',
      '"$(PODS_TARGET_SRCROOT)/Sources/libmongoc"',
      '"$(PODS_TARGET_SRCROOT)/Sources/libbson"',
    ].join(' ')
  }

  # This is due to some linking leakage, should be resolved by converting to Frameworks
  spec.user_target_xcconfig = {
    'LIBRARY_SEARCH_PATHS[sdk=iphoneos*]'        => '$(PODS_ROOT)/MongoMobile/MobileSDKs/iphoneos/lib',
    'LIBRARY_SEARCH_PATHS[sdk=iphonesimulator*]' => '$(PODS_ROOT)/MongoMobile/MobileSDKs/iphoneos/lib',
    'LIBRARY_SEARCH_PATHS[sdk=appletvos*]'       => '$(PODS_ROOT)/MongoMobile/MobileSDKs/appletvos/lib',
    'LIBRARY_SEARCH_PATHS[sdk=appletvsimulator*]'=> '$(PODS_ROOT)/MongoMobile/MobileSDKs/appletvos/lib',
  }
end
