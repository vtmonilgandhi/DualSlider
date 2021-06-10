Pod::Spec.new do |spec|

  spec.name                  = "DualSlider"
  spec.version               = "0.0.8"
  spec.summary               = "A cocoapod library for dual slider."
  spec.description           = <<-DESC
                               This CocoaPods library helps you to create dual and single slider with customization.
                               DESC
  spec.homepage              = "https://github.com/vtmonilgandhi/DualSlider"
  # spec.screenshots         = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"
  spec.license               = "MIT"
  spec.author                = { "Monil Gandhi" => "monilgandhi28@gmail.com" }
  spec.ios.deployment_target = "13.0"
  spec.swift_version         = "5.0"
  spec.source                = { :git => "https://github.com/vtmonilgandhi/DualSlider.git", :tag => "0.0.8" }
  spec.source_files          = "DualSlider/DualSlider/**/*.{h,m,swift}"

end
