# frozen_string_literal: true

module WireGram
  module Tools
    # LanguageServer - Foundation for building language servers
    class LanguageServer
      getter documents : Hash(String, String)

      def initialize
        @documents = {} of String => String
        @change_handler : Proc(Document, Nil)? = nil
        @completion_handler : Proc(Document, Int32, Array(String))? = nil
        @diagnostics_handler : Proc(Document, Array(String))? = nil
      end

      # Register a handler for an event
      def on(event : Symbol, &block)
        case event
        when :change
          @change_handler = block
        when :completion
          @completion_handler = block
        when :diagnostics
          @diagnostics_handler = block
        end
      end

      # Handle document changes
      def on_change(&block : Document ->)
        @change_handler = block
      end

      # Handle completion requests
      def on_completion(&block : Document, Int32 -> Array(String))
        @completion_handler = block
      end

      # Handle diagnostics requests
      def on_diagnostics(&block : Document -> Array(String))
        @diagnostics_handler = block
      end

      # Process a document change
      def process_change(uri : String, text : String)
        @documents[uri] = text
        return unless @change_handler

        fabric = WireGram.weave(text)
        @change_handler.not_nil!.call(Document.new(uri, text, fabric))
      end

      # Get completions for a document at a position
      def get_completions(uri : String, position : Int32)
        return [] of String unless @completion_handler

        text = @documents[uri]?
        return [] of String unless text

        fabric = WireGram.weave(text)
        @completion_handler.not_nil!.call(Document.new(uri, text, fabric), position)
      end

      # Get diagnostics for a document
      def get_diagnostics(uri : String)
        return [] of String unless @diagnostics_handler

        text = @documents[uri]?
        return [] of String unless text

        fabric = WireGram.weave(text)
        @diagnostics_handler.not_nil!.call(Document.new(uri, text, fabric))
      end

      # Document wrapper
      class Document
        getter uri : String
        getter text : String
        getter fabric : WireGram::Core::Fabric

        def initialize(@uri : String, @text : String, @fabric : WireGram::Core::Fabric)
        end
      end
    end
  end
end
