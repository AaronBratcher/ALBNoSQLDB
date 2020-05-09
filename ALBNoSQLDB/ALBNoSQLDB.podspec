Pod::Spec.new do |s|
  s.name         = "ALBNoSQLDB"
  s.version      = "6.0.0"
  s.summary      = "A thread safe SQLite database wrapper written in Swift 5"
  s.homepage	 = "https://github.com/AaronBratcher/ALBNoSQLDB"

  s.license      = "MIT"
  s.author             = { "Aaron Bratcher" => "aaronlbratcher@yahoo.com" }
  s.social_media_url   = "http://twitter.com/AaronLBratcher"

  s.osx.deployment_target = "10.15"
  s.ios.deployment_target = "13.0"
  s.swift_version = '5.2'
  
  s.osx.frameworks = 'AppKit', 'Foundation'
  s.ios.frameworks = 'UIKit', 'Foundation'
  
  s.source				= { :git => "https://github.com/AaronBratcher/ALBNoSQLDB.git", :tag => s.version }
  s.ios.source_files	= "ALBNoSQLDB", "ALBNoSQLDB/ALBNoSQLDB/**/*.{h,m,swift}"
  s.osx.source_files	= "ALBNoSQLDB", "ALBNoSQLDB/ALBNoSQLDB/**/*.{h,m,swift}"
  
  s.library				= "sqlite3"
end
