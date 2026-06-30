@fractional
Feature: Evaluator fractional operator

  # Tests the fractional bucketing operator for consistent user assignment.
  # @fractional-v1: legacy float-based bucketing (abs(hash) / i32::MAX * 100)
  # @fractional-v2: high-precision integer bucketing ((hash * totalWeight) >> 32)

  Background:
    Given an evaluator

  Scenario Outline: Fractional operator
    Given a String-flag with key "fractional-flag" and a fallback value "fallback"
    And a context containing a nested property with outer key "user" and inner key "name", with value "<name>"
    When the flag was evaluated with details
    Then the resolved details value should be "<value>"

    @fractional-v1
    Examples: v1
      | name  | value    |
      | jack  | spades   |
      | queen | clubs    |
      | ten   | diamonds |
      | nine  | hearts   |
      | 3     | diamonds |

    @fractional-v2
    Examples: v2
      | name  | value    |
      | jack  | hearts   |
      | queen | spades   |
      | ten   | clubs    |
      | nine  | diamonds |
      | 3     | clubs    |

    @fractional-v3
    Examples: v3
      | name  | value    |
      | jack  | diamonds |
      | queen | diamonds |
      | ten   | clubs    |
      | nine  | clubs    |
      | 3     | spades   |

  Scenario Outline: Fractional operator shorthand
    Given a String-flag with key "fractional-flag-shorthand" and a fallback value "fallback"
    And a context containing a targeting key with value "<targeting_key>"
    When the flag was evaluated with details
    Then the resolved details value should be "<value>"

    @fractional-v1
    Examples: v1
      | targeting_key    | value |
      | jon@company.com  | heads |
      | jane@company.com | tails |

    @fractional-v2
    Examples: v2
      | targeting key    | value |
      | jon@company.com  | tails |
      | jane@company.com | tails |

    @fractional-v3
    Examples: v3
      | targeting key    | value |
      | jon@company.com  | tails |
      | jane@company.com | tails |

  Scenario Outline: Fractional operator with shared seed
    Given a String-flag with key "fractional-flag-A-shared-seed" and a fallback value "fallback"
    And a context containing a nested property with outer key "user" and inner key "name", with value "<name>"
    When the flag was evaluated with details
    Then the resolved details value should be "<value>"

    @fractional-v1
    Examples: v1
      | name  | value    |
      | jack  | hearts   |
      | queen | spades   |
      | ten   | hearts   |
      | nine  | diamonds |

    @fractional-v2
    Examples: v2
      | name  | value    |
      | seven | hearts   |
      | eight | diamonds |
      | nine  | clubs    |
      | two   | spades   |

    @fractional-v3
    Examples: v3
      | name  | value    |
      | seven | hearts   |
      | eight | hearts   |
      | nine  | diamonds |
      | two   | diamonds |

  @fractional-v2
  Scenario: Fractional operator with single entry always resolves to the only variant
    Given a String-flag with key "fractional-single-entry-flag" and a fallback value "fallback"
    And a context containing a targeting key with value "some-targeting-key"
    When the flag was evaluated with details
    Then the resolved details value should be "single"

  Scenario Outline: Second fractional operator with shared seed
    Given a String-flag with key "fractional-flag-B-shared-seed" and a fallback value "fallback"
    And a context containing a nested property with outer key "user" and inner key "name", with value "<name>"
    When the flag was evaluated with details
    Then the resolved details value should be "<value>"

    @fractional-v1
    Examples: v1
      | name  | value           |
      | jack  | ace-of-hearts   |
      | queen | ace-of-spades   |
      | ten   | ace-of-hearts   |
      | nine  | ace-of-diamonds |

    @fractional-v2
    Examples: v2
      | name  | value           |
      | seven | ace-of-hearts   |
      | eight | ace-of-diamonds |
      | nine  | ace-of-clubs    |
      | two   | ace-of-spades   |

    @fractional-v3
    Examples: v3
      | name  | value           |
      | seven | ace-of-hearts   |
      | eight | ace-of-hearts   |
      | nine  | ace-of-diamonds |
      | two   | ace-of-diamonds |

  # Hash edge-case vectors — keys chosen by brute-force search so their
  # MurmurHash3-x86-32 (seed=0) falls at the six critical boundary values.
  @fractional-v2
  Scenario Outline: Fractional operator hash edge cases
    Given a String-flag with key "fractional-hash-edge-flag" and a fallback value "fallback"
    And a context containing a targeting key with value "<key>"
    When the flag was evaluated with details
    Then the resolved details value should be "<value>"

    Examples:
      | key    | value |
      | ejOoVL | lower |
      | bY9fO- | lower |
      | SI7p-  | lower |
      | 6LvT0  | upper |
      | ceQdGm | upper |

  # Nested JSON Logic expressions as bucket variant names / weights.
  # Requires evaluator implementations to support the @fractional-nested feature.
  # Use -t "not @fractional-nested" to exclude during transition.

  @fractional-nested
  Scenario Outline: Fractional operator with nested if expression as variant name
    # bucket0=[if(tier=="premium","premium","standard"),50], bucket1=["standard",50]
    # jon@company.com bv(100)=36 → bucket0; user1 bv(100)=76 → bucket1
    Given an evaluator
    And a String-flag with key "fractional-nested-if-flag" and a fallback value "fallback"
    And a context containing a targeting key with value "<targetingKey>"
    And a context containing a key "tier", with type "String" and with value "<tier>"
    When the flag was evaluated with details
    Then the resolved details value should be "<value>"
    Examples:
      | targetingKey    | tier    | value    |
      | jon@company.com | premium | premium  |
      | jon@company.com | basic   | standard |
      | user1           | premium | standard |
      | user1           | basic   | standard |

  @fractional-nested
  Scenario Outline: Fractional operator with nested var expression as variant name
    # bucket0=[var("color"),50], bucket1=["blue",50]
    # jon@company.com bv(100)=36 → bucket0 (resolves var "color"); user1 bv(100)=76 → bucket1 ("blue")
    Given an evaluator
    And a String-flag with key "fractional-nested-var-flag" and a fallback value "fallback"
    And a context containing a targeting key with value "<targetingKey>"
    And a context containing a key "color", with type "String" and with value "<color>"
    When the flag was evaluated with details
    Then the resolved details value should be "<value>"
    Examples:
      | targetingKey    | color  | value    |
      | jon@company.com | red    | red      |
      | jon@company.com | green  | green    |
      | user1           | red    | blue     |
      | jon@company.com | yellow | fallback |
      | jon@company.com |        | fallback |

  @fractional-nested
  Scenario Outline: Fractional operator with nested if expression as weight
    # bucket0=["red",if(tier=="premium",100,0)], bucket1=["blue",10]
    Given an evaluator
    And a String-flag with key "fractional-nested-weight-flag" and a fallback value "fallback"
    And a context containing a targeting key with value "<targetingKey>"
    And a context containing a key "tier", with type "String" and with value "<tier>"
    When the flag was evaluated with details
    Then the resolved details value should be "<value>"
    Examples:
      | targetingKey    | tier    | value |
      | jon@company.com | premium | red   |
      | jon@company.com | basic   | blue  |
      | user1           | premium | red   |
      | user1           | basic   | blue  |

  @fractional-nested
  Scenario: Fractional as condition
    Given an evaluator
    And a String-flag with key "fractional-as-condition-flag" and a fallback value "zero"
    And a context containing a targeting key with value "some-targeting-key"
    When the flag was evaluated with details
    Then the resolved details value should be "hundreds"

  @fractional-nested
  Scenario: Fractional as condition evaluates false path
    Given an evaluator
    And a String-flag with key "fractional-as-condition-false-flag" and a fallback value "zero"
    And a context containing a targeting key with value "some-targeting-key"
    When the flag was evaluated with details
    Then the resolved details value should be "ones"

  @operator-errors
  Scenario: fractional operator with missing bucket key falls back to default variant
    Given an evaluator
    And a String-flag with key "fractional-null-bucket-key-flag" and a fallback value "wrong"
    When the flag was evaluated with details
    Then the resolved details value should be "fallback"
