require 'uri'
require 'cgi'
require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))

module WithinHelpers
  def with_scope(locator)
    locator ? within(locator) { yield } : yield
  end
end
World(WithinHelpers)

Then /^I should see "([^"]*)" as "([^"]*)"$/ do |arg1, arg2|
  find(:xpath, "//input[@id=\"#{arg2}\"]").value == arg1
end
