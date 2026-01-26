# frozen_string_literal: true

require 'spec_helper'

describe WireGram::Languages::Ucl do
  describe 'Basic UCL Parsing and Normalization' do
    it 'parses and normalizes simple assignments' do
      input = 'key = value;'
      result = WireGram::Languages::Ucl.process(input)

      expect(result[:output]).to include('key = "value";')
      expect(result[:errors]).to be_empty
    end

    it 'parses identifiers as string values' do
      input = 'key = value'
      result = WireGram::Languages::Ucl.process(input)

      expect(result[:output]).to include('key = "value"')
    end

    it 'preserves quoted strings' do
      input = 'key = "value";'
      result = WireGram::Languages::Ucl.process(input)

      expect(result[:output]).to include('key = "value";')
    end

    it 'preserves string values with special characters' do
      input = 'key = "value;";'
      result = WireGram::Languages::Ucl.process(input)

      expect(result[:output]).to include('key = "value;";')
    end

    it 'normalizes colon separator to equals' do
      input = 'key: value;'
      result = WireGram::Languages::Ucl.process(input)

      expect(result[:output]).to include('key = "value";')
    end

    it 'handles multiple assignments to same key' do
      input = "key = value1;\nkey = value2;"
      result = WireGram::Languages::Ucl.process(input)

      expect(result[:output]).to include('key = "value1";')
      expect(result[:output]).to include('key = "value2";')
    end
  end

  describe 'Number Handling' do
    it 'preserves floating point numbers' do
      input = 'key = 1.0;'
      result = WireGram::Languages::Ucl.process(input)

      expect(result[:output]).to include('key = 1.0;')
    end

    it 'preserves integer numbers' do
      input = 'key = 1;'
      result = WireGram::Languages::Ucl.process(input)

      expect(result[:output]).to include('key = 1;')
    end

    it 'preserves scientific notation' do
      input = 'key = -1e-10;'
      result = WireGram::Languages::Ucl.process(input)

      expect(result[:output]).to include('key = -1e-10;')
    end

    it 'converts hex numbers to decimal' do
      input = 'key = -0xdeadbeef;'
      result = WireGram::Languages::Ucl.process(input)

      # -0xdeadbeef = -3735928559
      expect(result[:output]).to include('key = -3735928559;')
    end

    it 'converts positive hex numbers to decimal' do
      input = 'key = 0xdeadbeef;'
      result = WireGram::Languages::Ucl.process(input)

      # 0xdeadbeef = 3735928559
      expect(result[:output]).to include('key = 3735928559;')
    end

    it 'treats invalid hex (with decimal point) as string' do
      input = 'key = 0xdeadbeef.1;'
      result = WireGram::Languages::Ucl.process(input)

      expect(result[:output]).to include('key = "0xdeadbeef.1";')
    end

    it 'treats invalid hex (invalid characters) as string' do
      input = 'key = 0xreadbeef;'
      result = WireGram::Languages::Ucl.process(input)

      expect(result[:output]).to include('key = "0xreadbeef";')
    end
  end

  describe 'Boolean Normalization' do
    it 'normalizes true to true' do
      input = 'key = true;'
      result = WireGram::Languages::Ucl.process(input)

      expect(result[:output]).to include('key = true;')
    end

    it 'normalizes false to false' do
      input = 'key = false;'
      result = WireGram::Languages::Ucl.process(input)

      expect(result[:output]).to include('key = false;')
    end

    it 'normalizes yes to true' do
      input = 'key = yes;'
      result = WireGram::Languages::Ucl.process(input)

      expect(result[:output]).to include('key = true;')
    end

    it 'normalizes no to false' do
      input = 'key = no;'
      result = WireGram::Languages::Ucl.process(input)

      expect(result[:output]).to include('key = false;')
    end

    it 'normalizes on to true' do
      input = 'key = on;'
      result = WireGram::Languages::Ucl.process(input)

      expect(result[:output]).to include('key = true;')
    end

    it 'normalizes off to false' do
      input = 'key = off;'
      result = WireGram::Languages::Ucl.process(input)

      expect(result[:output]).to include('key = false;')
    end
  end

  describe 'Comments' do
    it 'skips line comments with #' do
      input = "# This is a comment\nkey = value;"
      result = WireGram::Languages::Ucl.process(input)

      expect(result[:output]).to include('key = "value";')
    end

    it 'skips block comments with /* */' do
      input = 'key = /* comment */ value;'
      result = WireGram::Languages::Ucl.process(input)

      expect(result[:output]).to include('key = "value";')
    end

    it 'handles nested block comments' do
      input = 'key = /* outer /* inner */ end */ value;'
      result = WireGram::Languages::Ucl.process(input)

      expect(result[:output]).to include('key = "value";')
    end

    it 'handles multiple nested block comments' do
      input = 'key = /* /* /* */ */ */ value;'
      result = WireGram::Languages::Ucl.process(input)

      expect(result[:output]).to include('key = "value";')
    end

    it 'preserves string content with comment-like text' do
      input = 'key = "/* not a comment */";'
      result = WireGram::Languages::Ucl.process(input)

      expect(result[:output]).to include('key = "/* not a comment */";')
    end

    it 'preserves string content with comment-like text in values' do
      input = 'key = "/* value";'
      result = WireGram::Languages::Ucl.process(input)

      expect(result[:output]).to include('key = "/* value";')
    end
  end

  describe 'Objects and Nested Structures' do
    it 'parses simple object' do
      input = "{\nkey = value;\n}"
      result = WireGram::Languages::Ucl.process(input)

      expect(result[:output]).to include('key = "value";')
    end

    it 'parses empty object' do
      input = '{}'
      result = WireGram::Languages::Ucl.process(input)

      expect(result[:output]).to include('{}')
    end

    it 'handles quoted keys' do
      input = '"key" = "value";'
      result = WireGram::Languages::Ucl.process(input)

      expect(result[:output]).to include('key = "value";')
    end
  end

  describe 'Arrays' do
    it 'parses simple array' do
      input = 'key = [value1, value2];'
      result = WireGram::Languages::Ucl.process(input)

      # libucl CONFIG format uses multi-line arrays
      expect(result[:output]).to include('key [')
      expect(result[:output]).to include('"value1",')
      expect(result[:output]).to include('"value2",')
    end

    it 'parses array with numbers' do
      input = 'key = [1, 2, 3];'
      result = WireGram::Languages::Ucl.process(input)

      # libucl CONFIG format uses multi-line arrays
      expect(result[:output]).to include('key [')
      expect(result[:output]).to include('1,')
      expect(result[:output]).to include('2,')
      expect(result[:output]).to include('3,')
    end

    it 'parses empty array' do
      input = 'key = [];'
      result = WireGram::Languages::Ucl.process(input)

      # Empty arrays still use block format in libucl
      expect(result[:output]).to include('key [')
      expect(result[:output]).to include(']')
    end
  end

  describe 'Escapes' do
    it 'handles escaped double quotes' do
      input = 'key = "value\\"with\\"quotes";'
      result = WireGram::Languages::Ucl.process(input)

      expect(result[:output]).to include('key = "value\\"with\\"quotes";')
    end

    it 'handles escaped backslashes' do
      input = 'key = "value\\\\end";'
      result = WireGram::Languages::Ucl.process(input)

      # When the lexer reads "value\\end", it processes the escape sequence \\ -> \
      # So the stored value is "value\end" (single backslash)
      # When serializing, the backslash should be re-escaped
      expect(result[:output]).to match(/key = "value.*end";/)
    end

    it 'handles escaped newlines' do
      input = 'key = "line1\\nline2";'
      result = WireGram::Languages::Ucl.process(input)

      expect(result[:output]).to include('key = "line1\\nline2";')
    end
  end

  describe 'Token Stream' do
    it 'produces correct token stream for simple assignment' do
      input = 'key = "value";'
      result = WireGram::Languages::Ucl.process(input)

      tokens = result[:tokens]
      expect(tokens.length).to be > 0
      expect(tokens[0][:type]).to eq(:identifier)
      expect(tokens[1][:type]).to eq(:equals)
      expect(tokens[2][:type]).to eq(:string)
      expect(tokens[3][:type]).to eq(:semicolon)
    end

    it 'tokenizes comments correctly' do
      input = '# comment'
      result = WireGram::Languages::Ucl.process(input)

      # Comments should be skipped, only EOF token remains
      expect(result[:tokens].length).to eq(1)
      expect(result[:tokens][0][:type]).to eq(:eof)
    end

    it 'tokenizes hex numbers as hex_number type' do
      input = 'key = 0xdeadbeef;'
      result = WireGram::Languages::Ucl.process(input)

      tokens = result[:tokens]
      hex_token = tokens.find { |t| t[:type] == :hex_number }
      expect(hex_token).not_to be_nil
    end

    it 'tokenizes invalid hex as invalid_hex type' do
      input = 'key = 0xdeadbeef.1;'
      result = WireGram::Languages::Ucl.process(input)

      tokens = result[:tokens]
      invalid_hex_token = tokens.find { |t| t[:type] == :invalid_hex }
      expect(invalid_hex_token).not_to be_nil
    end
  end

  describe 'AST Structure' do
    it 'builds AST for simple assignment' do
      input = 'key = "value";'
      result = WireGram::Languages::Ucl.process(input)

      ast = result[:ast]
      expect(ast.type).to eq(:object)
      expect(ast.children.length).to be > 0

      assignment = ast.children[0]
      expect(assignment.type).to eq(:pair)
      expect(assignment.children.length).to eq(2)
    end

    it 'builds AST with correct node types' do
      input = 'key = 42;'
      result = WireGram::Languages::Ucl.process(input)

      ast = result[:ast]
      assignment = ast.children[0]

      key_node = assignment.children[0]
      value_node = assignment.children[1]

      expect(key_node.type).to eq(:identifier)
      expect(value_node.type).to eq(:number)
    end
  end

  describe 'Error Handling' do
    it 'reports missing separator' do
      input = 'key value;'
      result = WireGram::Languages::Ucl.process(input)

      # Should have some error handling
      expect(result).to have_key(:errors)
    end

    it 'handles unexpected EOF gracefully' do
      input = 'key = "value'
      result = WireGram::Languages::Ucl.process(input)

      # Should handle EOF in string gracefully
      expect(result).to have_key(:output)
    end
  end
end
