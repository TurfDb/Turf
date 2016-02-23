Pod::Spec.new do |s|
  s.name     = "Turf"
  s.version  = "0.1"
  s.summary  = "Really strongly typed document store built upon SQLite."
  s.license  = { :type => "MIT", :file => "LICENSE" }

  s.homepage = "https://github.com/jordanhamill/Turf"
  s.author   = { "Jordan Hamill" => "https://twitter.com/JayHamill22" }
  s.source   = { :git => "git@github.com:jordanhamill/Turf.git", :tag => "#{s.version}" }
  s.source_files = "Turf/*.swift"
  s.ios.deployment_target = "9.0"
  s.requires_arc = true
end