# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "roda-sprockets"
  spec.version       = '1.0.1'
  spec.authors       = ["cj", "hmdne"]
  spec.email         = ["cjlazell@gmail.com"]
  spec.summary       = %q{Use sprockets to serve assets in roda.}
  spec.description   = %q{Use sprockets to serve assets in roda.}
  spec.homepage      = "https://github.com/hmdne/roda-sprockets"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'roda', '~> 3'
  spec.add_dependency 'sprockets', '>= 2.2'
  spec.add_dependency 'sprockets-helpers', '>= 1.4.0'

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
end
