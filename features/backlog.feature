Feature: Backlog
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
      When I follow "new"
      Then I should see "New backlog entry"

      Given I am on the "New backlog entry" page
      When I fill in "Subject" with "dummy"
      And I fill in "Description" with "foo foo"
      And I fill in "Persona" with "Tester"
      And I press "Create"
      Then I should see "Backlog"
      And I should see "dummy"

   Scenario: Accessing an item
      Given I am on the home page
      Then I should see "dummy" within ".itemlist"
      When I follow "dummy"
      Then I should see "dummy" as "item_subject"
      Then I should see "foo foo" within "#description"
      And I should see "Tester" as "item_persona"

   Scenario: Bouncing a feature from mail
      Given I have a mail called "sample-mail"
      When I bounce "sample-mail" to 'backlog'
      Then "sample-mail" should appear in the backlog
