# Rakefile for rubydust gem
#
# Ryan W Sims (rwsims@umd.edu)

require 'rake'
require 'rake/clean'

# Prevent OS X from including extended attribute junk in the tar output
ENV['COPY_EXTENDED_ATTRIBUTES_DISABLE'] = 'true'

CLEAN.include("lib/rtc/annot_parser.tab.rb", "lib/rtc/annot_lexer.rex.rb")

desc "Default task"
task :default => :rtc

file "lib/rtc/annot_parser.tab.rb" => "lib/rtc/annot_parser.racc" do
    sh "racc lib/rtc/annot_parser.racc"
end

file "lib/rtc/annot_lexer.rex.rb" => "lib/rtc/annot_lexer.rex" do
  sh "rex --matcheos lib/rtc/annot_lexer.rex"
end

desc "Generates the lexer from the .rex file"
task :lexer => "lib/rtc/annot_lexer.rex.rb"

desc "Generates the parser from the .racc file"
task :parser => [:lexer,"lib/rtc/annot_parser.tab.rb"]

desc "Builds rtc"
task :rtc => :parser
