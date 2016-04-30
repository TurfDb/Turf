Pod::Spec.new do |s|
  s.name     = "Turf"
  s.version  = "0.0.1"
  s.summary  = "Fully Swift compatible, strongly typed document store built upon SQLite."
  s.license  = { :type => "MIT", :file => "LICENSE" }

  s.description      = <<-DESC
    Turf is a strongly typed database built from the ground up for Swift. It provides an
    extemely safe wrapper around SQLite3 enabling easy, performant peristence of `struct`s,
    `class`es, `enum`s or tuples.
                       DESC

  s.homepage = "https://github.com/TurfDb/Turf"
  s.author   = { "Jordan Hamill" => "https://twitter.com/JayHamill22" }
  s.source   = { :git => "git@github.com:TurfDb/Turf.git", :tag => "#{s.version}" }
  s.source_files = "Turf/**/*.{h,m,swift}"
  s.libraries = 'sqlite3'
  s.ios.deployment_target = "9.0"
  s.osx.deployment_target = "10.10"
  s.requires_arc = true
end
