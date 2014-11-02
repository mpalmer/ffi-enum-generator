require 'git-version-bump'

Gem::Specification.new do |s|
	s.name = "ffi-enum-generator"

	s.version = GVB.version
	s.date    = GVB.date

	s.platform = Gem::Platform::RUBY

	s.homepage = "http://theshed.hezmatt.org/ffi-enum-generator"
	s.summary = "Generate values for FFI enums directly"
	s.authors = ["Matt Palmer"]

	s.extra_rdoc_files = ["README.md"]
	s.files = `git ls-files -z lib`.split("\0")

	s.add_runtime_dependency "git-version-bump", "~> 0.10"
	s.add_runtime_dependency "ffi", "~> 1.9"

	s.add_development_dependency 'bundler'
	s.add_development_dependency 'github-release'
	s.add_development_dependency 'rake'
	s.add_development_dependency 'redcarpet'
	s.add_development_dependency 'yard'
end
