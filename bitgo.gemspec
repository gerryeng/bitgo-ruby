Gem::Specification.new do |s|
  s.name        = 'bitgo'
  s.version     = '0.0.4'
  s.date        = '2015-04-09'
  s.summary     = "Ruby wrapper for Bitgo and Bitgo Express API"
  s.description = "Ruby wrapper for Bitgo and Bitgo Express API"
  s.authors     = ["Gerry Eng", "Pramodh Rai", "Genaro Madrid"]
  s.email       = 'gerry@coinhako.com'
  s.files       = ["lib/bitgo.rb", "lib/bitgo/v1/api.rb", "lib/bitgo/v2/api.rb"]
  s.homepage    = 'https://www.bitgo.com/api/'
  s.license       = 'MIT'

  s.add_development_dependency 'bundler', '~> 1.6'
  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'rspec', '3.1'
  s.add_development_dependency 'bump', '~> 0.5', '>= 0.5.3'
  s.add_development_dependency 'pry'
end
