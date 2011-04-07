def samples_dir
  File.expand_path(File.join(File.dirname(__FILE__),"..","samples"))
end

Given /^I have a mail called "([^"]*)"$/ do |arg1| #"
  raise unless File.readable?(File.join(samples_dir, arg1))
end

Given /^I have mails with features$/ do  #"
  @mails = []
  Dir.open(samples_dir) do |d|
    d.each do |f|
      next if f[0,1] == "."
      @mails << File.join(samples_dir,f)
    end
  end
end
  
When /^I bounce "([^"]*)" to 'backlog'$/ do |arg1| #"
  File.open(File.join(samples_dir, arg1)) do |m|
    IO.popen(File.expand_path(File.join(File.dirname(__FILE__),"..","..","script","backlog")),"w") do |p|
      p.write(m.read)
    end
  end
end
    
Then /^"([^"]*)" should appear in the backlog$/ do |arg1| #"
  subject = ""
  File.open(File.join(samples_dir, arg1)) do |m|
    while line = m.gets.chomp
      next unless line =~ /^Subject: (.*)$/
      subject = $1
      break
    end
  end
  if page.respond_to? :should
    page.should have_content(subject)
  else
    assert page.has_content?(subject)
  end
end
