module Warp
  module Format
    def self.pretty(value : DOM::Value, indent : Int32 = 2, newline : String = "\n") : String
      build(value, pretty: true, indent: indent, newline: newline)
    end

    def self.pretty(doc : IR::Document, indent : Int32 = 2, newline : String = "\n") : String
      build_from_tape(doc, pretty: true, indent: indent, newline: newline)
    end

    def self.pretty(doc : CST::Document, indent : Int32 = 2, newline : String = "\n") : String
      build_from_cst(doc, indent: indent, newline: newline)
    end

    def self.pretty(node : AST::Node, indent : Int32 = 2, newline : String = "\n") : String
      build_from_ast(node, pretty: true, indent: indent, newline: newline)
    end

    def self.minify(value : DOM::Value) : String
      build(value, pretty: false, indent: 0, newline: "")
    end

    private def self.build(value : DOM::Value, pretty : Bool, indent : Int32, newline : String) : String
      builder = String::Builder.new
      write_value(builder, value, pretty, indent, newline, 0)
      builder.to_s
    end

    private def self.build_from_tape(doc : IR::Document, pretty : Bool, indent : Int32, newline : String) : String
      builder = String::Builder.new
      index = first_value_index(doc)
      return "" unless index
      write_tape_entry(builder, doc, index, pretty, indent, newline, 0)
      builder.to_s
    end

    private def self.build_from_cst(doc : CST::Document, indent : Int32, newline : String) : String
      builder = String::Builder.new
      root = doc.root
      write_cst_trivia(builder, doc, root.leading_trivia, indent, newline, 0)
      root.children.each do |child|
        write_cst_node(builder, doc, child, indent, newline, 0)
      end
      builder.to_s
    end

    private def self.build_from_ast(node : AST::Node, pretty : Bool, indent : Int32, newline : String) : String
      builder = String::Builder.new
      write_ast_node(builder, node, pretty, indent, newline, 0)
      builder.to_s
    end

    private def self.write_value(
      io : String::Builder,
      value : DOM::Value,
      pretty : Bool,
      indent : Int32,
      newline : String,
      level : Int32
    ) : Nil
      case value
      when Nil
        io << "null"
      when Bool
        io << (value ? "true" : "false")
      when Int64
        io << value.to_s
      when Float64
        io << value.to_s
      when String
        io << '"'
        io << escape_string(value)
        io << '"'
      when Array
        write_array(io, value, pretty, indent, newline, level)
      when Hash
        write_object(io, value, pretty, indent, newline, level)
      end
    end

    private def self.write_array(
      io : String::Builder,
      value : Array(DOM::Value),
      pretty : Bool,
      indent : Int32,
      newline : String,
      level : Int32
    ) : Nil
      if value.empty?
        io << "[]"
        return
      end

      io << '['
      if pretty
        io << newline
      end

      value.each_with_index do |entry, idx|
        if pretty
          io << (" " * ((level + 1) * indent))
        end
        write_value(io, entry, pretty, indent, newline, level + 1)
        if idx < value.size - 1
          io << ','
          io << newline if pretty
        end
      end

      if pretty
        io << newline
        io << (" " * (level * indent))
      end
      io << ']'
    end

    private def self.write_object(
      io : String::Builder,
      value : Hash(String, DOM::Value),
      pretty : Bool,
      indent : Int32,
      newline : String,
      level : Int32
    ) : Nil
      if value.empty?
        io << "{}"
        return
      end

      io << '{'
      if pretty
        io << newline
      end

      entries = value.to_a
      entries.each_with_index do |(key, val), idx|
        if pretty
          io << (" " * ((level + 1) * indent))
        end
        io << '"'
        io << escape_string(key)
        io << '"'
        io << (pretty ? ": " : ":")
        write_value(io, val, pretty, indent, newline, level + 1)
        if idx < entries.size - 1
          io << ','
          io << newline if pretty
        end
      end

      if pretty
        io << newline
        io << (" " * (level * indent))
      end
      io << '}'
    end

    private def self.escape_string(value : String) : String
      builder = String::Builder.new
      value.each_char do |ch|
        case ch
        when '"'
          builder << "\\\""
        when '\\'
          builder << "\\\\"
        when '\b'
          builder << "\\b"
        when '\f'
          builder << "\\f"
        when '\n'
          builder << "\\n"
        when '\r'
          builder << "\\r"
        when '\t'
          builder << "\\t"
        else
          if ch.ord < 0x20
            builder << "\\u%04X" % ch.ord
          else
            builder << ch
          end
        end
      end
      builder.to_s
    end

    private def self.write_ast_node(
      io : String::Builder,
      node : AST::Node,
      pretty : Bool,
      indent : Int32,
      newline : String,
      level : Int32
    ) : Nil
      case node.kind
      when AST::NodeKind::Root
        node.children.each { |child| write_ast_node(io, child, pretty, indent, newline, level) }
      when AST::NodeKind::Object
        write_ast_object(io, node, pretty, indent, newline, level)
      when AST::NodeKind::Array
        write_ast_array(io, node, pretty, indent, newline, level)
      when AST::NodeKind::Pair
        key = node.children[0]
        value = node.children[1]
        io << '"'
        io << key.value.to_s
        io << '"'
        io << (pretty ? ": " : ":")
        write_ast_node(io, value, pretty, indent, newline, level + 1)
      when AST::NodeKind::String
        io << '"'
        io << node.value.to_s
        io << '"'
      when AST::NodeKind::Number
        io << node.value.to_s
      when AST::NodeKind::True
        io << "true"
      when AST::NodeKind::False
        io << "false"
      when AST::NodeKind::Null
        io << "null"
      end
    end

    private def self.write_ast_object(
      io : String::Builder,
      node : AST::Node,
      pretty : Bool,
      indent : Int32,
      newline : String,
      level : Int32
    ) : Nil
      pairs = node.children
      if pairs.empty?
        io << "{}"
        return
      end

      io << '{'
      io << newline if pretty
      pairs.each_with_index do |pair, idx|
        if pretty
          io << (" " * ((level + 1) * indent))
        end
        write_ast_node(io, pair, pretty, indent, newline, level + 1)
        if idx < pairs.size - 1
          io << ','
          io << newline if pretty
        end
      end
      if pretty
        io << newline
        io << (" " * (level * indent))
      end
      io << '}'
    end

    private def self.write_ast_array(
      io : String::Builder,
      node : AST::Node,
      pretty : Bool,
      indent : Int32,
      newline : String,
      level : Int32
    ) : Nil
      values = node.children
      if values.empty?
        io << "[]"
        return
      end

      io << '['
      io << newline if pretty
      values.each_with_index do |value, idx|
        if pretty
          io << (" " * ((level + 1) * indent))
        end
        write_ast_node(io, value, pretty, indent, newline, level + 1)
        if idx < values.size - 1
          io << ','
          io << newline if pretty
        end
      end
      if pretty
        io << newline
        io << (" " * (level * indent))
      end
      io << ']'
    end

    private def self.write_cst_node(
      io : String::Builder,
      doc : CST::Document,
      node : CST::RedNode,
      indent : Int32,
      newline : String,
      level : Int32
    ) : Nil
      write_cst_trivia(io, doc, node.leading_trivia, indent, newline, level)
      case node.kind
      when CST::NodeKind::Object
        write_cst_object(io, doc, node, indent, newline, level)
      when CST::NodeKind::Array
        write_cst_array(io, doc, node, indent, newline, level)
      when CST::NodeKind::Pair
        key = node.children[0]
        value = node.children[1]
        write_cst_node(io, doc, key, indent, newline, level)
        io << ": "
        write_cst_node(io, doc, value, indent, newline, level + 1)
      when CST::NodeKind::String
        write_cst_string(io, doc, node)
      when CST::NodeKind::Number
        write_cst_slice(io, doc, node)
      when CST::NodeKind::True, CST::NodeKind::False, CST::NodeKind::Null
        write_cst_slice(io, doc, node)
      end
    end

    private def self.write_cst_object(
      io : String::Builder,
      doc : CST::Document,
      node : CST::RedNode,
      indent : Int32,
      newline : String,
      level : Int32
    ) : Nil
      pairs = node.children
      if pairs.empty?
        io << "{}"
        return
      end

      io << '{'
      io << newline
      pairs.each_with_index do |pair, idx|
        io << (" " * ((level + 1) * indent))
        write_cst_node(io, doc, pair, indent, newline, level + 1)
        if idx < pairs.size - 1
          io << ','
          io << newline
        end
      end
      io << newline
      io << (" " * (level * indent))
      io << '}'
    end

    private def self.write_cst_array(
      io : String::Builder,
      doc : CST::Document,
      node : CST::RedNode,
      indent : Int32,
      newline : String,
      level : Int32
    ) : Nil
      values = node.children
      if values.empty?
        io << "[]"
        return
      end

      io << '['
      io << newline
      values.each_with_index do |value, idx|
        io << (" " * ((level + 1) * indent))
        write_cst_node(io, doc, value, indent, newline, level + 1)
        if idx < values.size - 1
          io << ','
          io << newline
        end
      end
      io << newline
      io << (" " * (level * indent))
      io << ']'
    end

    private def self.write_cst_trivia(
      io : String::Builder,
      doc : CST::Document,
      trivia : Array(CST::Token),
      indent : Int32,
      newline : String,
      level : Int32
    ) : Nil
      return if trivia.empty?
      trivia.each do |token|
        case token.kind
        when CST::TokenKind::CommentLine
          io << (" " * (level * indent))
          io << String.new(doc.bytes[token.start, token.length])
          io << newline
        when CST::TokenKind::CommentBlock
          io << (" " * (level * indent))
          io << String.new(doc.bytes[token.start, token.length])
          io << newline
        else
        end
      end
    end

    private def self.write_cst_slice(io : String::Builder, doc : CST::Document, node : CST::RedNode) : Nil
      token = node.token
      return unless token
      io.write(doc.bytes[token.start, token.length])
    end

    private def self.write_cst_string(io : String::Builder, doc : CST::Document, node : CST::RedNode) : Nil
      token = node.token
      return unless token
      io << '"'
      io.write(doc.bytes[token.start, token.length])
      io << '"'
    end

    private def self.first_value_index(doc : IR::Document) : Int32?
      tape = doc.tape
      i = 0
      while i < tape.size
        entry = tape[i]
        return i unless entry.type == IR::TapeType::Root
        i += 1
      end
      nil
    end

    private def self.write_tape_entry(
      io : String::Builder,
      doc : IR::Document,
      index : Int32,
      pretty : Bool,
      indent : Int32,
      newline : String,
      level : Int32
    ) : Int32
      entry = doc.tape[index]
      case entry.type
      when IR::TapeType::StartObject
        write_object_tape(io, doc, index, pretty, indent, newline, level)
      when IR::TapeType::StartArray
        write_array_tape(io, doc, index, pretty, indent, newline, level)
      when IR::TapeType::Key
        write_string_slice(io, doc, entry)
        index + 1
      when IR::TapeType::String
        write_string_slice(io, doc, entry)
        index + 1
      when IR::TapeType::Number
        write_slice(io, doc, entry)
        index + 1
      when IR::TapeType::True
        io << "true"
        index + 1
      when IR::TapeType::False
        io << "false"
        index + 1
      when IR::TapeType::Null
        io << "null"
        index + 1
      else
        index + 1
      end
    end

    private def self.write_object_tape(
      io : String::Builder,
      doc : IR::Document,
      start_index : Int32,
      pretty : Bool,
      indent : Int32,
      newline : String,
      level : Int32
    ) : Int32
      end_index = doc.tape[start_index].b
      if end_index == start_index + 1
        io << "{}"
        return end_index + 1
      end

      io << '{'
      io << newline if pretty

      i = start_index + 1
      pair_index = 0
      while i < end_index
        if pretty
          io << (" " * ((level + 1) * indent))
        end

        key_entry = doc.tape[i]
        write_string_slice(io, doc, key_entry)
        io << (pretty ? ": " : ":")
        i += 1

        i = write_tape_entry(io, doc, i, pretty, indent, newline, level + 1)
        pair_index += 1
        if i < end_index
          io << ','
          io << newline if pretty
        end
      end

      if pretty
        io << newline
        io << (" " * (level * indent))
      end
      io << '}'
      end_index + 1
    end

    private def self.write_array_tape(
      io : String::Builder,
      doc : IR::Document,
      start_index : Int32,
      pretty : Bool,
      indent : Int32,
      newline : String,
      level : Int32
    ) : Int32
      end_index = doc.tape[start_index].b
      if end_index == start_index + 1
        io << "[]"
        return end_index + 1
      end

      io << '['
      io << newline if pretty

      i = start_index + 1
      element_index = 0
      while i < end_index
        if pretty
          io << (" " * ((level + 1) * indent))
        end
        i = write_tape_entry(io, doc, i, pretty, indent, newline, level + 1)
        element_index += 1
        if i < end_index
          io << ','
          io << newline if pretty
        end
      end

      if pretty
        io << newline
        io << (" " * (level * indent))
      end
      io << ']'
      end_index + 1
    end

    private def self.write_slice(io : String::Builder, doc : IR::Document, entry : IR::Entry) : Nil
      slice = doc.bytes[entry.a, entry.b]
      io.write(slice)
    end

    private def self.write_string_slice(io : String::Builder, doc : IR::Document, entry : IR::Entry) : Nil
      slice = doc.bytes[entry.a, entry.b]
      io << '"'
      io.write(slice)
      io << '"'
    end
  end
end
