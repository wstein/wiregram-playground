Feature: CLI and API integration
  Scenario: Lists languages via the CLI
    When I run the CLI with args:
      | list |
    Then the CLI exit status should be 0
    And the CLI stdout should include:
      | Available languages: |
      | expression |
      | json |
      | ucl |

  Scenario: Shows help for a language
    When I run the CLI with args:
      | json |
      | help |
    Then the CLI exit status should be 0
    And the CLI stdout should include:
      | json commands: |

  Scenario: Inspects json from a file
    Given a temp file with content:
      """json
      {"a":1}
      """
    When I run the CLI with args:
      | json |
      | inspect |
      | <tempfile> |
    Then the CLI exit status should be 0

  Scenario: Inspects json with no stdin
    When I run the CLI with args:
      | json |
      | inspect |
    Then the CLI exit status should be 0

  Scenario: Rejects unknown language
    When I run the CLI with args:
      | foobar |
      | help |
    Then the CLI exit status should be 1
    And the CLI stderr should include:
      | Unknown command: foobar |

  Scenario: Exposes available languages in the API
    When I query available CLI languages
    Then the available CLI languages should include:
      | json |
      | expression |
      | ucl |

  Scenario Outline: Resolves language modules
    When I resolve the CLI language module "<language>"
    Then the resolved module should be the "<language>" language module

    Examples:
      | language |
      | json |
      | expression |
      | ucl |

  Scenario Outline: Language modules support core actions
    When I resolve the CLI language module "<language>"
    And I process "<input>" with the CLI language module
    Then the CLI language process result should include tokens, ast, output
    When I tokenize "<input>" with the CLI language module
    Then the CLI language tokens should be an array
    When I parse "<input>" with the CLI language module
    Then the CLI language AST should be a node

    Examples:
      | language | input |
      | json | {"name": "test", "value": 42} |
      | expression | let x = 10 + 20 |
      | ucl | server { port = 8080; } |
