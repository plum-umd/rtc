# In the top directory 
# gem build dsl.gemspec
# gem install dsl-0.0.0.gem

Gem::Specification.new do |s|
  s.name        = 'dsl'
  s.version     = '0.0.0'
  s.date        = '2013-03-29'
  s.summary     = "DSL Specification Language"
  s.description = "DSL Specification Language"
  s.authors     = ["NA"]
  s.email       = 'NA'
  s.files       = ["lib/dsl.rb", "lib/dsl/inspect.rb", "lib/dsl/infer.rb",
                   "lib/dsl/structure.rb"]
  s.homepage    =
    'https://github.com/plum-umd/rtc'
end
