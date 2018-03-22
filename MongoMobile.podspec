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
  spec.source_files = ["Sources/MongoMobile/**/*.swift", "Sources/MongoSwift/**/*.swift"]
  spec.preserve_paths = [
    "Sources/libmongodbcapi/*.{h,modulemap}",
    "Sources/libbson/*.{h,modulemap}",
    "Sources/libmongoc/*.{h,modulemap}",
    "MobileSDKs"
  ]

  spec.prepare_command = <<-EOT
  # download module definitions for libmongoc/libbson
  [[ -d Sources/libbson ]] || git clone --depth 1 https://github.com/mongodb/swift-bson Sources/libbson
  [[ -d Sources/libmongoc ]] || git clone --depth 1 https://github.com/mongodb/swift-mongoc Sources/libmongoc

  # vendor in MongoSwift
  if [ ! -d Sources/MongoSwift ]; then
    curl -L https://api.github.com/repos/mongodb/mongo-swift-driver/tarball > mongo-swift.tgz
    mkdir mongo-swift
    tar -xzf mongo-swift.tgz -C mongo-swift --strip-components 1
    cp -r mongo-swift/Sources/MongoSwift Sources/MongoSwift
    # TODO: copy tests

    rm -rf mongo-swift mongo-swift.tgz
  fi

  # download mobile SDKs
  mkdir -p MobileSDKs && cd MobileSDKs

  if [ ! -d iphoneos ]; then
    curl https://s3.amazonaws.com/mciuploads/mongodb-mongo-master/ios-102-debug/17eebc8ac8bfcff0b8d2b8b2a1d97187efd6efca/embedded_sdk/mongodb_mongo_master_ios_102_debug_patch_17eebc8ac8bfcff0b8d2b8b2a1d97187efd6efca_5ab13a42e3c33148ba80034f_18_03_20_16_46_13.tgz > mobile-sdks.tgz
    mkdir iphoneos
    tar -xzf mobile-sdks.tgz -C iphoneos --strip-components 2
    rm mobile-sdks.tgz

    # TEMPORARY
    sed -i '' '/#include "mongo\\/client\\/embedded\\/libmongodbcapi.h"/d' iphoneos/include/embedded_transport_layer.h
  fi

  if [ ! -d iphonesimulator ]; then
    curl https://s3.amazonaws.com/mciuploads/mongodb-mongo-master/ios-sim-102-debug/17eebc8ac8bfcff0b8d2b8b2a1d97187efd6efca/embedded_sdk/mongodb_mongo_master_ios_sim_102_debug_patch_17eebc8ac8bfcff0b8d2b8b2a1d97187efd6efca_5ab13a42e3c33148ba80034f_18_03_20_16_46_13.tgz > mobile-sdks.tgz
    mkdir iphonesimulator
    tar -xzf mobile-sdks.tgz -C iphonesimulator --strip-components 2
    rm mobile-sdks.tgz

    # TEMPORARY
    sed -i '' '/#include "mongo\\/client\\/embedded\\/libmongodbcapi.h"/d' iphonesimulator/include/embedded_transport_layer.h
  fi
  EOT

  spec.ios.vendored_library = "MobileSDKs/iphonesimulator/lib/*"
  spec.tvos.vendored_library = "MobileSDKs/appletvsimulator/lib/*"

  spec.pod_target_xcconfig = {
    'SWIFT_INCLUDE_PATHS[sdk=iphoneos*]'  => [
      '"$(PODS_TARGET_SRCROOT)/MobileSDKs/iphoneos/include"',
      '"$(PODS_TARGET_SRCROOT)/MobileSDKs/iphoneos/include/libbson-1.0"',
      '"$(PODS_TARGET_SRCROOT)/MobileSDKs/iphoneos/include/libmongoc-1.0"',
      '"$(PODS_TARGET_SRCROOT)/Sources/libmongodbcapi"',
      '"$(PODS_TARGET_SRCROOT)/Sources/libmongoc"',
      '"$(PODS_TARGET_SRCROOT)/Sources/libbson"',
    ].join(' '),

    'SWIFT_INCLUDE_PATHS[sdk=iphonesimulator*]'  => [
      '"$(PODS_TARGET_SRCROOT)/MobileSDKs/iphonesimulator/include"',
      '"$(PODS_TARGET_SRCROOT)/MobileSDKs/iphonesimulator/include/libbson-1.0"',
      '"$(PODS_TARGET_SRCROOT)/MobileSDKs/iphonesimulator/include/libmongoc-1.0"',
      '"$(PODS_TARGET_SRCROOT)/Sources/libmongodbcapi"',
      '"$(PODS_TARGET_SRCROOT)/Sources/libmongoc"',
      '"$(PODS_TARGET_SRCROOT)/Sources/libbson"',
    ].join(' '),
    'SWIFT_INCLUDE_PATHS[sdk=appletvos*]'        => '$(PODS_TARGET_SRCROOT)/MobileSDKs/appletvos/include',
    'SWIFT_INCLUDE_PATHS[sdk=appletvsimulator*]' => '$(PODS_TARGET_SRCROOT)/MobileSDKs/appletvsimulator/include',

    'LIBRARY_SEARCH_PATHS[sdk=iphoneos*]'        => '$(PODS_TARGET_SRCROOT)/MobileSDKs/iphoneos/lib',
    'LIBRARY_SEARCH_PATHS[sdk=iphonesimulator*]' => '$(PODS_TARGET_SRCROOT)/MobileSDKs/iphonesimulator/lib',
    'LIBRARY_SEARCH_PATHS[sdk=appletvos*]'       => '$(PODS_TARGET_SRCROOT)/MobileSDKs/appletvos/lib',
    'LIBRARY_SEARCH_PATHS[sdk=appletvsimulator*]'=> '$(PODS_TARGET_SRCROOT)/MobileSDKs/appletvsimulator/lib'
  }
end
