require "../spec_helper"
require "benchmark"

# Lexer Performance Benchmarks
#
# Measures tokenization speed and characteristics

module LexerBenchmark
  extend self

  CORPUS_FILES = {
    "small"  => "corpus/ruby/00_simple.rb",
    "medium" => "corpus/ruby/05_classes.rb",
    "large"  => "corpus/ruby/10_complex.rb",
    "xlarge" => "corpus/ruby/11_sorbet_annotations.rb",
  }

  def run
    puts "=" * 80
    puts "Lexer Performance Benchmarks"
    puts "Crystal #{Crystal::VERSION}"
    puts "=" * 80
    puts

    # Warm-up
    puts "Warming up..."
    CORPUS_FILES.each_value do |path|
      next unless File.exists?(path)
      source = File.read(path).to_slice
      Warp::Lang::Ruby::Lexer.scan(source)
    end
    puts

    # Benchmark tokenization speed
    puts "Tokenization Speed"
    puts "-" * 80

    CORPUS_FILES.each do |size, path|
      next unless File.exists?(path)

      source = File.read(path)
      bytes = source.to_slice
      file_size = bytes.size

      tokens = nil
      error_code = nil
      elapsed = Benchmark.measure do
        100.times do
          tokens, error_code = Warp::Lang::Ruby::Lexer.scan(bytes)
        end
      end

      token_count = tokens.try(&.size) || 0
      throughput_kb = (file_size * 100 / elapsed.total / 1024).round(2)
      throughput_tokens = (token_count * 100 / elapsed.total).round(0)
      avg_ms = (elapsed.total * 1000 / 100).round(2)

      status = error_code == Warp::Core::ErrorCode::Success ? "✓" : "✗"

      puts sprintf("  %-10s %6d bytes  %5d tokens  %8.2f ms  %10.2f KB/s  %8.0f tok/s  %s",
        size, file_size, token_count, avg_ms, throughput_kb, throughput_tokens, status)
    end

    puts

    # Token distribution analysis
    puts "Token Distribution (xlarge file)"
    puts "-" * 80

    xlarge_path = CORPUS_FILES["xlarge"]
    if File.exists?(xlarge_path)
      source = File.read(xlarge_path).to_slice
      tokens, _ = Warp::Lang::Ruby::Lexer.scan(source)

      if tokens
        # Count token types
        token_types = Hash(String, Int32).new(0)
        tokens.each do |token|
          type_name = token.kind.to_s
          token_types[type_name] += 1
        end

        # Show top 10 token types
        top_10 = token_types.to_a.sort_by { |(k, v)| -v }.first(10)
        top_10.each_with_index do |(type, count), idx|
          percentage = (count.to_f / tokens.size * 100).round(1)
          puts sprintf("  %2d. %-20s %6d (%5.1f%%)", idx + 1, type, count, percentage)
        end
      end
    end

    puts

    # Trivia handling benchmark
    puts "Whitespace/Trivia Handling"
    puts "-" * 80

    # Create a heavily whitespace-laden test
    whitespace_heavy = <<-RUBY
      class Foo

        def bar


          x = 1


          y = 2


        end


      end


    RUBY

    bytes = whitespace_heavy.to_slice

    elapsed = Benchmark.measure do
      1000.times do
        Warp::Lang::Ruby::Lexer.scan(bytes)
      end
    end

    avg_ms = (elapsed.total * 1000 / 1000).round(3)

    puts sprintf("  Whitespace-heavy code:  %.3f ms/op", avg_ms)
    puts

    puts "=" * 80
    puts "Benchmark complete"
    puts "=" * 80
  end
end

# Run if executed directly
if PROGRAM_NAME.includes?("lexer_bench")
  LexerBenchmark.run
end
