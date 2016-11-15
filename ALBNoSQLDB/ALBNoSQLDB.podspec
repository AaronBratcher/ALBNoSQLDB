Pod::Spec.new do |s|
  s.name         = "ALBNoSQLDB"
  s.version      = "4.1.1"
  s.summary      = "A thread safe SQLite database wrapper written in Swift 3"
  s.homepage	 = "https://github.com/AaronBratcher/ALBNoSQLDB"

  s.license      = "MIT"
  s.author             = { "Aaron Bratcher" => "aaronbratcher1@gmail.com" }
  s.social_media_url   = "http://twitter.com/AaronLBratcher"

  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/AaronBratcher/ALBNoSQLDB.git", :tag => "4.1.1" }
  s.source_files  = "ALBNoSQLDB", "ALBNoSQLDB/ALBNoSQLDB/**/*.{h,m,swift}"
  s.library      = "sqlite3"
end
