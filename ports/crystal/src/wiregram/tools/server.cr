# frozen_string_literal: true

module WireGram
  module Tools
    # LanguageServer - Foundation for building language servers
    class LanguageServer
      attr_reader :documents, :handlers

      def initialize
        @documents = {}
        @handlers = {}
      end

      # Register a handler for an event
      def on(event, &block)
        @handlers[event] = block
      end

      # Handle document changes
      def on_change(&block)
        on(:change, &block)
      end

      # Handle completion requests
      def on_completion(&block)
        on(:completion, &block)
      end

      # Handle diagnostics requests
      def on_diagnostics(&block)
        on(:diagnostics, &block)
      end

      # Process a document change
      def process_change(uri, text)
        @documents[uri] = text

        return unless @handlers[:change]

        fabric = WireGram.weave(text)
        @handlers[:change].call(Document.new(uri, text, fabric))
      end

      # Get completions for a document at a position
      def get_completions(uri, position)
        return [] unless @handlers[:completion]

        text = @documents[uri]
        return [] unless text

        fabric = WireGram.weave(text)
        @handlers[:completion].call(Document.new(uri, text, fabric), position)
      end

      # Get diagnostics for a document
      def get_diagnostics(uri)
        return [] unless @handlers[:diagnostics]

        text = @documents[uri]
        return [] unless text

        fabric = WireGram.weave(text)
        @handlers[:diagnostics].call(Document.new(uri, text, fabric))
      end

      # Document wrapper
      class Document
        attr_reader :uri, :text, :fabric

        def initialize(uri, text, fabric)
          @uri = uri
          @text = text
          @fabric = fabric
        end
      end
    end
  end
end
