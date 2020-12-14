lib = File.expand_path("../lib/", __FILE__)
$:.unshift(lib) unless $:.include?(lib)

require "active_shipping/version"

Gem::Specification.new do |s|
  if s.respond_to?(:metadata)
    s.metadata["allowed_push_host"] = "https://rubygems.pkg.github.com/Hello-Labs/"
  end

  s.name          = "active_shipping"
  s.version       = ActiveShipping::VERSION
  s.platform      = Gem::Platform::RUBY
  s.authors       = ["Shopify"]
  s.email         = ["integrations-team@shopify.com"]
  s.homepage      = "http://github.com/shopify/active_shipping"
  s.summary       = "Simple shipping abstraction library"
  s.description   = "Get rates and tracking info from various shipping carriers. Extracted from Shopify."
  s.license       = "MIT"
  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.require_path  = "lib"
  s.post_install_message = "Thanks for installing ActiveShipping! If upgrading to v2.0, please see the changelog for breaking changes: https://github.com/Shopify/active_shipping/blob/master/CHANGELOG.md."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  s.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  s.add_dependency("measured", ">= 2.0")
  s.add_dependency("activesupport", ">= 4.2")
  s.add_dependency("active_utils", "~> 3.3.1")
  s.add_dependency("nokogiri", ">= 1.6")

  s.add_development_dependency("minitest")
  s.add_development_dependency("minitest-reporters")
  s.add_development_dependency("rake")
  s.add_development_dependency("mocha", "~> 1")
  s.add_development_dependency("timecop")
  s.add_development_dependency("business_time")
  s.add_development_dependency("pry")
  s.add_development_dependency("pry-byebug")
  s.add_development_dependency("vcr")
  s.add_development_dependency("webmock")
end
