Feature: Expression language integration
  Scenario Outline: Processes basic expressions
    Given an expression input "<input>"
    When I process the expression input
    Then the expression result should include tokens, ast, uom, output
    And the expression output should be "<output>"

    Examples:
      | input | output |
      | 42 | 42 |
      | x | x |
      | "hello" | "hello" |
      | 1 + 2 | 1 + 2 |
      | 1 + 2 * 3 | 1 + 2 * 3 |
      | (1 + 2) * 3 | (1 + 2) * 3 |
      | let x = 42 | let x = 42 |

  Scenario: Processes complex programs
    Given an expression input:
      """
      let x = 42
      let y = x + 1
      x * y
      """
    When I process the expression input
    Then the expression result should include tokens, ast, uom, output
    And the expression output should be:
      """
      let x = 42
      let y = x + 1
      x * y
      """

  Scenario Outline: Reports errors for invalid expressions
    Given an expression input "<input>"
    When I process the expression input
    Then the expression errors should include:
      | type |
      | <error_type> |

    Examples:
      | input | error_type |
      | let x = | unexpected_token |
      | 1 + + 2 | unexpected_token |
      | "unclosed string | unexpected_token |

  Scenario: Processes valid simple fixture
    Given I load the expression fixture "valid/simple.txt"
    When I process the expression input
    Then the expression output should be "42"

  Scenario: Processes valid identifiers fixture
    Given I load the expression fixture "valid/identifiers.txt"
    When I process the expression input
    Then the expression output should be:
      """
      x
      variable_name
      result
      """

  Scenario: Processes valid strings fixture
    Given I load the expression fixture "valid/strings.txt"
    When I process the expression input
    Then the expression output should be:
      """
      "hello"
      "world"
      "test string"
      """

  Scenario: Processes valid arithmetic fixture
    Given I load the expression fixture "valid/arithmetic.txt"
    When I process the expression input
    Then the expression output should be:
      """
      1 + 2
      x * y
      a - b
      result / 2
      1 + 2 * 3
      (1 + 2) * 3
      """

  Scenario: Processes valid assignments fixture
    Given I load the expression fixture "valid/assignments.txt"
    When I process the expression input
    Then the expression output should be:
      """
      let x = 42
      let result = x + y
      let message = "hello"
      let value = 1 * 2 + 3
      """

  Scenario: Processes valid complex fixture
    Given I load the expression fixture "valid/complex.txt"
    When I process the expression input
    Then the expression output should match the fixture input

  Scenario Outline: Reports errors for invalid fixtures
    Given I load the expression fixture "<fixture>"
    When I process the expression input
    Then the expression errors should include:
      | type |
      | unexpected_token |

    Examples:
      | fixture |
      | invalid/incomplete.txt |
      | invalid/malformed.txt |

  Scenario: Provides core API methods
    Given an expression input "1 + 2"
    When I tokenize the expression input
    Then the expression tokens should include type and value fields
    When I parse the expression input
    Then the expression AST should be a program node
    When I transform the expression input
    Then the expression UOM should have a root
    When I serialize the expression input
    Then the expression output should be "1 + 2"
    When I process the expression input
    Then the expression output should be "1 + 2"

  Scenario: Provides pretty and simple processing
    Given an expression input "1 + 2"
    When I pretty process the expression input with indent 2
    Then the expression output should be "1 + 2"
    When I simple process the expression input
    Then the expression output should be "1 + 2"
