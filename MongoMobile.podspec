Pod::Spec.new do |spec|
  spec.name       = "MongoMobile"
  spec.version    = "0.1.0"
  spec.summary    = "An embedded version of MongoDB for mobile"
  spec.homepage   = "https://github.com/mongodb/swift-mongo-mobile"
  spec.license    = 'Apache License, Version 2.0'
  spec.authors    = {
    "Matt Broadstone" => "mbroadst@mongodb.com",
    "Kaitlin Mahar" => "kaitlin.mahar@mongodb.com",
    "Patrick Freed" => "patrick.freed@mongodb.com"
  }
  spec.source     = {
    :git => "https://github.com/mongodb/swift-mongo-mobile.git",
    :tag => "v0.1.0"
  }

  spec.ios.deployment_target = "11.0"
  spec.tvos.deployment_target = "10.2"
  spec.watchos.deployment_target = "4.3"

  spec.requires_arc = true
  spec.source_files = ["Sources/MongoMobile/**/*.swift"]

  spec.dependency "MongoSwift", "~> 0.1.0"
  spec.dependency "mongoc_embedded", "~> 4.0.4"
  spec.dependency "mongo_embedded", "~> 4.0.4"

  spec.test_spec "Tests" do |test_spec|
    test_spec.ios.deployment_target = "11.0"
    test_spec.source_files = "Tests/MongoMobileTests/*.swift"
  end
end
