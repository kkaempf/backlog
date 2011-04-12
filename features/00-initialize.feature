Feature: Initialize
    In order to test Backlog
    As a developer
    I want to start with a clean environment

    Background:
    Given... (common init for all scenarios)
		      
    Scenario: Start with a clean testing environment
      Given I create an empty dir for git
      And I create a sample backlogrc
      Then I have a backlogrc
      And I have an empty git repo