<<<<<<< Updated upstream
    And the reason should be "DEFAULT"

  # Follow-up error scenarios from https://github.com/open-feature/flagd/issues/1874

  @operator-errors
  Scenario: fractional with all-zero bucket weights falls back to default variant
    Given an evaluator
    And a String-flag with key "fractional-zero-weights-flag" and a fallback value "wrong"
    And a context containing a targeting key with value "any-user"
    When the flag was evaluated with details
    Then the resolved details value should be "fallback"
    And the reason should be "DEFAULT"

  @operator-errors
  Scenario: fractional negative bucket weight is clamped to zero
    # ["one", -50] is treated as ["one", 0]; "two" gets 100% of the weight
    Given an evaluator
    And a String-flag with key "fractional-negative-weight-flag" and a fallback value "wrong"
    And a context containing a targeting key with value "any-user"
    When the flag was evaluated with details
    Then the resolved details value should be "two"
=======

  @fractional-v3
  Scenario Outline: Fractional operator with basic types
    Given a String-flag with key "fractional-basic-flag" and a fallback value "fallback"
    And a context containing a key "hashing_input", with type "<type>" and with value "<hashing_input>"
    When the flag was evaluated with details
    Then the resolved details value should be "<value>"

    Examples:
      | hashing_input      | type    | value     |
      | true               | Boolean | bucket5   |
      | false              | Boolean | bucket1   |
      | user1              | String  | bucket22  |
      | user2              | String  | bucket16  |
      | 123                | Integer | bucket20  |
      | 456                | Integer | bucket12  |
      | 1.23               | Float   | bucket14  |
      | 4.56               | Float   | bucket18  |
      | 123                | String  | bucket22  | 
      | true               | String  | bucket24  | 
      | false              | String  | bucket1   | 
      | null               | String  | bucket8   | 
      | 1.23               | String  | bucket4   | 
      | 0                  | Integer | bucket8   | 

  @fractional-v3
  Scenario Outline: Fractional operator with float mapping
    Given a String-flag with key "fractional-basic-flag" and a fallback value "fallback"
    And a context containing a key "hashing_input", with type "<type>" and with value "<hashing_input>"
    When the flag was evaluated with details
    Then the resolved details value should be "<value>"

    Examples:
      | hashing_input         | type    | value    |
      | 1.0                   | Float   | bucket23 |
      | 1                     | Integer | bucket23 |
      | 1.0000000000000001    | Float   | bucket23 |
      | -2.0                  | Float   | bucket12 |
      | -2                    | Integer | bucket12 |
      | 9007199254740992.0    | Float   | bucket10 |
 
  @fractional-v3
  Scenario Outline: Fractional operator with zero values
    Given a String-flag with key "fractional-basic-flag" and a fallback value "fallback"
    And a context containing a key "hashing_input", with type "<type>" and with value "<hashing_input>"
    When the flag was evaluated with details
    Then the resolved details value should be "<value>"

    Examples:
      | hashing_input | type    | value   |
      | 0.0           | Float   | bucket8 |
      | -0.0          | Float   | bucket8 |
      | 0             | Integer | bucket8 |

  @fractional-v3
  Scenario Outline: Fractional operator with integer limits
    Given a String-flag with key "fractional-basic-flag" and a fallback value "fallback" 
    And a context containing a key "hashing_input", with type "Integer" and with value "<hashing_input>" 
    When the flag was evaluated with details 
    Then the resolved details value should be "<value>" 

    Examples:
      | hashing_input         | value     |
      | 2147483647            | bucket10  | 
      | -2147483648           | bucket8   | 
      | 23                    | bucket21  |
      | 24                    | bucket11  |
      | 255                   | bucket13  |
      | 256                   | bucket13  |
      | 65535                 | bucket4   |
      | 65536                 | bucket11  |
      | -24                   | bucket4   |
      | -25                   | bucket16  |

  @fractional-v3
  Scenario Outline: Fractional operator with floats limits
    Given a String-flag with key "fractional-basic-flag" and a fallback value "fallback"
    And a context containing a key "hashing_input", with type "Float" and with value "<hashing_input>"
    When the flag was evaluated with details
    Then the resolved details value should be "<value>"

    Examples:
      | hashing_input             | value    |
      | 1e20                      | bucket19 | 
      | -1e20                     | bucket25 |
      | 65504.0                   | bucket16 | # Max Float16
      | -65504.0                  | bucket9  | # Min Float16
      | 0.00006103515625          | bucket22 | # Min positive normal Float16
      | 0.000000059604644775390625| bucket23 | # Min positive subnormal Float16
      | 65505.0                   | bucket17 | # Exceeds Float16 max
      | -65505.0                  | bucket17 | # Exceeds Float16 min
      | 3.4028234663852886e+38    | bucket10 | # Max Float32
      | -3.4028234663852886e+38   | bucket3  | # Min Float32
      | 1.1754943508222875e-38    | bucket24 | # Min positive normal Float32
      | 3.5e+38                   | bucket1  | # Exceeds Float32 max
      | -3.5e+38                  | bucket6  | # Exceeds Float32 min
      | 1.7976931348623157e+308   | bucket17 | # Max Float64
      | -1.7976931348623157e+308  | bucket9  | # Min Float64
      | 2.2250738585072014e-308   | bucket11 | # Min positive normal Float64
      | 4.9406564584124654e-324   | bucket2  | # Min subnormal Float64 (Smallest non-zero Float64)

  @fractional-v3
  Scenario Outline: Fractional operator with map key ordering
    Given a String-flag with key "fractional-basic-flag" and a fallback value "fallback"
    And a context containing a key "hashing_input", with type "Object" and with value "<hashing_input>"
    When the flag was evaluated with details
    Then the resolved details value should be "<value>"

    Examples:
      | hashing_input                                     | value    |
      | {"a": 1, "b": 2}                                  | bucket23 |
      | {"b": 2, "a": 1}                                  | bucket23 | 
      | {"a": 1, "b": 2, "c": 3}                          | bucket18 |
      | {"c": 3, "a": 1, "b": 2}                          | bucket18 | 
      | {"z": 1, "aa": 2}                                 | bucket21 | 
      | {"aa": 2, "z": 1}                                 | bucket21 |  
      | {"a": {"b": 1}, "b": 2}                           | bucket9  | 
      | {"b": 2, "a": {"b": 1}}                           | bucket9  |
      | {"a": true, "bbb": 1, "c": "text", "dddd": 2.5}   | bucket25 |
      | {"c": "text", "bbb": 1, "a": true, "dddd": 2.5}   | bucket25 |
      | {"aaa": 1, "ÿ": 2}                                | bucket12 |
      | {"ÿ": 2, "aaa": 1}                                | bucket12 |
      | {"": 2, "abc": 1}                                 | bucket25 |
      | {"key": -0.0}                                     | bucket10 |
      | {"key": 0}                                        | bucket10 |
      | {"key": 0.0}                                      | bucket10 |
      | {"b": -0.0, "a": {"b": 1}, "c": 0.0}              | bucket8  |
      | {"c": 0.0, "b": -0.0, "a": {"b": 1}}              | bucket8  |
      | {"café": "façade", "b": {"résumé": {"ÿ": true}}}  | bucket22 |

  @fractional-v3 
  Scenario Outline: Fractional operator with advanced structures 
    Given a String-flag with key "fractional-basic-flag" and a fallback value "fallback" 
    And a context containing a key "hashing_input", with type "Object" and with value "<hashing_input>"
    When the flag was evaluated with details 
    Then the resolved details value should be "<value>" 

    Examples: 
    | hashing_input                                           | value    |  
    | {}                                                      | bucket3  |
    | {"a": {} }                                              | bucket20 | 
    | {"b": 2, "a": {} }                                      | bucket20 | 
    | {"a": {}, "b": {}}                                      | bucket21 | 
    | {"a": {}, "b": []}                                      | bucket7  |
    | {"c": 0.0, "a": []}                                     | bucket18 | 
    | {"c": 0.0, "b": -0.0, "a": {"b": []}}                   | bucket9  | 
    | {"a": [] }                                              | bucket12 |
    | {"a": [1, [], 3], "b": null}                            | bucket3  | 
    | {"a": ["a", "b", {}], "b": [1, null, 2]}                | bucket23 | 
    | {"a": [1, "two", true, [], null]}                       | bucket23 | 
    | {"a": [false, 2.5, ""], "b": [], "c": [{}], "c": null}  | bucket15 | 
    | {"x": [{"a": 1}, {"b": 2}, {"b": null}]}                | bucket3  | 
    | {"x": [{"a": {"b": []}}] }                              | bucket16 |
    | {"x": [{"a": {"b": null}}] }                            | bucket6  |  
    | {"x": [{"a": {"b": {}}}] }                              | bucket2  |
    | {"": "", "": [], "": {}, "": null}                      | bucket25 |
    | {"": {"": ""}, "": ["", {"": ""}], "": {"": {"": ""}}}  | bucket11 | 
    | {"a": [[[[[]]]]] }                                      | bucket15 |  
    | {"a": [[[[null]]]] }                                    | bucket7  |
    | {"a": {"b": {"c": {"d": {}}} } }                        | bucket21 | 
    | {"a": {"b": {"c": {"d": null}} } }                      | bucket19 |

  @fractional-v3
  Scenario Outline: Fractional operator with string length boundaries
    Given a String-flag with key "fractional-basic-flag" and a fallback value "fallback"
    And a context containing a key "hashing_input", with type "String" and with value "<hashing_input>"
    When the flag was evaluated with details
    Then the resolved details value should be "<value>"

    Examples:
      | hashing_input              | value    |
      |                            | bucket4  |
      | a                          | bucket6  | # Length 1
      | 12345678901234567890123    | bucket4  | # Length 23
      | 123456789012345678901234   | bucket14 | # Length 24
      |aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa | bucket18   | # Length 255
      |aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa | bucket7  | # Length 256 

  @fractional-v3
  Scenario Outline: Valid well-formed UTF-8 String consistency across different languages
    Given a String-flag with key "fractional-basic-flag" and a fallback value "fallback"
    And a context containing a key "hashing_input", with type "String" and with value "<hashing_input>"
    When the flag was evaluated with details
    Then the resolved details value should be "<value>"

    Examples:
      | hashing_input            | value     |
      | あいうえおかき             | bucket17  | # 7 chars, 21 bytes
      | あいうえおかきく            | bucket16  | # 8 chars, 24 bytes
      | ééééééééééé              | bucket16  |# 11 chars, 22 bytes
      | éééééééééééé             | bucket19  |# 12 chars, 24 bytes
      | café façade résumé café  | bucket9   |# 23 chars, 28 bytes
      | A\u0000B                 | bucket15  |
      | e\u0301                  | bucket7   |
      | \uD83D\uDE00             | bucket23  |

  @fractional-v3
  Scenario Outline: Fractional operator using implicit targeting key
    Given a String-flag with key "fractional-flag-shorthand" and a fallback value "draw"
    And a context containing a targeting key with value "<targeting_key>"
    When the flag was evaluated with details
    Then the resolved details value should be "<value>"

    Examples:
      | targeting_key | value |
      | user-1        | heads |
      | user-2        | tails |
      | user-3        | heads |

  @fractional-v3
  Scenario Outline: Fractional operator invalid explicit inputs
    Given a String-flag with key "fractional-flag-shorthand" and a fallback value "fallback"
    And a context containing a key "<key>", with type "<type>" and with value "<value>"
    When the flag was evaluated with details
    Then the resolved details value should be "fallback"
    Then the reason should be "ERROR"
    Examples:
      | key          | type    | value   |
      | irrelevant   | String  | none    | # Missing targetingKey entirely
      | targetingKey | Integer | 12345   | # targetingKey is not a string
      | targetingKey | Boolean | true    | # targetingKey is not a string

  @fractional-v3
  Scenario Outline: Errors and edge cases
    Given a Integer-flag with key "<key>" and a fallback value "3"
    When the flag was evaluated with details
    Then the resolved details value should be "<value>"
    And the error-code should be "<error_code>"
    Examples:
      | key                               | value | error_code  |
      | targeting-null-variant-flag       | 2     |             |
      | error-targeting-flag              | 3     | PARSE_ERROR |
      | missing-variant-targeting-flag    | 3     | GENERAL     |
      | non-string-variant-targeting-flag | 2     |             |
      | empty-targeting-flag              | 1     |             |
      | targeting-null-flag               | 3     | GENERAL     |
>>>>>>> Stashed changes
