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
    "Sources/libmongocapi/*.{h,modulemap}"
  ]

  spec.dependency 'MongoSwift', '~> 1.0'

  spec.prepare_command = <<-EOT
  # mkdir iphoneos && tar -xzf mongodb_mongo_master_ios_102_debug_patch_17eebc8ac8bfcff0b8d2b8b2a1d97187efd6efca_5ab13a42e3c33148ba80034f_18_03_20_16_46_13.tgz -C ios --strip-components 1
  # mkdir iphonesimulator && tar -xzf mongodb_mongo_master_ios_sim_102_debug_patch_17eebc8ac8bfcff0b8d2b8b2a1d97187efd6efca_5ab13a42e3c33148ba80034f_18_03_20_16_46_13.tgz -C ios-sim --strip-components 1
  EOT

  s.pod_target_xcconfig = {
    'SWIFT_INCLUDE_PATHS[sdk=iphoneos*]'         => '$(SRCROOT)/SDKs/iphoneos/include',
    'SWIFT_INCLUDE_PATHS[sdk=iphonesimulator*]'  => '$(SRCROOT)/SDKs/iphonesimulator/include',
    'SWIFT_INCLUDE_PATHS[sdk=appletvos*]'        => '$(SRCROOT)/SDKs/appletvos/include',
    'SWIFT_INCLUDE_PATHS[sdk=appletvsimulator*]' => '$(SRCROOT)/SDKs/appletvsimulator/include',

    'LIBRARY_SEARCH_PATHS[sdk=iphoneos*]'        => '$(SRCROOT)/SDKs/iphoneos/lib'
    'LIBRARY_SEARCH_PATHS[sdk=iphonesimulator*]' => '$(SRCROOT)/SDKs/iphonesimulator/lib'
    'LIBRARY_SEARCH_PATHS[sdk=appletvos*]'       => '$(SRCROOT)/SDKs/appletvos/lib'
    'LIBRARY_SEARCH_PATHS[sdk=appletvsimulator*]'=> '$(SRCROOT)/SDKs/appletvsimulator/lib'
  }


end
