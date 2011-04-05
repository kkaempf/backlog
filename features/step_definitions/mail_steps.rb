Given /^I have a mail with a feature$/ do
  samples_dir = File.expand_path(File.join(File.dirname(__FILE__),"..","samples"))
  $stderr.puts "Samples: #{samples_dir}"
  @mails = []
  Dir.open(samples_dir) do |d|
    d.each do |f|
      next if f[0,1] == "."
      @mails << File.join(samples_dir,f)
    end
  end
end
  
When /^I bounce it to 'backlog'$/ do
  @mails.each do |m|
    $stderr.puts "Bounce #{m} to 'backlog'"
    IO.popen(File.expand_path(File.join(File.dirname(__FILE__),"..","..","script","backlog")),"w") do |p|
      p.write(File.open(m).read)
    end
  end
end
    
Then /^it should appear in the backlog$/ do
  pending # express the regexp above with the code you wish you had
end
