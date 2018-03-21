Pod::Spec.new do |spec|
  spec.name       = "MongoMobile"
  spec.version    = "0.0.1"
  spec.summary    = "Some description"
  spec.homepage   = "https://github.com/10gen/swift-mongo-mobile"
  spec.license    = 'AGPL 3.0'
  spec.author     = { "mbroadst" => "mbroadst@mongodb.com" }
  spec.source     = {
    :git => "ssh://git@github.com/10gen/swift-mongo-mobile.git",
    :branch => "master"
  }

  spec.platform = :ios, "11.2"
  spec.swift_version = "4"
  spec.requires_arc = true
  spec.source_files = "Sources/MongoMobile/**/*.swift"
  spec.preserve_paths = [
    "Sources/libmongodbcapi/*.{h,modulemap}"
  ]

  spec.dependency 'MongoSwift', '~> 0'


  ENV["MONGODB_MOBILE"] = "HERE IS A SOME SAMPLE DATA FOR MY COOL ENVIRONMENT VARIABLE"
  spec.prepare_command = <<-EOT
  mkdir -p MobileSDKs && cd MobileSDKs
  if [ ! -d iphonesimulator ]; then
    wget https://s3.amazonaws.com/mciuploads/mongodb-mongo-master/ios-sim-102-debug/17eebc8ac8bfcff0b8d2b8b2a1d97187efd6efca/embedded_sdk/mongodb_mongo_master_ios_sim_102_debug_patch_17eebc8ac8bfcff0b8d2b8b2a1d97187efd6efca_5ab13a42e3c33148ba80034f_18_03_20_16_46_13.tgz
    mkdir iphonesimulator
    tar -xzf mongodb_mongo_master_ios_sim_102_debug_patch_17eebc8ac8bfcff0b8d2b8b2a1d97187efd6efca_5ab13a42e3c33148ba80034f_18_03_20_16_46_13.tgz -C iphonesimulator --strip-components 2
    rm *.tgz
  fi

  # mkdir iphoneos && tar -xzf mongodb_mongo_master_ios_102_debug_patch_17eebc8ac8bfcff0b8d2b8b2a1d97187efd6efca_5ab13a42e3c33148ba80034f_18_03_20_16_46_13.tgz -C ios --strip-components 1
  # mkdir iphonesimulator && tar -xzf mongodb_mongo_master_ios_sim_102_debug_patch_17eebc8ac8bfcff0b8d2b8b2a1d97187efd6efca_5ab13a42e3c33148ba80034f_18_03_20_16_46_13.tgz -C ios-sim --strip-components 1
  EOT

  spec.pod_target_xcconfig = {
    'SWIFT_INCLUDE_PATHS[sdk=iphoneos*]'         => '"$(PODS_TARGET_SRCROOT)/MobileSDKs/iphoneos/include" "$(PODS_TARGET_SRCROOT)/Sources/libmongodbcapi/include"',
    'SWIFT_INCLUDE_PATHS[sdk=iphonesimulator*]'  => '"$(PODS_TARGET_SRCROOT)/MobileSDKs/iphonesimulator/include" "$(PODS_TARGET_SRCROOT)/MobileSDKs/iphonesimulator/include/libbson-1.0" "$(PODS_TARGET_SRCROOT)/MobileSDKs/iphonesimulator/include/libmongoc-1.0" "$(PODS_TARGET_SRCROOT)/Sources/libmongodbcapi"',
    'SWIFT_INCLUDE_PATHS[sdk=appletvos*]'        => '$(PODS_TARGET_SRCROOT)/MobileSDKs/appletvos/include',
    'SWIFT_INCLUDE_PATHS[sdk=appletvsimulator*]' => '$(PODS_TARGET_SRCROOT)/MobileSDKs/appletvsimulator/include',

    'LIBRARY_SEARCH_PATHS[sdk=iphoneos*]'        => '$(PODS_TARGET_SRCROOT)/MobileSDKs/iphoneos/lib',
    'LIBRARY_SEARCH_PATHS[sdk=iphonesimulator*]' => '$(PODS_TARGET_SRCROOT)/MobileSDKs/iphonesimulator/lib',
    'LIBRARY_SEARCH_PATHS[sdk=appletvos*]'       => '$(PODS_TARGET_SRCROOT)/MobileSDKs/appletvos/lib',
    'LIBRARY_SEARCH_PATHS[sdk=appletvsimulator*]'=> '$(PODS_TARGET_SRCROOT)/MobileSDKs/appletvsimulator/lib'
  }


end
