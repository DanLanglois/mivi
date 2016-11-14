Feature Kill and Yank
  In order to edit text in command mode
  As a user
  I want to kill and yank text

  Scenario: x
    Given the buffer is empty
    When I insert:
    """
    foo bar baz qux
    123
    456
    789
    """
    And I go to beginning of buffer
    And I type "x"
    Then I should see pattern "^oo "

    When I go to line "2"
    And I go to end of line
    And I type "x"
    Then I should see pattern "^123456$"

    When I go to beginning of buffer
    And I type "10x"
    Then I should see pattern "^ qux$"

  Scenario: X
    Given the buffer is empty
    When I insert:
    """
    foo bar baz qux
    """
    And I go to end of line
    And I type "X"
    Then I should see pattern " qu$"

    When I type "3X"
    Then I should see pattern "baz$"

  Scenario: paste
    Given the buffer is empty
    When I insert:
    """
    foo bar baz
    
    qux
    """
    When I go to beginning of buffer
    And I type "5x"
    And I go to line "2"
    And I type "p"
    Then I should see pattern "^foo b$"
    And the cursor should be at cell (2, 0)
    When I go to beginning of buffer
    And I type "2p"
    Then I should see pattern "^afoo bfoo br"
    And the cursor should be at cell (1, 1)
    When I type "3x"
    And I go to end of buffer
    And I type "p"
    Then I should see pattern "quxfoo$"

  Scenario: Paste
    Given the buffer is empty
    When I insert:
    """
    foo bar
    baz
    qux
    """
    When I go to line "2"
    And I type "3x"
    And I go to beginning of buffer
    And I type "P"
    Then I should see pattern "^bazfoo"
    And the cursor should be at cell (1, 0)
    And I go to end of buffer
    And I type "4P"
    Then I should see pattern "^quxbazbazbazbaz"
    When I go to beginning of buffer
    And I type "5x"
    And I go to word "bar"
    And I type "P"
    Then I should see pattern "bazfobar$"
