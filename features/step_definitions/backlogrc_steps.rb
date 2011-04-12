Given /^I create a sample backlogrc$/ do
  Dir.chdir File.expand_path('../../..', __FILE__) do |d|
    $stderr.puts "At #{d}, pwd #{Dir.pwd}"
    File.delete(BACKLOGRC) if File.exists?(BACKLOGRC)
    File.open(BACKLOGRC, "w+") do |f|
      f.puts "home: #{File.join(d,GITPATH)}"
      f.puts "origin: #{GITORIGIN}"
    end
  end
end

Then /^I have a backlogrc$/ do
  require 'lib/backlog_rc'
  rc = Backlog::BacklogRc.instance
end      
