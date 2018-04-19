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
    curl https://s3.amazonaws.com/mciuploads/mongodb-mongo-master/embedded-sdk/embedded-sdk-iphoneos-10.2-debug/84f56ce808fc985f2c340f05fc7f7e63ccbdb8e7/mongodb_mongo_master_embedded_sdk_iphoneos_10.2_debug_patch_84f56ce808fc985f2c340f05fc7f7e63ccbdb8e7_5ad6beaee3c3316b1511aa4c_18_04_18_03_43_05.tgz > mobile-sdks.tgz
    mkdir iphoneos
    tar -xzf mobile-sdks.tgz -C iphoneos --strip-components 2
    rm mobile-sdks.tgz

    # TEMPORARY
    rm iphoneos/lib/libbson-1.0.dylib
    cp iphoneos/lib/libbson-1.0.0.dylib iphoneos/lib/libbson-1.0.dylib
    rm iphoneos/lib/libmongoc-1.0.dylib
    cp iphoneos/lib/libmongoc-1.0.0.dylib iphoneos/lib/libmongoc-1.0.dylib
  fi

  if [ ! -d iphonesimulator ]; then
    curl https://s3.amazonaws.com/mciuploads/mongodb-mongo-master/embedded-sdk/embedded-sdk-iphonesimulator-10.2-debug/84f56ce808fc985f2c340f05fc7f7e63ccbdb8e7/mongodb_mongo_master_embedded_sdk_iphonesimulator_10.2_debug_patch_84f56ce808fc985f2c340f05fc7f7e63ccbdb8e7_5ad6beaee3c3316b1511aa4c_18_04_18_03_43_05.tgz > mobile-sdks.tgz

    mkdir iphonesimulator
    tar -xzf mobile-sdks.tgz -C iphonesimulator --strip-components 2
    rm mobile-sdks.tgz

    # TEMPORARY
    rm iphonesimulator/lib/libbson-1.0.dylib
    cp iphonesimulator/lib/libbson-1.0.0.dylib iphonesimulator/lib/libbson-1.0.dylib
    rm iphonesimulator/lib/libmongoc-1.0.dylib
    cp iphonesimulator/lib/libmongoc-1.0.0.dylib iphonesimulator/lib/libmongoc-1.0.dylib
  fi
  EOT

  spec.ios.vendored_library = "MobileSDKs/iphonesimulator/lib/*.dylib"
  spec.tvos.vendored_library = "MobileSDKs/appletvsimulator/lib/*.dylib"

  spec.pod_target_xcconfig = {
    'OTHER_LDFLAGS[sdk=iphoneos*]' => '-rpath $(PODS_TARGET_SRCROOT)/MobileSDKs/iphoneos/lib',
    'SWIFT_INCLUDE_PATHS[sdk=iphoneos*]'  => [
      '"$(PODS_TARGET_SRCROOT)/MobileSDKs/iphoneos/include"',
      '"$(PODS_TARGET_SRCROOT)/MobileSDKs/iphoneos/include/libbson-1.0"',
      '"$(PODS_TARGET_SRCROOT)/MobileSDKs/iphoneos/include/libmongoc-1.0"',
      '"$(PODS_TARGET_SRCROOT)/Sources/libmongodbcapi"',
      '"$(PODS_TARGET_SRCROOT)/Sources/libmongoc"',
      '"$(PODS_TARGET_SRCROOT)/Sources/libbson"',
    ].join(' '),

    'OTHER_LDFLAGS[sdk=iphonesimulator*]' => '-rpath $(PODS_TARGET_SRCROOT)/MobileSDKs/iphonesimulator/lib',
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
    'LIBRARY_SEARCH_PATHS[sdk=appletvsimulator*]'=> '$(PODS_TARGET_SRCROOT)/MobileSDKs/appletvsimulator/lib',
  }
end
