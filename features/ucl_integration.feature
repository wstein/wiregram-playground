Feature: UCL language integration
  Scenario: Processes libucl test case 1 input
    Given a ucl input:
      """
      {
      "key1": value;
      "key1": value2;
      "key1": "value;"
      "key1": 1.0,
      "key1": -0xdeadbeef
      "key1": 0xdeadbeef.1
      "key1": 0xreadbeef
      "key1": -1e-10,
      "key1": 1
      "key1": true
      "key1": no
      "key1": yes
      }
      """
    When I process the ucl input
    Then the ucl output should include:
      | key1 = "value"; |
      | key1 = "value2"; |
      | key1 = "value;"; |
      | key1 = 1.0; |
      | key1 = -3735928559; |
      | key1 = "0xdeadbeef.1"; |
      | key1 = "0xreadbeef"; |
      | key1 = -1e-10; |
      | key1 = 1; |
      | key1 = true; |
      | key1 = false; |
      | key1 = true; |
