Feature: JSON language integration
  Scenario Outline: Processes JSON through the pipeline
    Given a json input "<input>"
    When I process the json input
    Then the json result should include tokens, ast, uom, output
    And the json output should be "<output>"
    And the json errors should be empty

    Examples:
      | input | output |
      | {"name": "John", "age": 30} | {"name": "John", "age": 30} |
      | {"user": {"name": "John", "address": {"city": "NYC"}}, "active": true} | {"user": {"name": "John", "address": {"city": "NYC"}}, "active": true} |
      | [1, "hello", true, null] | [1, "hello", true, null] |
      | {"users": [{"name": "John", "age": 30}, {"name": "Jane", "age": 25}], "count": 2} | {"users": [{"name": "John", "age": 30}, {"name": "Jane", "age": 25}], "count": 2} |

  Scenario: Handles pretty formatting
    Given a json input "{\"name\":\"John\",\"age\":30}"
    When I pretty process the json input
    Then the json output should include:
      | "name": "John" |
      | "age": 30 |
    And the json output should include a newline
    And the json errors should be empty

  Scenario: Handles simple Ruby structure conversion
    Given a json input "{\"name\": \"John\", \"age\": 30}"
    When I simple process the json input
    Then the json simple output should equal:
      """
      {"name": "John", "age": 30}
      """
    And the json errors should be empty

  Scenario: Handles malformed JSON
    Given a json input "{\"name\": \"John\", \"age\":}"
    When I process the json input
    Then the json errors should be present
    And the json output should be a string

  Scenario: Converts UOM to simple JSON
    Given a json input "{\"name\": \"John\", \"age\": 30, \"active\": true, \"tags\": [\"developer\", \"ruby\"]}"
    When I process the json input
    And I convert the json UOM to simple JSON
    Then the json simple output should equal:
      """
      {"name": "John", "age": 30, "active": true, "tags": ["developer", "ruby"]}
      """
