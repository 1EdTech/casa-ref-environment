Gem::Specification.new do |s|

  s.name        = 'casa-environment'
  s.version     = '0.0.01'
  s.summary     = 'Environment manager for the reference implementation for the CASA Protocol'
  s.authors     = ['Eric Bollens']
  s.email       = ['ebollens@ucla.edu']
  s.homepage    = 'https://appsharing.github.io/casa-protocol'
  s.license     = 'BSD-3-Clause'

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  s.add_dependency 'thor'
  s.add_dependency 'systemu'
  s.add_dependency 'deep_merge'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'coveralls'

end