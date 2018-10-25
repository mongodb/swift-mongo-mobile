Pod::Spec.new do |spec|
  spec.name       = "MongoMobile"
  spec.version    = "0.0.2"
  spec.summary    = "Some description"
  spec.homepage   = "https://github.com/mongodb/swift-mongo-mobile"
  spec.license    = 'AGPL 3.0'
  spec.author     = { "Matt Broadstone" => "mbroadst@mongodb.com" }
  spec.source     = {
    :git => "ssh://git@github.com/10gen/swift-mongo-mobile.git",
    :branch => "SWIFT-129/use-mobile-sdk-for-cocoapods"
  }

  spec.ios.deployment_target = "11.0"
  spec.tvos.deployment_target = "10.2"
  spec.watchos.deployment_target = "4.3"

  spec.requires_arc = true
  spec.source_files = ["Sources/MongoMobile/**/*.swift"]

  spec.dependency 'MongoSwift', '~> 0.0.5'
  spec.dependency 'mongoc_embedded', '~> 4.0.3-92-g8468282'
  spec.dependency 'mongo_embedded', '~> 4.0.3-92-g8468282'
end
