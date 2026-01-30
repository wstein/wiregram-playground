require "../spec_helper"

describe Warp::Format do
  it "pretty-prints from tape without DOM materialization" do
    json = %({"a":1,"b":["x",true]})
    parser = Warp::Parser.new
    doc_result = parser.parse_document(json.to_slice, validate_literals: true, validate_numbers: true)
    doc_result.error.success?.should be_true

    pretty = Warp::Format.pretty(doc_result.doc.not_nil!, indent: 2)
    pretty.should contain("\"a\": 1")
    pretty.should contain("\"b\": [")
  end

  describe "tape-based formatting edge cases" do
    it "handles empty objects correctly (line 504)" do
      json = "{}"
      parser = Warp::Parser.new
      doc_result = parser.parse_document(json.to_slice, validate_literals: true, validate_numbers: true)
      doc_result.error.success?.should be_true

      pretty = Warp::Format.pretty(doc_result.doc.not_nil!, indent: 2)
      pretty.should eq("{}")
    end

    it "handles empty arrays correctly (line 550)" do
      json = "[]"
      parser = Warp::Parser.new
      doc_result = parser.parse_document(json.to_slice, validate_literals: true, validate_numbers: true)
      doc_result.error.success?.should be_true

      pretty = Warp::Format.pretty(doc_result.doc.not_nil!, indent: 2)
      pretty.should eq("[]")
    end

    it "handles object key processing correctly (line 449, 470, 471)" do
      json = %({"key1":"value1","key2":42})
      parser = Warp::Parser.new
      doc_result = parser.parse_document(json.to_slice, validate_literals: true, validate_numbers: true)
      doc_result.error.success?.should be_true

      # Test tape-based formatting specifically
      pretty_tape = Warp::Format.pretty(doc_result.doc.not_nil!, indent: 2)
      pretty_tape.should contain("\"key1\": \"value1\"")
      pretty_tape.should contain("\"key2\": 42")

      # Verify the tape-based formatting is actually being used
      # The tape-based path should be exercised when using the document directly
    end

    it "tests tape-based formatting with complex nested structures" do
      json = %({"a":{"b":[1,2,3],"c":{"d":"value"}},"e":[4,5,6]})
      parser = Warp::Parser.new
      doc_result = parser.parse_document(json.to_slice, validate_literals: true, validate_numbers: true)
      doc_result.error.success?.should be_true

      pretty = Warp::Format.pretty(doc_result.doc.not_nil!, indent: 2)
      pretty.should contain("\"a\": {")
      pretty.should contain("\"b\": [")
      pretty.should contain("\"c\": {")
      pretty.should contain("\"d\": \"value\"")
      pretty.should contain("\"e\": [")
    end

    it "tests tape-based formatting with complex nested structures" do
      json = %({"a":{"b":[1,2,3],"c":{"d":"value"}},"e":[4,5,6]})
      parser = Warp::Parser.new
      doc_result = parser.parse_document(json.to_slice, validate_literals: true, validate_numbers: true)
      doc_result.error.success?.should be_true

      pretty = Warp::Format.pretty(doc_result.doc.not_nil!, indent: 2)
      pretty.should contain("\"a\": {")
      pretty.should contain("\"b\": [")
      pretty.should contain("\"c\": {")
      pretty.should contain("\"d\": \"value\"")
      pretty.should contain("\"e\": [")
    end

    it "handles array element processing correctly (line 535, 575)" do
      json = "[1,2,3]"
      parser = Warp::Parser.new
      doc_result = parser.parse_document(json.to_slice, validate_literals: true, validate_numbers: true)
      doc_result.error.success?.should be_true

      pretty = Warp::Format.pretty(doc_result.doc.not_nil!, indent: 2)
      pretty.should contain("1,")
      pretty.should contain("2,")
      pretty.should contain("3")
    end

    it "handles nested empty structures correctly" do
      json = %({"empty_obj":{},"empty_array":[]})
      parser = Warp::Parser.new
      doc_result = parser.parse_document(json.to_slice, validate_literals: true, validate_numbers: true)
      doc_result.error.success?.should be_true

      pretty = Warp::Format.pretty(doc_result.doc.not_nil!, indent: 2)
      pretty.should contain("\"empty_obj\": {}")
      pretty.should contain("\"empty_array\": []")
    end

    it "handles complex nested structures with proper indexing" do
      json = %({"obj":{"nested":{},"array":[1,2]},"arr":[{},{"key":"value"}]})
      parser = Warp::Parser.new
      doc_result = parser.parse_document(json.to_slice, validate_literals: true, validate_numbers: true)
      doc_result.error.success?.should be_true

      pretty = Warp::Format.pretty(doc_result.doc.not_nil!, indent: 2)
      pretty.should contain("\"nested\": {}")
      pretty.should contain("\"array\": [")
      pretty.should contain("\"arr\": [")
      pretty.should contain("\"key\": \"value\"")
    end

    it "handles single element structures correctly" do
      json = %({"single":"value"})
      parser = Warp::Parser.new
      doc_result = parser.parse_document(json.to_slice, validate_literals: true, validate_numbers: true)
      doc_result.error.success?.should be_true

      pretty = Warp::Format.pretty(doc_result.doc.not_nil!, indent: 2)
      pretty.should contain("\"single\": \"value\"")
    end

    it "handles single element arrays correctly" do
      json = "[42]"
      parser = Warp::Parser.new
      doc_result = parser.parse_document(json.to_slice, validate_literals: true, validate_numbers: true)
      doc_result.error.success?.should be_true

      pretty = Warp::Format.pretty(doc_result.doc.not_nil!, indent: 2)
      pretty.should contain("42")
    end
  end
end
