Pod::Spec.new do |s|
  s.name         = "SlideUpPanel"
  s.version      = "1.1"
  s.summary      = "SlideUpPanel is a custom control."
  s.description  = "With use of SlideUpPanel we can implement Google map like slide up panel in ios."
  s.homepage     = "https://github.com/DominatorVbN/SlideUpPanel"
  s.screenshots  = "https://raw.githubusercontent.com/DominatorVbN/SlideUpPanel/master/SlideUpPanel.gif"
  s.license      = "MIT"
  s.author             = { "DominatorVbN" => "as9039851921@gmail.com" }
  s.platform     = :ios, "12.0"
  s.source       = { :git => "https://github.com/neneds/SlideUpPanel.git", :tag => "1.1" }
  s.source_files  = "SlideUpPanel/Sources/**/*.{swift}"
  s.swift_version = "5.1"
end
