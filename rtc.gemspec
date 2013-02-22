# In the top directory 
# gem build rtc.gemspec
# gem install rtc-0.0.0.gem

Gem::Specification.new do |s|
  s.name        = 'rtc'
  s.version     = '0.0.0'
  s.date        = '2011-02-16'
  s.summary     = "Ruby Type Checker"
  s.description = "Ruby Type Checker"
  s.authors     = ["NA"]
  s.email       = 'NA'
  s.files       = Dir.glob("*") + Dir.glob("*/*")  + Dir.glob("*/*/*") + Dir.glob("*/*/*/*") + Dir.glob("*/*/*/*/*") 
  s.homepage    =
    'https://github.com/jeffrey-s-foster/rtc'
  s.add_dependency 'racc'
end
