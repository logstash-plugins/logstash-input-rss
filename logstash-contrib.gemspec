# -*- encoding: utf-8 -*-
require File.expand_path('../lib/logstash/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Author Name"]
  gem.email         = ["Auther Email"]
  gem.description   = %q{A description}
  gem.summary       = %q{logstash-pluginname}
  gem.homepage      = "Some Website"
  gem.license       = "Apache License (2.0)"

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "logstash-pluginname"
  gem.require_paths = ["lib"]
  gem.version       = LOGSTASH_VERSION
end
