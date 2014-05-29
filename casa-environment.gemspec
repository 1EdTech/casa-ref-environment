Gem::Specification.new do |s|

  s.name        = 'casa-environment'
  s.version     = '0.1.0'
  s.summary     = 'Environment manager for the reference implementation for the CASA Protocol'
  s.authors     = ['Eric Bollens']
  s.email       = ['ebollens@ucla.edu']
  s.homepage    = 'https://imsglobal.github.io/casa'
  s.license     = 'Apache-2'

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  s.add_dependency 'thor'
  s.add_dependency 'systemu'
  s.add_dependency 'deep_merge'
  s.add_dependency 'extend_method'
  s.add_dependency 'sequel'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'coveralls'

end