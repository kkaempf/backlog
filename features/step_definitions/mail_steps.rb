Given /^I have a mail called "([^"]*)"$/ do |arg1|
  samples_dir = File.expand_path(File.join(File.dirname(__FILE__),"..","samples"))
  raise unless File.readable?(File.join(samples_dir, arg1))
end

Given /^I have mails with features$/ do  
  $stderr.puts "Samples: #{samples_dir}"
  @mails = []
  Dir.open(samples_dir) do |d|
    d.each do |f|
      next if f[0,1] == "."
      @mails << File.join(samples_dir,f)
    end
  end
end
  
When /^I bounce "([^"]*)" to 'backlog'$/ do |arg1|
  samples_dir = File.expand_path(File.join(File.dirname(__FILE__),"..","samples"))
  $stderr.puts "Bounce #{arg1} to 'backlog'"
  File.open(File.join(samples_dir, arg1)) do |m|
    IO.popen(File.expand_path(File.join(File.dirname(__FILE__),"..","..","script","backlog")),"w") do |p|
      p.write(m.read)
    end
  end
end
    
Then /^"([^"]*)" should appear in the backlog$/ do |arg1|
  pending # express the regexp above with the code you wish you had
end
