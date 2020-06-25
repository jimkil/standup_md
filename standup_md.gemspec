require_relative 'lib/standup_md/version'

Gem::Specification.new do |spec|
  spec.name          = 'standup_md'
  spec.version       = StandupMD::Version.to_s
  spec.authors       = ['Evan Gray']
  spec.email         = 'evanthegrayt@vivaldi.net'
  spec.license       = 'MIT'
  spec.date          = Time.now.strftime('%Y-%m-%d')

  spec.summary       = %q{The cure for all your standup woes}
  spec.description   = %q{Generate and edit standups in markdown format}
  spec.homepage      = 'https://evanthegrayt.github.io/standup_md/'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'

    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://github.com/evanthegrayt/standup_md'
    spec.metadata['documentation_uri'] = 'https://evanthegrayt.github.io/standup_md/doc/index.html'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  # spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    # `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  # end
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.add_development_dependency 'rake', '~> 13.0', '>= 13.0.1'
  spec.add_development_dependency 'test-unit', '~> 3.3', '>= 3.3.5'
  spec.add_development_dependency 'simplecov'
end
