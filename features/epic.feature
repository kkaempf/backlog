Feature: Epic
    In order to capture a new customer request
    As a product manager
    I want to enter it into the backlog    In order to get an overview

    Background:
    Given... (common init for all scenarios)
		      
    @tag
    Scenario: Start page
      Given I have a browser
      When I go to the home page
      Then I should see "Backlog"

    Scenario: Entering a feature
      Given I am on the home page
      When I press "new"
      Then I should see "New backlog entry"
