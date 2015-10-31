Pod::Spec.new do |s|

s.name          = "ALBNoSQLDB"
s.module_name   = "ALBNoSQLDB"
s.version       = "2.0"
s.summary       = "A SQLite database wrapper written in Swift that requires no SQL knowledge to use and can sync with instances of itself."
s.homepage      = "https://github.com/AaronBratcher/ALBNoSQLDB"
s.license       = "MIT"
s.author        = { "Aaron Bratcher" => "aaronlbratcher@yahoo.com" }
s.platform      = :ios, "8.0"
s.source        = { :git => "https://github.com/AaronBratcher/ALBNoSQLDB.git", :tag => "v2.0" }
s.source_files  = "ALBNoSQLDB", "ALBNoSQLDB/ALBNoSQLDB.swift"
s.module_map    = "ALBNoSQLDB/module.modulemap"
s.framework     = "sqlite3"

end
