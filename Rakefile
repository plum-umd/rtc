# Rakefile for rubydust gem
#
# Ryan W Sims (rwsims@umd.edu)

require 'rake'
require 'rake/clean'

# Prevent OS X from including extended attribute junk in the tar output
ENV['COPY_EXTENDED_ATTRIBUTES_DISABLE'] = 'true'

CLEAN.include("lib/rtc/annot_parser.tab.rb")

desc "Default task"
task :default => :rtc

file "lib/rtc/annot_parser.tab.rb" => "lib/rtc/annot_parser.racc" do
    sh "racc lib/rtc/annot_parser.racc"
end

task :parser => "lib/rtc/annot_parser.tab.rb"

desc "Builds rtc"
task :rtc => :parser