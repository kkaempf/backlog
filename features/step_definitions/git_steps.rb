Given /^I create an empty dir for git$/ do
  Dir.chdir File.expand_path('../../..', __FILE__) do |d|
    system "rm -rf #{GITPATH}"
  end
end

Then /^I have an empty git repo$/ do
  require 'lib/git'
  raise unless File.directory?(Backlog::Git.instance.git.dir.path)
end
