Gem::Specification.new do |s|
  # Get the facts.
  s.name             = "yard-grape"
  s.version          = "1.0.1"
  s.description      = "Displays Grape routes (including comments) in YARD output."

  # External dependencies
  s.add_dependency "yard", "~> 0.7"
  s.add_development_dependency "rspec", "~> 2.6"

  # Those should be about the same in any BigBand extension.
  s.authors          = ["nobody"]
  s.email            = "Jianfeng@revibe.fm"
  s.files            = Dir["**/*.{rb,md}"] << "LICENSE"
  s.homepage         = "http://github.com/winfield/#{s.name}"
  s.require_paths    = ["lib"]
  s.summary          = s.description
end
