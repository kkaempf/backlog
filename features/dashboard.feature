Feature: Dashboard
    In order to manage the backlog
    As a project manager
    I want to work on the backlog

    Background:
    Given... (common init for all scenarios)
		      
    @tag
    Scenario: Start page
      Given I have a browser
      When I go to the home page
      Then I should see "Backlog"

    Scenario: Homedir
      Given I am on the home page
      Then I should see "Dir"
