# Crystal Programming Language

This is the language reference for the Crystal programming language.

Crystal is a programming language with the following goals:

* Have a syntax similar to Ruby (but compatibility with it is not a goal).
* Be statically type-checked, but without having to specify the type of variables or method parameters.
* Be able to call C code by writing bindings to it in Crystal.
* Have compile-time evaluation and generation of code, to avoid boilerplate code.
* Compile to efficient native code.

**Crystal's standard library is documented in the [API docs](https://crystal-lang.org/api).**

## Contributing to the Language Reference

Do you consider yourself a helpful person? If you find bugs or sections
which need more clarification you're welcome to contribute to this
language reference. You can submit a pull request to this repository:
https://github.com/crystal-lang/crystal-book

Thank you very much!

### Branches

There is a separate branch for every minor Crystal release, all deployed alongside each other on https://crystal-lang.org/reference/
Typically, only branches of maintained releases receive updates, i.e. the branch for the most recent Crystal release.

* Changes that apply to the current Crystal release should go into the most recent `release/*` branch.
* Changes that apply to yet unreleased features should go into `master`. They'll be part of the `release/*` branch for the next release.
  The `master` branch is deployed at https://crystal-lang.org/reference/master/

### Building and Serving Locally

```console
$ git clone https://github.com/crystal-lang/crystal-book
$ cd crystal-book
$ pip install -r requirements.txt
```

Live preview (at http://127.0.0.1:8000):

```console
$ make serve
INFO    -  Building documentation...
INFO    -  Cleaning site directory
INFO    -  Documentation built in 3.02 seconds
INFO    -  Serving on http://127.0.0.1:8000
...
```

Build into the `site` directory (some functionality won't work if opening the files locally):

```console
$ make build
```

### devenv environment

This project includes configuration for a reproducible environment via [devenv.sh](https://devenv.sh/)
with integrated pre-commit checks.

Live preview (at http://127.0.0.1:8000):

```console
$ devenv up
Building shell ...
pre-commit-hooks.nix: hooks up to date
17:37:13 system  | serve.1 started (pid=6507)
17:37:13 serve.1 | INFO     -  Building documentation...
17:37:13 serve.1 | INFO     -  Cleaning site directory
17:37:16 serve.1 | INFO     -  Documentation built in 2.64 seconds
17:37:16 serve.1 | INFO     -  [17:37:16] Watching paths for changes: 'docs', 'mkdocs.yml'
17:37:16 serve.1 | INFO     -  [17:37:16] Serving on http://127.0.0.1:8000/reference/latest/
````

Build the site:

```console
$ devenv shell build
Building shell ...
pre-commit-hooks.nix: hooks up to date
rm -rf ./site
mkdocs build -d ./site  --strict
INFO     -  Cleaning site directory
INFO     -  Building documentation to directory: ./site
INFO     -  Documentation built in 2.43 seconds
```

Enter the development shell and build the site from there:

```console
$ devenv shell
Building shell ...
Entering shell ...

pre-commit-hooks.nix: hooks up to date
$(devenv) make build
mkdocs build -d ./site  --strict
INFO     -  Cleaning site directory
INFO     -  Building documentation to directory: ./site
INFO     -  Documentation built in 2.43 seconds
```

Run pre-commit checks on the entire repository:

```console
$ devenv ci
```

### Adding a page

To add a page, create a Markdown file in the desired location. Then, add a link in the `SUMMARY.md` file which acts as the navigation for the language reference.
---
hide:
  - toc        # Hide table of contents
  - navigation # Hide sidebar navigation
---

# Crystal Book

Welcome to the documentation for the Crystal language.

Crystal is a language for humans and computers. These materials help humans understand the language and its ecosystem.

## Learning Materials

These instructions and courses help you get to know the language and how to use it.

<div class="cards" markdown="1">
  <div class="card" markdown="1">

### [Getting started](getting_started/README.md)

Install Crystal and get it running.

* [Install](https://crystal-lang.org/install)
* [Try Online](https://play.crystal-lang.org/#/cr)
* [Crystal for Rubyists](crystal_for_rubyists/README.md)

  </div>
  <div class="card" markdown="1">

### Tutorials

Introductory material for beginners.

* [Language introduction](tutorials/basics/README.md)

  </div>
  <div class="card" markdown="1">

### Tools

* [Online Playgrounds](https://github.com/crystal-lang/crystal/wiki/Online-playgrounds)
* [IDE Integrations](https://github.com/veelenga/awesome-crystal#editor-plugins)
* [CI Integrations](guides/ci/README.md)

  </div>

  <div class="card" markdown="1">

### [External resources](https://crystal-lang.org/learning)

A collection of external resources to help you take the most of the language.

  </div>

</div>

---

## Grow in Crystal

The core documentation of the Crystal language, standard library, and tooling.

<div class="cards" markdown="1">
  <div class="card" markdown="1">

### [Language Reference](syntax_and_semantics/README.md)

Specification of the language.

  </div>
  <div class="card" markdown="1">

### [Standard Library API](https://crystal-lang.org/api)

Documentation of the standard library.

  </div>
  <div class="card" markdown="1">

### Shards

Discover the ecosystem of Crystal libraries.

* [Discovering Shards](https://crystal-lang.org/community/#shards)
* [Specification](https://github.com/crystal-lang/shards/blob/master/docs/shard.yml.adoc)
* [Shards Manual](man/shards/README.md)
* [Writing Shards](guides/writing_shards.md)

  </div>
  <div class="card" markdown="1">

### [Guides](guides/README.md)

Detailed examples for practical applications.

* [Performance](guides/performance.md)
* [Concurrency](guides/concurrency.md)
* [Testing](guides/testing.md)
* [Database](database/README.md)

  </div>
  <div class="card" markdown="1">

### The compiler

Instructions on how to use the compiler and tools.

* [Compiler manual](man/crystal/README.md)
* [Required libraries](man/required_libraries.md)
* [Platform Support](syntax_and_semantics/platform_support.md)
* [Static linking](guides/static_linking.md)

  </div>
  <div class="card" markdown="1">

### Project and Releases Information

Announcements about the language development.

* [Release Notes](https://crystal-lang.org/releases)
* [Release Policy](project/release-policy.md)
* [Crystal Blog](https://crystal-lang.org/blog)

  </div>

</div>

---

## Contribute

If you want to dive into the development of Crystal, these materials give some guidance.

<div class="cards" markdown="1">
  <div class="card" markdown="1">

### [Contributing Instructions](https://github.com/crystal-lang/crystal/blob/master/CONTRIBUTING.md)

A guide on how to open issues and contribute code to the Crystal project.

  </div>
  <div class="card" markdown="1">

### [Requests for Comments](https://github.com/crystal-lang/rfcs/pulls?q=is%3Apr+is%3Aopen+sort%3Aupdated-desc)

The [RFC process](https://github.com/crystal-lang/rfcs) provides a consistent and controlled path to discuss substantial changes in the Crystal project and form a community consensus.

  </div>
  <div class="card" markdown="1">

### [Code of Conduct](https://github.com/crystal-lang/crystal/blob/master/CODE_OF_CONDUCT.md)

Our standards and expectations about working together as a community.

  </div>
  <div class="card" markdown="1">

### [Governance document](https://crystal-lang.org/community/governance.html)

How we take the decisions that guide the language and its community.

  </div>
  <div class="card" markdown="1">

### Developer resources

* [Compiler internals](https://github.com/crystal-lang/crystal/wiki/Compiler-internals)
* [Coding style](conventions/coding_style.md)
* [Merging PRs](https://github.com/crystal-lang/crystal/wiki/Merging-PRs)

  </div>

</div>
# Summary

* [Index](README.md)
* Specification
    * [About this guide](syntax_and_semantics/README.md)
    * [The Program](syntax_and_semantics/the_program.md)
    * [Comments](syntax_and_semantics/comments.md)
    * [Documenting code](syntax_and_semantics/documenting_code.md)
    * [Literals](syntax_and_semantics/literals/README.md)
        * [Nil](syntax_and_semantics/literals/nil.md)
        * [Bool](syntax_and_semantics/literals/bool.md)
        * [Integers](syntax_and_semantics/literals/integers.md)
        * [Floats](syntax_and_semantics/literals/floats.md)
        * [Char](syntax_and_semantics/literals/char.md)
        * [String](syntax_and_semantics/literals/string.md)
        * [Symbol](syntax_and_semantics/literals/symbol.md)
        * [Array](syntax_and_semantics/literals/array.md)
        * [Hash](syntax_and_semantics/literals/hash.md)
        * [Range](syntax_and_semantics/literals/range.md)
        * [Regex](syntax_and_semantics/literals/regex.md)
        * [Tuple](syntax_and_semantics/literals/tuple.md)
        * [NamedTuple](syntax_and_semantics/literals/named_tuple.md)
        * [Proc](syntax_and_semantics/literals/proc.md)
        * [Command](syntax_and_semantics/literals/command.md)
    * [Assignment](syntax_and_semantics/assignment.md)
    * [Local variables](syntax_and_semantics/local_variables.md)
    * [Control expressions](syntax_and_semantics/control_expressions.md)
        * [Truthy and falsey values](syntax_and_semantics/truthy_and_falsey_values.md)
        * [if](syntax_and_semantics/if.md)
            * [As a suffix](syntax_and_semantics/as_a_suffix.md)
            * [As an expression](syntax_and_semantics/as_an_expression.md)
            * [Ternary if](syntax_and_semantics/ternary_if.md)
            * [if var](syntax_and_semantics/if_var.md)
            * [if var.is_a?(...)](syntax_and_semantics/if_varis_a.md)
            * [if var.responds_to?(...)](syntax_and_semantics/if_varresponds_to.md)
            * [if var.nil?](syntax_and_semantics/if_var_nil.md)
            * [if !](syntax_and_semantics/not.md)
        * [unless](syntax_and_semantics/unless.md)
        * [case](syntax_and_semantics/case.md)
        * [select](syntax_and_semantics/select.md)
        * [while](syntax_and_semantics/while.md)
            * [break](syntax_and_semantics/break.md)
            * [next](syntax_and_semantics/next.md)
        * [until](syntax_and_semantics/until.md)
        * [&&](syntax_and_semantics/and.md)
        * [||](syntax_and_semantics/or.md)
    * [Requiring files](syntax_and_semantics/requiring_files.md)
    * [Types and methods](syntax_and_semantics/types_and_methods.md)
        * [Everything is an object](syntax_and_semantics/everything_is_an_object.md)
        * [Classes and methods](syntax_and_semantics/classes_and_methods.md)
            * [new, initialize and allocate](syntax_and_semantics/new,_initialize_and_allocate.md)
            * [Methods and instance variables](syntax_and_semantics/methods_and_instance_variables.md)
            * [Type inference](syntax_and_semantics/type_inference.md)
            * [Union types](syntax_and_semantics/union_types.md)
            * [Overloading](syntax_and_semantics/overloading.md)
            * [Default parameter values and named arguments](syntax_and_semantics/default_and_named_arguments.md)
            * [Splats and tuples](syntax_and_semantics/splats_and_tuples.md)
            * [Type restrictions](syntax_and_semantics/type_restrictions.md)
            * [Return types](syntax_and_semantics/return_types.md)
            * [Method arguments](syntax_and_semantics/default_values_named_arguments_splats_tuples_and_overloading.md)
            * [Operators](syntax_and_semantics/operators.md)
            * [Visibility](syntax_and_semantics/visibility.md)
            * [Inheritance](syntax_and_semantics/inheritance.md)
                * [Virtual and abstract types](syntax_and_semantics/virtual_and_abstract_types.md)
            * [Class methods](syntax_and_semantics/class_methods.md)
            * [Class variables](syntax_and_semantics/class_variables.md)
            * [finalize](syntax_and_semantics/finalize.md)
        * [Modules](syntax_and_semantics/modules.md)
        * [Generics](syntax_and_semantics/generics.md)
        * [Structs](syntax_and_semantics/structs.md)
        * [Constants](syntax_and_semantics/constants.md)
        * [Enums](syntax_and_semantics/enum.md)
        * [Blocks and Procs](syntax_and_semantics/blocks_and_procs.md)
            * [Capturing blocks](syntax_and_semantics/capturing_blocks.md)
            * [Proc literal](syntax_and_semantics/proc_literal.md)
            * [Block forwarding](syntax_and_semantics/block_forwarding.md)
            * [Closures](syntax_and_semantics/closures.md)
        * [alias](syntax_and_semantics/alias.md)
    * [Exception handling](syntax_and_semantics/exception_handling.md)
    * [Type grammar](syntax_and_semantics/type_grammar.md)
    * [Type reflection](syntax_and_semantics/type_reflection.md)
        * [is_a?](syntax_and_semantics/is_a.md)
        * [nil?](syntax_and_semantics/nil_question.md)
        * [responds_to?](syntax_and_semantics/responds_to.md)
        * [as](syntax_and_semantics/as.md)
        * [as?](syntax_and_semantics/as_question.md)
        * [typeof](syntax_and_semantics/typeof.md)
    * [Type autocasting](syntax_and_semantics/autocasting.md)
    * [Macros](syntax_and_semantics/macros/README.md)
        * [Macro methods](syntax_and_semantics/macros/macro_methods.md)
        * [Hooks](syntax_and_semantics/macros/hooks.md)
        * [Fresh variables](syntax_and_semantics/macros/fresh_variables.md)
    * [Annotations](syntax_and_semantics/annotations/README.md)
        * [Built-in annotations](syntax_and_semantics/annotations/built_in_annotations.md)
    * [Low-level primitives](syntax_and_semantics/low_level_primitives.md)
        * [pointerof](syntax_and_semantics/pointerof.md)
        * [sizeof](syntax_and_semantics/sizeof.md)
        * [instance_sizeof](syntax_and_semantics/instance_sizeof.md)
        * [alignof](syntax_and_semantics/alignof.md)
        * [instance_alignof](syntax_and_semantics/instance_alignof.md)
        * [offsetof](syntax_and_semantics/offsetof.md)
        * [Uninitialized variable declaration](syntax_and_semantics/declare_var.md)
        * [asm](syntax_and_semantics/asm.md)
    * [Compile-time flags](syntax_and_semantics/compile_time_flags.md)
        * [Cross-compilation](syntax_and_semantics/cross-compilation.md)
    * [C bindings](syntax_and_semantics/c_bindings/README.md)
        * [lib](syntax_and_semantics/c_bindings/lib.md)
        * [fun](syntax_and_semantics/c_bindings/fun.md)
            * [out](syntax_and_semantics/c_bindings/out.md)
            * [to_unsafe](syntax_and_semantics/c_bindings/to_unsafe.md)
        * [struct](syntax_and_semantics/c_bindings/struct.md)
        * [union](syntax_and_semantics/c_bindings/union.md)
        * [enum](syntax_and_semantics/c_bindings/enum.md)
        * [Variables](syntax_and_semantics/c_bindings/variables.md)
        * [Constants](syntax_and_semantics/c_bindings/constants.md)
        * [type](syntax_and_semantics/c_bindings/type.md)
        * [alias](syntax_and_semantics/c_bindings/alias.md)
        * [Callbacks](syntax_and_semantics/c_bindings/callbacks.md)
    * [Unsafe code](syntax_and_semantics/unsafe.md)
* [Guides](guides/README.md)
    * [Performance](guides/performance.md)
    * [Concurrency](guides/concurrency.md)
    * [Testing](guides/testing.md)
        * [Code Coverage](guides/testing/code_coverage.md)
    * [Writing Shards](guides/writing_shards.md)
        * [Hosting on GitHub](guides/hosting/github.md)
        * [Hosting on GitLab](guides/hosting/gitlab.md)
    * [Continuous Integration](guides/ci/README.md)
        * [GitHub Actions](guides/ci/gh-actions.md)
        * [CircleCI](guides/ci/circleci.md)
    * [Build Docker Image](guides/build_docker_image.md)
    * [Static Linking](guides/static_linking.md)
    * [Crystal for Rubyists](crystal_for_rubyists/README.md)
        * [Metaprogramming Help](crystal_for_rubyists/metaprogramming_help.md)
    * [Database](database/README.md)
        * [Connection](database/connection.md)
        * [Connection pool](database/connection_pool.md)
        * [Transactions](database/transactions.md)
    * [Coding style](conventions/coding_style.md)
    * [Runtime Tracing](guides/runtime_tracing.md)
* [Tutorials](tutorials/README.md)
    * [Getting started](getting_started/README.md)
        * [An HTTP Server](getting_started/http_server.md)
        * [A Command Line Application](getting_started/cli.md)
    * [Language introduction](tutorials/basics/README.md)
        * [Hello World](tutorials/basics/10_hello_world.md)
        * [Variables](tutorials/basics/20_variables.md)
        * [Math](tutorials/basics/30_math.md)
        * [Strings](tutorials/basics/40_strings.md)
        * [Control Flow](tutorials/basics/50_control_flow.md)
        * [Methods](tutorials/basics/60_methods.md)
* [Manuals](man/README.md)
    * [Using the Compiler](man/crystal/README.md)
    * [The Shards Command](man/shards/README.md)
    * [Required libraries](man/required_libraries.md)
    * [Platform Support](syntax_and_semantics/platform_support.md)
    * [Release Policy](project/release-policy.md)
# Coding Style

This style is used in the standard library. You can use it in your own project to make it familiar to other developers.

## Naming

**Type names** are PascalCased. For example:

```crystal
class ParseError < Exception
end

module HTTP
  class RequestHandler
  end
end

alias NumericValue = Float32 | Float64 | Int32 | Int64

lib LibYAML
end

struct TagDirective
end

enum Time::DayOfWeek
end
```

**Method names** are snake_cased. For example:

```crystal
class Person
  def first_name
  end

  def date_of_birth
  end

  def homepage_url
  end
end
```

**Variable names** are snake_cased. For example:

```crystal
class Greeting
  @@default_greeting = "Hello world"

  def initialize(@custom_greeting = nil)
  end

  def print_greeting
    greeting = @custom_greeting || @@default_greeting
    puts greeting
  end
end
```

**Constants** are SCREAMING_SNAKE_CASED. For example:

```crystal
LUCKY_NUMBERS     = [3, 7, 11]
DOCUMENTATION_URL = "http://crystal-lang.org/docs"
```

**Exception messages** are Sentence cased, although code or acronyms may start a message in lowercase. For example:

```crystal
raise ArgumentError.new("Cannot create a string with a null pointer")
raise RuntimeError.new("getpeername failed")
{% raise "Expected size to be an integer literal" %}
```

### Acronyms

In class names, acronyms are *all-uppercase*. For example, `HTTP`, and `LibXML`.

In method names, acronyms are *all-lowercase*. For example `#from_json`, `#to_io`.

### Libs

`Lib` names are prefixed with `Lib`. For example: `LibC`, `LibEvent2`.

### Directory and File Names

Within a project:

* `/` contains a readme, any project configurations (eg, CI or editor configs), and any other project-level documentation (eg, changelog or contributing guide).
* `src/` contains the project's source code.
* `spec/` contains the [project's specs](../guides/testing.md), which can be run with `crystal spec`.
* `bin/` contains any executables.

File paths match the namespace of their contents. Files are named after the class or namespace they define, with *snake_case*.

For example, `HTTP::WebSocket` is defined in `src/http/web_socket.cr`.

## Indentation

Use **two spaces** to indent code inside namespaces, methods, blocks or other nested contexts. For example:

```crystal
module Scorecard
  class Parser
    def parse(score_text)
      begin
        score_text.scan(SCORE_PATTERN) do |match|
          handle_match(match)
        end
      rescue err : ParseError
        # handle error ...
      end
    end
  end
end
```

Within a class, separate method definitions, constants and inner class definitions with **one newline**. For example:

```crystal
module Money
  CURRENCIES = {
    "EUR" => 1.0,
    "ARS" => 10.55,
    "USD" => 1.12,
    "JPY" => 134.15,
  }

  class Amount
    getter :currency, :value

    def initialize(@currency, @value)
    end
  end

  class CurrencyConversion
    def initialize(@amount, @target_currency)
    end

    def amount
      # implement conversion ...
    end
  end
end
```
# Crystal for Rubyists

Although Crystal has a Ruby-like syntax, Crystal is a different language, not another Ruby implementation. For this reason, and mostly because it's a compiled, statically typed language, the language has some big differences when compared to Ruby.

## Crystal as a compiled language

### Using the `crystal` command

If you have a program `foo.cr`:

```crystal
# Crystal
puts "Hello world"
```

When you execute one of these commands, you will get the same output:

```console
$ crystal foo.cr
Hello world
$ ruby foo.cr
Hello world
```

It looks like `crystal` interprets the file, but what actually happens is that the file `foo.cr` is first compiled to a temporary executable and then this executable is run. This behaviour is very useful in the development cycle as you normally compile a file and want to immediately execute it.

If you just want to compile it you can use the `build` command:

```console
$ crystal build foo.cr
```

This creates a `foo` executable, which you can then run with `./foo`.

Note that this creates an executable that is not optimized. To optimize it, pass the `--release` flag:

```console
$ crystal build foo.cr --release
```

When writing benchmarks or testing performance, always remember to compile in release mode.

You can check other commands and flags by invoking `crystal` without arguments, or `crystal` with a command and no arguments (for example `crystal build` will list all flags that can be used with that command). Alternatively, you can read [the manual](../man/crystal/README.md).

## Types

### Bool

`true` and `false` are of type [`Bool`](https://crystal-lang.org/api/Bool.html) rather than instances of classes `TrueClass` or `FalseClass`.

### Integers

For Ruby's `Integer` type, use one of Crystal's integer types `Int8`, `Int16`, `Int32`, `Int64`, `UInt8`, `UInt16`, `UInt32`, or `UInt64`.

If any operation on a Ruby immediate integer value exceeds machine's native word size, the value is automatically converted to a heap-allocated arbitrary-precision integer object.
Crystal will instead raise an `OverflowError` on overflow. For example:

```crystal
x = 127_i8 # An Int8 type
x          # => 127
x += 1     # Unhandled exception: Arithmetic overflow (OverflowError)
```

Crystal's standard library provides number types with arbitrary size and precision: [`BigDecimal`](https://crystal-lang.org/api/BigDecimal.html), [`BigFloat`](https://crystal-lang.org/api/BigFloat.html), [`BigInt`](https://crystal-lang.org/api/BigInt.html), [`BigRational`](https://crystal-lang.org/api/BigRational.html).

See the language reference on [Integers](../syntax_and_semantics/literals/integers.md).

### Regex

Global variables ``$` `` and `$'` are not supported (yet `$~` and `$1`, `$2`, ... are present). Use `$~.pre_match` and `$~.post_match`. [Read more](https://github.com/crystal-lang/crystal/issues/1202#issuecomment-136526633).

## Pared-down instance methods

In Ruby where there are several methods for doing the same thing, in Crystal there may be only one.
Specifically:

| Ruby Method               | Crystal Method        |
|---------------------------|-----------------------|
| `Enumerable#detect`       | `Enumerable#find`     |
| `Enumerable#collect`      | `Enumerable#map`      |
| `Object#respond_to?`      | `Object#responds_to?` |
| `length`, `size`, `count` | `size`                |

## Omitted Language Constructs

Where Ruby has a a couple of alternative constructs, Crystal has one.

* trailing `while`/`until` are missing. Note however that [if as a suffix](../syntax_and_semantics/as_a_suffix.md) is still available
* `and` and `or`: use `&&` and `||` instead with suitable parentheses to indicate precedence
* Ruby has `Kernel#proc`, `Kernel#lambda`, `Proc#new` and `->`, while Crystal uses `Proc(*T, R).new` and `->` (see [this](../syntax_and_semantics/blocks_and_procs.md) for reference).
* For `require_relative "foo"` use `require "./foo"`

## No autosplat for arrays and enforced maximum block arity

```cr
[[1, "A"], [2, "B"]].each do |a, b|
  pp a
  pp b
end
```

will generate an error message like

```text
    in line 1: too many block arguments (given 2, expected maximum 1)
```

However omitting unneeded arguments is fine (as it is in Ruby), ex:

```cr
[[1, "A"], [2, "B"]].each do # no arguments
  pp 3
end
```

Or

```cr
def many
  yield 1, 2, 3
end

many do |x, y| # ignoring value passed in for "z" is OK
  puts x + y
end
```

There is autosplat for tuples:

```cr
[{1, "A"}, {2, "B"}].each do |a, b|
  pp a
  pp b
end
```

will return the result you expect.

You can also explicitly unpack to get the same result as Ruby's autosplat:

```cr
[[1, "A"], [2, "B"]].each do |(a, b)|
  pp a
  pp b
end
```

Following code works as well, but prefer former.

```cr
[[1, "A"], [2, "B"]].each do |e|
  pp e[0]
  pp e[1]
end
```

## `#each` returns nil

In Ruby `.each` returns the receiver for many built-in collections like `Array` and `Hash`, which allows for chaining methods off of that, but that can lead to some performance and codegen issues in Crystal, so that feature is not supported. Alternately, one can use `.tap`.

Ruby:

```ruby
[1, 2].each { "foo" } # => [1, 2]
```

Crystal:

```crystal
[1, 2].each { "foo" }       # => nil
[1, 2].tap &.each { "foo" } # => [1, 2]
```

[Reference](https://github.com/crystal-lang/crystal/pull/3815#issuecomment-269978574)

## Reflection and Dynamic Evaluation

`Kernel#eval()` and the weird `Kernel#autoload()` are omitted. Object and class introspection methods `Object#kind_of?()`, `Object#methods`, `Object#instance_methods`, and `Class#constants`, are omitted as well.

In some cases [macros](../syntax_and_semantics/macros/README.md) can be used for reflection.

## Semantic differences

### Single versus double-quoted strings

In Ruby, string literals can be delimited with single or double quotes. A double-quoted string in Ruby is subject to variable interpolation inside the literal, while a single-quoted string is not.

In Crystal, string literals are delimited with double quotes only. Single quotes act as character literals just like say C-like languages. As with Ruby, there is variable interpolation inside string literals.

In sum:

```ruby
X = "ho"
puts '"cute"' # Not valid in Crystal, use "\"cute\"", %{"cute"}, or %("cute")
puts "Interpolate #{X}"  # works the same in Ruby and Crystal.
```

Triple quoted strings literals of Ruby or Python are not supported, but string literals can have newlines embedded in them:

```ruby
"""Now,
what?""" # Invalid Crystal use:
"Now,
what?"  # Valid Crystal
```

Crystal supports many [percent string literals](../syntax_and_semantics/literals/string.md#percent-string-literals), though.

### The `[]` and `[]?` methods

In Ruby the `[]` method generally returns `nil` if an element by that index/key is not found. For example:

```ruby
# Ruby
a = [1, 2, 3]
a[10] #=> nil

h = {a: 1}
h[1] #=> nil
```

In Crystal an exception is thrown in those cases:

```crystal
# Crystal
a = [1, 2, 3]
a[10] # => raises IndexError

h = {"a" => 1}
h[1] # => raises KeyError
```

The reason behind this change is that it would be very annoying to program in this way if every `Array` or `Hash` access could return `nil` as a potential value. This wouldn't work:

```crystal
# Crystal
a = [1, 2, 3]
a[0] + a[1] # => Error: undefined method `+` for Nil
```

If you do want to get `nil` if the index/key is not found, you can use the `[]?` method:

```crystal
# Crystal
a = [1, 2, 3]
value = a[4]? # => return a value of type Int32 | Nil
if value
  puts "The number at index 4 is : #{value}"
else
  puts "No number at index 4"
end
```

The `[]?` is just a regular method that you can (and should) define for a container-like class.

Another thing to know is that when you do this:

```crystal
# Crystal
h = {1 => 2}
h[3] ||= 4
```

the program is actually translated to this:

```crystal
# Crystal
h = {1 => 2}
h[3]? || (h[3] = 4)
```

That is, the `[]?` method is used to check for the presence of an index/key.

Just as `[]` doesn't return `nil`, some `Array` and `Hash` methods also don't return nil and raise an exception if the element is not found: `first`, `last`, `shift`, `pop`, etc. For these a question-method is also provided to get the `nil` behaviour: `first?`, `last?`, `shift?`, `pop?`, etc.

***

The convention is for `obj[key]` to return a value or else raise if `key` is missing (the definition of "missing" depends on the type of `obj`) and for `obj[key]?` to return a value or else nil if `key` is missing.

For other methods, it depends. If there's a method named `foo` and another `foo?` for the same type, it means that `foo` will raise on some condition while `foo?` will return nil in that same condition. If there's just the `foo?` variant but no `foo`, it returns a truthy or falsey value (not necessarily `true` or `false`).

Examples for all of the above:

* `Array#[](index)` raises on out of bounds, `Array#[]?(index)` returns nil in that case.
* `Hash#[](key)` raises if the key is not in the hash, `Hash#[]?(key)` returns nil in that case.
* `Array#first` raises if the array is empty (there's no "first", so "first" is missing), while `Array#first?` returns nil in that case. Same goes for pop/pop?, shift/shift?, last/last?
* There's `String#includes?(obj)`, `Enumerable#includes?(obj)` and `Enumerable#all?`, all of which don't have a non-question variant. The previous methods do indeed return true or false, but that is not a necessary condition.

### `for` loops

`for` loops are not supported. Instead, we encourage you to use `Enumerable#each`. If you still want a `for`, you can add them via macro:

```crystal
macro for(expr)
  {{expr.args.first.args.first}}.each do |{{expr.name.id}}|
    {{expr.args.first.block.body}}
  end
end

for i ∈ [1, 2, 3] do # You can replace ∈ with any other word or character, just not `in`
  puts i
end
# note the trailing 'do' as block-opener!
```

### Methods

In Ruby, the following will raise an argument error:

```ruby
def process_data(a, b)
  # do stuff...
end

process_data(b: 2, a: "one")
```

This is because, in Ruby, `process_data(b: 2, a: "one")` is syntax sugar for `process_data({b: 2, a: "one"})`.

In Crystal, the compiler will treat `process_data(b: 2, a: "one")` as calling `process_data` with the named arguments `b: 2` and `a: "one"`, which is the same as `process_data("one", 2)`.

### Properties

The Ruby `attr_accessor`, `attr_reader` and `attr_writer` methods are replaced by macros with different names:

| Ruby Keyword    | Crystal    |
|-----------------|------------|
| `attr_accessor` | `property` |
| `attr_reader`   | `getter`   |
| `attr_writer`   | `setter`   |

Example:

```crystal
getter :name, :bday
```

In addition, Crystal added accessor macros for nilable or boolean instance variables. They have a question mark (`?`) in the name:

| Crystal     |
|-------------|
| `property?` |
| `getter?`   |

Example:

```crystal
class Person
  getter? happy = true
  property? sad = true
end

p = Person.new

p.sad = false

puts p.happy?
puts p.sad?
```

Even though this is for booleans, you can specify any type:

```crystal
class Person
  getter? feeling : String = "happy"
end

puts Person.new.feeling?
# => happy
```

Read more about [getter?](https://crystal-lang.org/api/Object.html#getter?(*names,&block)-macro) and/or [property?](https://crystal-lang.org/api/Object.html#property?(*names,&block)-macro) in the documentation.

### Consistent dot notation

For example `File::exists?` in Ruby becomes `File.exists?` in Crystal.

### Crystal keywords

Crystal added some new keywords, these can still be used as method names, but need to be called explicitly with a dot: e.g. `self.select { |x| x > "good" }`.

#### Available keywords

```text
abstract   do       if                nil?            return      uninitialized
alias      else     in                of              select      union
as         elsif    include           out             self        unless
as?        end      instance_sizeof   pointerof       sizeof      until
asm        ensure   is_a?             previous_def    struct      verbatim
begin      enum     lib               private         super       when
break      extend   macro             protected       then        while
case       false    module            require         true        with
class      for      next              rescue          type        yield
def        fun      nil               responds_to?    typeof
```

### Private methods

Crystal requires each private method to be prefixed with the `private` keyword:

```crystal
private def method
  42
end
```

### Hash syntax from Ruby to Crystal

Crystal introduces a data type that is not available in Ruby, the [`NamedTuple`](https://crystal-lang.org/api/NamedTuple.html).

Typically in Ruby you can define a hash with several syntaxes:

```ruby
# A valid Ruby Hash declaration
{
  key1: "some value",
  some_key2: "second value"
}

# This syntax in Ruby is shorthand for the hash rocket => syntax
{
  :key1 => "some value",
  :some_key2 => "second value"
}
```

In Crystal, this is not the case. The `Hash` rocket `=>` syntax is required to declare a hash in Crystal.

However, the `Hash` shorthand syntax in Ruby creates a `NamedTuple` in Crystal.

```crystal
# Creates a valid `Hash(Symbol, String)` in Crystal
{
  :key1      => "some value",
  :some_key2 => "second value",
}

# Creates a `NamedTuple(key1: String, some_key2: String)` in Crystal
{
  key1:      "some value",
  some_key2: "second value",
}
```

`NamedTuple`s and regular [`Tuple`s](https://crystal-lang.org/api/Tuple.html) have a fixed size, so these are best used for data structures that are known at compile time.

### Pseudo Constants

Crystal provides a few pseudo-constants which provide reflective data about the source code being executed.

> [Read more about Pseudo Constants in the Crystal documentation.](../syntax_and_semantics/constants.md#pseudo-constants)

| Crystal | Ruby | Description |
| ------- | ---- | ----------- |
| `__FILE__` | `__FILE__` | The full path to the currently executing Crystal file. |
| `__DIR__` | `__dir__` | The full path to the directory where the currently executing Crystal file is located. |
| `__LINE__` | `__LINE__` | The current line number in the currently executing Crystal file. |
| `__END_LINE__` | - | The line number of the end of the calling block. Can only be used as a default value to a method parameter. |

> TIP: Further reading about `__DIR__` vs. `__dir__`:
>
> * [Add an alias for `__dir__` [to Crystal]?](https://github.com/crystal-lang/crystal/issues/8546#issuecomment-561245178)
> * [Stack Overflow: Why is `__FILE__` uppercase and `__dir__` lowercase [in Ruby]?](https://stackoverflow.com/questions/15190700/why-is-file-uppercase-and-dir-lowercase)

## Crystal Shards for Ruby Gems

Many popular Ruby gems have been ported or rewritten in Crystal. [Here are some of the equivalent Crystal Shards for Ruby Gems](https://github.com/crystal-lang/crystal/wiki/Crystal-Shards-for-Ruby-Gems).

***

For other questions regarding differences between Ruby and Crystal, visit the [FAQ](https://github.com/crystal-lang/crystal/wiki/FAQ).
# Metaprogramming

Metaprogramming in Crystal is not the same as in Ruby. The links on this page will hopefully provide some insight into those differences and how to overcome them.

## Differences between Ruby and Crystal

Ruby makes heavy use of `send`, `method_missing`, `instance_eval`, `class_eval`, `eval`, `define_method`, `remove_method`, and others for making code modifications at runtime. It also supports `include`, `prepend` and `extend` for adding modules to other modules to create new class or instance methods at runtime. Herein lies the biggest difference between the two languages: Crystal does not allow for runtime code generation. All Crystal code must be generated and compiled prior to executing the final binary.

Therefore, many of those mechanisms listed above do not even exist. Of the methods listed above, Crystal has some support only for `method_missing` via a macro facility. Read the official docs on macros to understand them, but note that the macro is used to define valid Crystal methods during the compile step, so all receivers and method names must be known ahead of time. You can't build a method name from a string or symbol and `send` it to a receiver; there is no support for `send` and the compile will fail.

Crystal does support `include` and `extend`. But all code included or extended must be valid Crystal to compile.

## How to Translate Some Ruby Tricks to Crystal

But all is not lost for the intrepid metaprogrammer! Crystal still has powerful facilities for compile-time code generation. We just need to adjust our Ruby techniques a bit to work under the Crystal environment.

### Overriding #new via `extend`

In Ruby we can do some powerful things by overriding the `new` method on a class.

```ruby
module ClassMethods
  def new(*args)
    puts "Calling overridden new method with args #{args.inspect}"
    # Can do arbitrary setup or calculations here...
    instance = allocate
    instance.send(:initialize, *args) # need to use #send since #initialize is private
    instance
  end
end

class Foo
  def initialize(name)
    puts "Calling Foo.new with arg #{name}"
  end
end

foo = Foo.new('Quxo') # => Calling Foo.new with arg Quxo
p foo.class # => Foo

class Foo
  extend ClassMethods
end

foo = Foo.new('Quxo')
# => Calling overridden new method with args ["Quxo"]
# => Calling Foo.new with arg Quxo
p foo.class # => Foo
```

As seen in the example above, the `Foo` instance calls its normal constructor. When we `extend` it and override `new` we can inject all sorts of things into the process. The above example shows minimal interference and just allocates an instance of the object and initializes it. This instance is returned back from the constructor.

In the next example, we override `new` and return a completely different kind of class!

```ruby
class Bar
  def initialize(foo)
    puts "This arg was an instance of class #{foo.class}"
  end
end

module ClassMethods
  def new(*args)
    puts "Calling overridden new method with args #{args.inspect}"
    Bar.new(allocate) # return a completely different class instance
  end
end

class Foo
  extend ClassMethods

  def initialize(name)
    puts "Calling Foo.new with arg #{name}"
  end
end

foo = Foo.new('Quxo')
# => Calling overridden new method with args ["Quxo"]
# => This arg was an instance of class Foo
p foo.class # => Bar
```

This allows for very powerful meta programming at runtime. We can wrap a class in another class as a proxy and return a reference to this new proxy object.

Is the same kind of magic possible with Crystal? I wouldn't have written this section if it were impossible. But it does have some caveats that we'll get to later.

Here's the original class in Crystal and the expected behavior.

```crystal
module ClassMethods
  macro extended
    def self.new(number : Int32)
      puts "Calling overridden new added from extend hook, arg is #{number}"
      instance = allocate
      instance.initialize(number)
      instance
    end
  end
end

class Foo
  extend ClassMethods
  @number : Int32

  def initialize(number)
    puts "Foo.initialize called with number #{number}"
    @number = number
  end
end

foo = Foo.new(5)
# => Calling overridden new added from extend hook, arg is 5
# => Foo.initialize called with number 5
puts foo.class # Foo
```

This example makes use of the `macro extended` hook. This hook is called whenever a class body executes the `extend` method. We are able to use this macro to write a replacement `new` method.

(Need clarity on the method signature details. Removing the @number type declaration Foo  causes the override to silently fail. Adding "number : Int32" to the Foo class initialize signature also causes the override to fail. There are some subtleties here with method overloads that I am missing. Need more experimentation. Examples above still work though...)

### Generating Methods via `method_missing` Macro

Following is a very simple example that demonstrates how to use `method_missing` macro to create the missing method based on the existence of receiver JSON object's key

```cr
class Hashr
  getter obj

  def initialize(json : Hash(String, JSON::Any) | JSON::Any)
    @obj = json
  end

  macro method_missing(key)
    def {{ key.id }}
      value = obj[{{ key.id.stringify }}]

      Hashr.new(value)
    end
  end

  def ==(other)
    obj == other
  end
end
```

### How to Mimic `send` Using `record`s and Generated Lookup Tables

Sample code + explanation

### Crystal Approach to `alias_method`

Sometimes we want to reopen a class and redefine a previously defined method to have some new behavior. Plus, we probably want the original method to still be accessible too. In Ruby, we use `alias_method` for this purpose. Example:

```ruby
class Klass
  def salute
    puts "Aloha!"
  end
end

Klass.new.salute # => Aloha!

class Klass
  def salute_with_log
    puts "Calling method..."
    salute_without_log
    puts "... Method called"
  end

  alias_method :salute_without_log, :salute
  alias_method :salute, :salute_with_log
end

Klass.new.salute
# => Calling method...
# => Aloha!
# => ... Method called
```

Performing the same work in Crystal is fairly straight forward. Crystal provides a method called `previous_def` which can access the previously defined version of the method. To make the same example work in Crystal, it would look similar to this:

```crystal
class Klass
  def salute
    puts "Aloha!"
  end
end

# Reopen the class...
class Klass
  def salute
    puts "Calling method..."
    previous_def
  end
end

# Reopen it again for kicks!
class Klass
  def salute
    previous_def
    puts "... Method called"
  end
end

Klass.new.salute
# => Calling method...
# => Aloha!
# => ... Method called
```

Each time we reopen the class `previous_def` is set to the prior method definition so we can use this to build an alias method chain at compile time much like in Ruby. However, we do lose access to the original method definition each time we extend the chain. Unlike in Ruby where we are giving the old method an explicit name that we could refer to somewhere else, Crystal does not provide that facility.

### General Resources

Ary Borenszweig (@asterite on gitter) gave a talk at a conference in 2016 covering macros. It can be [seen here](https://vimeo.com/190927958).
# Database

To access a relational database you will need a shard designed for the database server you want to use. The package [crystal-lang/crystal-db](https://github.com/crystal-lang/crystal-db) offers a unified api across different drivers.

The following packages are compliant with crystal-db

* [crystal-lang/crystal-sqlite3](https://github.com/crystal-lang/crystal-sqlite3) for sqlite
* [crystal-lang/crystal-mysql](https://github.com/crystal-lang/crystal-mysql) for mysql & mariadb
* [will/crystal-pg](https://github.com/will/crystal-pg) for postgres

And several [more](https://github.com/crystal-lang/crystal-db).

This guide presents the api of crystal-db, the sql commands might need to be adapted for the concrete driver due to differences between postgres, mysql and sqlite.

Also some drivers may offer additional functionality like postgres `LISTEN`/`NOTIFY`.

## Installing the shard

Choose the appropriate driver from the list above and add it as any shard to your application's `shard.yml`

There is no need to explicitly require `crystal-lang/crystal-db`

During this guide `crystal-lang/crystal-mysql` will be used.

```yaml
dependencies:
  mysql:
    github: crystal-lang/crystal-mysql
```

## Open database

`DB.open` will allow you to easily connect to a database using a connection uri. The schema of the uri determines the expected driver. The following sample connects to a local mysql database named test with user root and password blank.

```crystal
require "db"
require "mysql"

DB.open "mysql://root@localhost/test" do |db|
  # ... use db to perform queries
end
```

Other connection uris are

* `sqlite3:///path/to/data.db`
* `mysql://user:password@server:port/database`
* `postgres://user:password@server:port/database`

Alternatively you can use a non yielding `DB.open` method as long as `Database#close` is called at the end.

```crystal
require "db"
require "mysql"

db = DB.open "mysql://root@localhost/test"
begin
  # ... use db to perform queries
ensure
  db.close
end
```

Alternatively, you can use `DB.connect` method to open a single connection to the database instead of a pool.

## Exec

To execute sql statements you can use `Database#exec`

```crystal
db.exec "create table contacts (name varchar(30), age int)"
```

```crystal
db.exec "insert into contacts (name, age) values ('abc', 30)"
```

Values can be provided as query parameters, see below.

## Query

To perform a query and get the result set use `Database#query`.

`Database#query` returns a `ResultSet` that needs to be closed. As in `Database#open`, if called with a block, the `ResultSet` will be closed implicitly.

```crystal
db.query "select name, age from contacts order by age desc" do |rs|
  rs.each do
    # ... perform for each row in the ResultSet
  end
end
```

Values can be provided as query parameters, see below.

## Query Parameters

To avoid [SQL injection](https://owasp.org/www-community/attacks/SQL_Injection) values can be provided as query parameters.
The syntax for using query parameters depends on the database driver because they are typically just passed through to the database. MySQL uses `?` for parameter expansion and assignment is based on argument order. PostgreSQL uses `$n` where `n` is the ordinal number of the argument (starting with 1).

```crystal
# MySQL
db.exec "insert into contacts values (?, ?)", "John", 30
# Postgres
db.exec "insert into contacts values ($1, $2)", "Sarah", 33
# Queries:
db.query("select name from contacts where age = ?", 33) do |rs|
  rs.each do
    # ... perform for each row in the ResultSet
  end
end
```

Query parameters are effected under the covers with prepared statements (sometimes cached),
or insertion on the client side, depending on the driver, but will always avoid SQL Injection.

If you want to manually use prepared statements, you can with the `build` method:

```crystal
# MySQL
prepared_statement = db.build("select * from contacts where id=?") # Use "... where id=$1" for PostgreSQL
# Use prepared statement:
prepared_statement.query(3) do |rs|
  # ... use rs
end
prepared_statement.query(4) do |rs|
  # ... use rs
end
prepared_statement.close
```

## Reading Query Results

When reading values from the database there is no type information during compile time that Crystal can use. You will need to call `rs.read(T)` with the type `T` you expect to get from the database.

```crystal
db.query "select name, age from contacts order by age desc" do |rs|
  rs.each do
    name = rs.read(String)
    age = rs.read(Int32)
    puts "#{name} (#{age})"
    # => Sarah (33)
    # => John Doe (30)
  end
end
```

There are many convenient query methods built on top of `#query` to make this easier.

You can read multiple columns at once:

```crystal
name, age = rs.read(String, Int32)
```

Or read a single row:

```crystal
name, age = db.query_one "select name, age from contacts order by age desc limit 1", as: {String, Int32}
```

Or read a scalar value without dealing explicitly with the ResultSet:

```crystal
max_age = db.scalar "select max(age) from contacts"
```

There are many other helper methods to query with types, query column names with types, etc.
All available methods to perform statements in a database are defined in `DB::QueryMethods`.
# Connection

A connection is one of the key parts when working with databases. It represents the *runway* through which statements travel from our application to the database.

In Crystal we have two ways of building this connection. And so, coming up next, we are going to present examples with some advice on when to use each one.

## DB module

> *Give me a place to stand, and I shall move the earth.*
> Archimedes

The DB module, is our place to stand when working with databases in Crystal. As written in the documentation: *is a unified interface for database access*.

One of the methods implemented in this module is `DB#connect`. Using this method is the **first way** for creating a connection. Let's see how to use it.

## DB#connect

When using `DB#connect` we are indeed opening a connection to the database. The `uri` passed as the argument is used by the module to determine which driver to use (for example: `mysql://`, `postgres://`, `sqlite://`, etc.) i.e. we do not need to specify which database we are using.

The `uri` for this example is `mysql://root:root@localhost/test`, and so the module will use the `mysql driver` to connect to the MySQL database.

Here is the example:

```crystal
require "mysql"

cnn = DB.connect("mysql://root:root@localhost/test")
puts typeof(cnn) # => DB::Connection
cnn.close
```

It's worth mentioning that the method returns a `DB::Connection` object. Although more specifically, it returns a `MySql::Connection` object, it doesn't matter because all types of connections should be polymorphic. So hereinafter we will work with a `DB::Connection` instance, helping us to abstract from specific issues of each database engine.

When creating a connection *manually* (as we are doing here) we are responsible for managing this resource, and so we must close the connection when we are done using it. Regarding the latter, this little details can be the cause of huge bugs! Crystal, being *a language for humans*, give us a more safe way of *manually* creating a connection using blocks, like this:

```crystal
require "mysql"

DB.connect "mysql://root:root@localhost/test" do |cnn|
  puts typeof(cnn) # => DB::Connection
end                # the connection will be closed here
```

Ok, now we have a connection, let's use it!

```crystal
require "mysql"

DB.connect "mysql://root:root@localhost/test" do |cnn|
  puts typeof(cnn)                         # => DB::Connection
  puts "Connection closed: #{cnn.closed?}" # => false

  result = cnn.exec("drop table if exists contacts")
  puts result

  result = cnn.exec("create table contacts (name varchar(30), age int)")
  puts result

  cnn.transaction do |tx|
    cnn2 = tx.connection
    puts "Yep, it is the same connection! #{cnn == cnn2}"

    cnn2.exec("insert into contacts values ('Joe', 42)")
    cnn2.exec("insert into contacts values (?, ?)", "Sarah", 43)
  end

  cnn.query_each "select * from contacts" do |rs|
    puts "name: #{rs.read}, age: #{rs.read}"
  end
end
```

First, in this example, we are using a transaction (check the [transactions](transactions.md) section for more information on this topic)
Second, it's important to notice that the connection given by the transaction **is the same connection** that we were working with, before the transaction begin. That is, there is only **one** connection at all times in our program.
And last, we are using the method `#exec` and `#query`. You may read more about executing queries in the [database](README.md) section.

Now that we have a good idea about creating a connection, let's present the **second way** for creating one: `DB#open`

## DB#open

```crystal
require "mysql"

db = DB.open("mysql://root:root@localhost/test")
puts typeof(db) # DB::Database
db.close
```

As with a connection, we should close the database once we don't need it anymore.
Or instead, we could use a block and let Crystal close the database for us!

But, where is the connection?
Well, we should be asking for the **connections**. When a database is created, a pool of connections is created with connections to the database prepared and ready to use! (Do you want to read more about **pool of connections**? In the [connection pool](connection_pool.md) section you may read all about this interesting topic!)

How do we use a connection from the `database` object?
For this, we could ask the database for a connection using the method `Database#checkout`. But, doing this will require to explicitly return the connection to the pool using `Connection#release`. Here is an example:

```crystal
require "mysql"

DB.open "mysql://root:root@localhost/test" do |db|
  cnn = db.checkout
  puts typeof(cnn)

  puts "Connection closed: #{cnn.closed?}" # => false
  cnn.release
  puts "Connection closed: #{cnn.closed?}" # => false
end
```

And we want a *safe* way (i.e. no need for us to release the connection) to request and use a connection from the `database`, we could use `Database#using_connection`:

```crystal
require "mysql"

DB.open "mysql://root:root@localhost/test" do |db|
  db.using_connection do |cnn|
    puts typeof(cnn)
    # use cnn
  end
end
```

In the next example we will let the `database` object *to manage the connections by itself*, like this:

```crystal
require "mysql"

DB.open "mysql://root:root@localhost/test" do |db|
  db.exec("drop table if exists contacts")
  db.exec("create table contacts (name varchar(30), age int)")

  db.transaction do |tx|
    cnn = tx.connection
    cnn.exec("insert into contacts values ('Joe', 42)")
    cnn.exec("insert into contacts values (?, ?)", "Sarah", 43)
  end

  db.query_each "select * from contacts" do |rs|
    puts "name: #{rs.read}, age: #{rs.read}"
  end
end
```

As we may notice, the `database` is polymorphic with a `connection` object with regard to the `#exec` / `#query` / `#transaction` methods. The database is responsible for the use of the connections. Great!

## When to use one or the other?

Given the examples, it may come to our attention that **the number of connections is relevant**.
If we are programming a short living application with only one user starting requests to the  database then a single connection managed by us (i.e. a `DB::Connection` object) should be enough (think of a command line application that receives parameters, then starts a request to the database and finally displays the result to the user)
On the other hand, if we are building a system with many concurrent users and with heavy database access, then we should use a `DB::Database` object; which by using a connection pool will have a number of connections already prepared and ready to use (no bootstrap/initialization-time penalizations). Or imagine that you are building a long-living application (like a background job) then a connection pool will free you from the responsibility of monitoring the state of the connection: is it alive or does it need to reconnect?

## Connection Configuration

When using an `uri` to create a connection, we can specify not only the user, password, host, database, etc. but also some connection pool configuration and some custom options provided by each driver. Check each driver's documentation for more information.

To mention a few examples:

* [crystal-lang/crystal-sqlite3](https://github.com/crystal-lang/crystal-sqlite3) allows specifying `?journal_mode=WAL` to setup the [journal_mode](https://www.sqlite.org/pragma.html#pragma_journal_mode) to `WAL`.
* [crystal-lang/crystal-mysql](https://github.com/crystal-lang/crystal-mysql) allows specifying `?encoding=utf8mb4_unicode_ci` to setup the collation & charset to `utf8mb4_unicode_ci`.
* [will/crystal-pg](https://github.com/will/crystal-pg) allows specifying `?auth_methods=scram-sha-256` to allow only `scram-sha-256` authentication method.

### Advanced Connection Setup

In some cases the flexibility of the `uri` might not be enough. We can manually create a connection object or a database object if we want a connection pool. Each driver will provide a way to do this since each driver may have different options.

```crystal
# for a single connection
connection = TheDriver::Connection.new(crystal_db_connection_options, driver_connection_options)

# for a connection pool
db = DB::Database.new(crystal_db_connection_options, crystal_db_pool_options) do
  TheDriver::Connection.new(crystal_db_connection_options, driver_connection_options)
end
```

In [crystal-db#181](https://github.com/crystal-lang/crystal-db/pull/181) we can see an example of using crystal-pg to connect to a postgres database through a SSH tunnel by manually creating the underlying `IO` that the connection will use.
# Connection pool

When a connection is established it usually means opening a TCP connection or Socket. The socket will handle one statement at a time. If a program needs to perform many queries simultaneously, or if it handles concurrent requests that aim to use a database, it will need more than one active connection.

Since databases are separate services from the application using them, the connections might go down, the services might be restarted, and other sort of things the program might not want to care about.

To address this issues usually a connection pool is a neat solution.

When a database is opened with `crystal-db` there is already a connection pool working. `DB.open` returns a `DB::Database` object which manages the whole connection pool and not just a single connection.

```crystal
DB.open("mysql://root@localhost/test") do |db|
  # db is a DB::Database
end
```

When executing statements using `db.query`, `db.exec`, `db.scalar`, etc. the algorithm goes:

1. Find an available connection in the pool.
    1. Create one if needed and possible.
    2. If the pool is not allowed to create a new connection, wait a for a connection to become available.
        1. But this wait should be aborted if it takes too long.
2. Checkout that connection from the pool.
3. Execute the SQL command.
4. If there is no `DB::ResultSet` yielded, return the connection to the pool. Otherwise, the connection will be returned to the pool when the ResultSet is closed.
5. Return the statement result.

If a connection can't be created, or if a connection loss occurs while the statement is performed the above process is repeated.

> The retry logic only happens when the statement is sent through the `DB::Database` . If it is sent through a `DB::Connection` or `DB::Transaction` no retry is performed since the code will state that certain connection object was expected to be used.

## Configuration

The behavior of the pool can be configured from a set of parameters that can appear as query string in the connection URI.

| Name | Default value |
| :--- | :--- |
| initial\_pool\_size | 1 |
| max\_pool\_size | 0 \(unlimited\) |
| max\_idle\_pool\_size | 1 |
| checkout\_timeout | 5.0 \(seconds\) |
| retry\_attempts | 1 |
| retry\_delay | 1.0 \(seconds\) |

When `DB::Database` is opened an initial number of `initial_pool_size` connections will be created. The pool will never hold more than `max_pool_size` connections. When returning/releasing a connection to the pool it will be closed if there are already `max_idle_pool_size` idle connections.

If the `max_pool_size` was reached and a connection is needed, wait up to `checkout_timeout` seconds for an existing connection to become available.

If a connection is lost or can't be established retry at most `retry_attempts` times waiting `retry_delay` seconds between each try.

## Sample

The following program will print the current time from MySQL but if the connection is lost or the whole server is down for a few seconds the program will still run without raising exceptions.

```crystal title="sample.cr"
require "mysql"

DB.open "mysql://root@localhost?retry_attempts=8&retry_delay=3" do |db|
  loop do
    pp db.scalar("SELECT NOW()")
    sleep 0.5
  end
end
```

```console
$ crystal sample.cr
db.scalar("SELECT NOW()") # => 2016-12-16 16:36:57
db.scalar("SELECT NOW()") # => 2016-12-16 16:36:57
db.scalar("SELECT NOW()") # => 2016-12-16 16:36:58
db.scalar("SELECT NOW()") # => 2016-12-16 16:36:58
db.scalar("SELECT NOW()") # => 2016-12-16 16:36:59
db.scalar("SELECT NOW()") # => 2016-12-16 16:36:59
# stop mysql server for some seconds
db.scalar("SELECT NOW()") # => 2016-12-16 16:37:06
db.scalar("SELECT NOW()") # => 2016-12-16 16:37:06
db.scalar("SELECT NOW()") # => 2016-12-16 16:37:07
```
# Transactions

When working with databases, it is common to need to group operations in such a way that if one fails, then we can go back to the latest safe state.
This solution is described in the **transaction paradigm**, and is implemented by most database engines as it is necessary to meet ACID properties (Atomicity, Consistency, Isolation, Durability) [^ACID]

With this in mind, we present the following example:

We have two accounts (each represented by a name and an amount of money).

```crystal
db = get_bank_db

create_account db, "John", amount: 100
create_account db, "Sarah", amount: 100
```

In one moment a transfer is made from one account to the other. For example, *John transfers $50 to Sarah*

```crystal
deposit db, "Sarah", 50
withdraw db, "John", 50
```

It is important to have in mind that if one of the operations fails then the final state would be inconsistent. So we need to execute the **two operations** (deposit and withdraw) as **one operation**. And if an error occurs then we would like to go back in time as if that one operation was never executed.

```crystal
db = get_bank_db

create_account db, "John", amount: 100
create_account db, "Sarah", amount: 100

db.transaction do |tx|
  cnn = tx.connection

  transfer_amount = 1000
  deposit cnn, "Sarah", transfer_amount
  withdraw cnn, "John", transfer_amount
end
```

In the above example, we start a transaction simply by calling the method `Database#transaction` (how we get the `database` object is encapsulated in the method `get_bank_db` and is out of the scope of this document).
The `block` is the body of the transaction. When the `block` gets executed (without any error) then an **implicit commit** is finally executed to persist the changes in the database.
If an exception is raised by one of the operations, then an **implicit rollback** is executed, bringing the database to the state before the transaction started.

## Exception handling and rolling back

As we mentioned early, an **implicit rollback** gets executed when an exception is raised, and it’s worth mentioning that the exception may be rescued by us.

```crystal
db = get_bank_db

create_account db, "John", amount: 100
create_account db, "Sarah", amount: 100

begin
  db.transaction do |tx|
    cnn = tx.connection

    transfer_amount = 1000
    deposit(cnn, "Sarah", transfer_amount)
    # John does not have enough money in his account!
    withdraw(cnn, "John", transfer_amount)
  end
rescue ex
  puts "Transfer has been rolled back due to: #{ex}"
end
```

We may also raise an exception in the body of the transaction:

```crystal
db = get_bank_db

create_account db, "John", amount: 100
create_account db, "Sarah", amount: 100

begin
  db.transaction do |tx|
    cnn = tx.connection

    transfer_amount = 50
    deposit(cnn, "Sarah", transfer_amount)
    withdraw(cnn, "John", transfer_amount)
    raise Exception.new "Because ..."
  end
rescue ex
  puts "Transfer has been rolled back due to: #{ex}"
end
```

As the previous example, the exception cause the transaction to rollback and then is rescued by us.

There is one `exception` with a different behaviour. If a `DB::Rollback` is raised within the block, the implicit rollback will happen, but the exception will not be raised outside the block.

```crystal
db = get_bank_db

create_account db, "John", amount: 100
create_account db, "Sarah", amount: 100

begin
  db.transaction do |tx|
    cnn = tx.connection

    transfer_amount = 50
    deposit(cnn, "Sarah", transfer_amount)
    withdraw(cnn, "John", transfer_amount)

    # rollback exception
    raise DB::Rollback.new
  end
rescue ex
  # ex is never a DB::Rollback
end
```

## Explicit commit and rollback

In all the previous examples, the rolling back is **implicit**, but we can also tell the transaction to rollback:

```crystal
db = get_bank_db

create_account db, "John", amount: 100
create_account db, "Sarah", amount: 100

begin
  db.transaction do |tx|
    cnn = tx.connection

    transfer_amount = 50
    deposit(cnn, "Sarah", transfer_amount)
    withdraw(cnn, "John", transfer_amount)

    tx.rollback

    puts "Rolling Back the changes!"
  end
rescue ex
  # Notice that no exception is used in this case.
end
```

And we can also use the `commit` method:

```crystal
db = get_bank_db

db.transaction do |tx|
  cnn = tx.connection

  transfer_amount = 50
  deposit(cnn, "Sarah", transfer_amount)
  withdraw(cnn, "John", transfer_amount)

  tx.commit
end
```

NOTE: After `commit` or `rollback` are used, the transaction is no longer usable. The connection is still open but any statement will be performed outside the context of the terminated transaction.

## Nested transactions

As the name suggests, a nested transaction is a transaction created inside the scope of another transaction. Here is an example:

```crystal
db = get_bank_db

create_account db, "John", amount: 100
create_account db, "Sarah", amount: 100
create_account db, "Jack", amount: 0

begin
  db.transaction do |outer_tx|
    outer_cnn = outer_tx.connection

    transfer_amount = 50
    deposit(outer_cnn, "Sarah", transfer_amount)
    withdraw(outer_cnn, "John", transfer_amount)

    outer_tx.transaction do |inner_tx|
      inner_cnn = inner_tx.connection

      # John => 50 (pending commit)
      # Sarah => 150 (pending commit)
      # Jack => 0

      another_transfer_amount = 150
      deposit(inner_cnn, "Jack", another_transfer_amount)
      withdraw(inner_cnn, "Sarah", another_transfer_amount)
    end
  end
rescue ex
  puts "Exception raised due to: #{ex}"
end
```

Some observations from the above example:
the `inner_tx` works with the values updated although the `outer_tx` is pending the commit.
The connection used by `outer_tx` and `inner_tx` is **the same connection**. This is because the `inner_tx` inherits the connection from the `outer_tx` when created.

### Rollback nested transactions

As we’ve already seen, a rollback may be fired at any time (by an exception or by sending the message `rollback` explicitly)

So let’s present an example with a **rollback fired by an exception placed at the outer-transaction**:

```crystal
db = get_bank_db

create_account db, "John", amount: 100
create_account db, "Sarah", amount: 100
create_account db, "Jack", amount: 0

begin
  db.transaction do |outer_tx|
    outer_cnn = outer_tx.connection

    transfer_amount = 50
    deposit(outer_cnn, "Sarah", transfer_amount)
    withdraw(outer_cnn, "John", transfer_amount)

    outer_tx.transaction do |inner_tx|
      inner_cnn = inner_tx.connection

      # John => 50 (pending commit)
      # Sarah => 150 (pending commit)
      # Jack => 0

      another_transfer_amount = 150
      deposit(inner_cnn, "Jack", another_transfer_amount)
      withdraw(inner_cnn, "Sarah", another_transfer_amount)
    end

    raise Exception.new("Rollback all the things!")
  end
rescue ex
  puts "Exception raised due to: #{ex}"
end
```

The rollback place in the `outer_tx` block, rolled back all the changes including the ones in the `inner_tx` block (the same happens if we use an **explicit** rollback).

If the **rollback is fired by an exception at the inner_tx block** all the changes including the ones in the `outer_tx` are rollbacked.

```crystal
db = get_bank_db

create_account db, "John", amount: 100
create_account db, "Sarah", amount: 100
create_account db, "Jack", amount: 0

begin
  db.transaction do |outer_tx|
    outer_cnn = outer_tx.connection

    transfer_amount = 50
    deposit(outer_cnn, "Sarah", transfer_amount)
    withdraw(outer_cnn, "John", transfer_amount)

    outer_tx.transaction do |inner_tx|
      inner_cnn = inner_tx.connection

      # John => 50 (pending commit)
      # Sarah => 150 (pending commit)
      # Jack => 0

      another_transfer_amount = 150
      deposit(inner_cnn, "Jack", another_transfer_amount)
      withdraw(inner_cnn, "Sarah", another_transfer_amount)

      raise Exception.new("Rollback all the things!")
    end
  end
rescue ex
  puts "Exception raised due to: #{ex}"
end
```

There is a way to rollback the changes in the `inner-transaction` but keep the ones in the `outer-transaction`. Use `rollback` in the `inner_tx` object. This will rollback **only** the inner-transaction. Here is the example:

```crystal
db = get_bank_db

create_account db, "John", amount: 100
create_account db, "Sarah", amount: 100
create_account db, "Jack", amount: 0

begin
  db.transaction do |outer_tx|
    outer_cnn = outer_tx.connection

    transfer_amount = 50
    deposit(outer_cnn, "Sarah", transfer_amount)
    withdraw(outer_cnn, "John", transfer_amount)

    outer_tx.transaction do |inner_tx|
      inner_cnn = inner_tx.connection

      # John => 50 (pending commit)
      # Sarah => 150 (pending commit)
      # Jack => 0

      another_transfer_amount = 150
      deposit(inner_cnn, "Jack", another_transfer_amount)
      withdraw(inner_cnn, "Sarah", another_transfer_amount)

      inner_tx.rollback
    end
  end
rescue ex
  puts "Exception raised due to: #{ex}"
end
```

The same happens if a `DB::Rollback` exception is raised in the `inner-transaction` block.

```crystal
db = get_bank_db

create_account db, "John", amount: 100
create_account db, "Sarah", amount: 100
create_account db, "Jack", amount: 0

begin
  db.transaction do |outer_tx|
    outer_cnn = outer_tx.connection

    transfer_amount = 50
    deposit(outer_cnn, "Sarah", transfer_amount)
    withdraw(outer_cnn, "John", transfer_amount)

    outer_tx.transaction do |inner_tx|
      inner_cnn = inner_tx.connection

      # John => 50 (pending commit)
      # Sarah => 150 (pending commit)
      # Jack => 0

      another_transfer_amount = 150
      deposit(inner_cnn, "Jack", another_transfer_amount)
      withdraw(inner_cnn, "Sarah", another_transfer_amount)

      # Rollback exception
      raise DB::Rollback.new
    end
  end
rescue ex
  puts "Exception raised due to: #{ex}"
end
```

[^ACID]: Theo Haerder and Andreas Reuter. 1983. Principles of transaction-oriented database recovery. ACM Comput. Surv. 15, 4 (December 1983), 287-317. DOI=http://dx.doi.org/10.1145/289.291
# Getting started

Hi and welcome to Crystal's Reference Book!

First, let's make sure to [install the compiler](https://crystal-lang.org/install/) so that we may try all the examples listed in this book.

Once installed, the Crystal compiler should be available as `crystal` command.

Let's try it!

## Crystal version

We may check the Crystal compiler version. If Crystal is installed correctly then we should see something like this:

```console
$ crystal --version
--8<-- "crystal-version.txt"
```

Great!

## Crystal help

Now, if we want to list all the options given by the compiler, we may run `crystal` program without any arguments:

```console
$ crystal
Usage: crystal [command] [switches] [program file] [--] [arguments]

Command:
    init                     generate a new project
    build                    build an executable
    docs                     generate documentation
    env                      print Crystal environment information
    eval                     eval code from args or standard input
    play                     starts Crystal playground server
    run (default)            build and run program
    spec                     build and run specs (in spec directory)
    tool                     run a tool
    help, --help, -h         show this help
    version, --version, -v   show version

Run a command followed by --help to see command-specific information, ex:
    crystal <command> --help
```

More details about using the compiler can be found on the manpage `man crystal` or in our [compiler manual](../man/crystal/README.md).

## Hello Crystal

The following example is the classic Hello World. In Crystal it looks like this:

```crystal title="hello_world.cr"
puts "Hello World!"
```

We may run our example like this:

```console
$ crystal hello_world.cr
Hello World!
```

NOTE: The main routine is simply the program itself. There's no need to define a "main" function or something similar.

Next you might want to start with the [Introduction Tour](../tutorials/basics/README.md) to get acquainted with the language.

Here we have two more examples to continue our first steps in Crystal:

* [HTTP Server](./http_server.md)
* [Command Line Application](./cli.md)
# Command Line Interface Application

Programming Command Line Interface applications (CLI applications) is one of the most entertaining tasks a developer may do. So let’s have some fun building our first CLI application in Crystal.

There are two main topics when building a CLI application:

* [input](#input)
* [output](#output)

## Input

This topic covers all things related to:

* [options passed to the app](#options)
* [request for user input](#request-for-user-input)

### Options

It is a very common practice to pass options to the application. For example, we may run `crystal -v` and Crystal will display:

```console
$ crystal -v
--8<-- "crystal-version.txt"
```

and if we run: `crystal -h`, then Crystal will show all the accepted options and how to use them.

So now the question would be: **do we need to implement an options parser?** No need to, Crystal has us covered with the class `OptionParser`. Let’s build an application using this parser!

At the start our CLI application has two options:

* `-v` / `--version`: it will display the application version.
* `-h` / `--help`: it will display the application help.

```crystal title="help.cr"
require "option_parser"

OptionParser.parse do |parser|
  parser.banner = "Welcome to The Beatles App!"

  parser.on "-v", "--version", "Show version" do
    puts "version 1.0"
    exit
  end
  parser.on "-h", "--help", "Show help" do
    puts parser
    exit
  end
end
```

So, how does all this work? Well … magic! No, it’s not really magic! Just Crystal making our life easy.
When our application starts, the block passed to `OptionParser#parse` gets executed. In that block we define all the options. After the block is executed, the parser will start consuming the arguments passed to the application, trying to match each one with the options defined by us. If an option matches then the block passed to `parser#on` gets executed!

We can read all about `OptionParser` in [the official API documentation](https://crystal-lang.org/api/OptionParser.html). And from there we are one click away from the source code ... the actual proof that it is not magic!

Now, let's run our application. We have two ways [using the compiler](../man/crystal/README.md):

1. [Build the application](../man/crystal/README.md#crystal-build) and then run it.
2. Compile and [run the application](../man/crystal/README.md#crystal-run), all in one command.

We are going to use the second way:

```console
$ crystal run ./help.cr -- -h

Welcome to The Beatles App!
    -v, --version                    Show version
    -h, --help                       Show help
```

Let's build another *fabulous* application with the following feature:

By default (i.e. no options given) the application will display the names of the Fab Four. But, if we pass the option `-t` / `--twist` it will display the names in uppercase:

```crystal title="twist_and_shout.cr"
require "option_parser"

the_beatles = [
  "John Lennon",
  "Paul McCartney",
  "George Harrison",
  "Ringo Starr",
]
shout = false

option_parser = OptionParser.parse do |parser|
  parser.banner = "Welcome to The Beatles App!"

  parser.on "-v", "--version", "Show version" do
    puts "version 1.0"
    exit
  end
  parser.on "-h", "--help", "Show help" do
    puts parser
    exit
  end
  parser.on "-t", "--twist", "Twist and SHOUT" do
    shout = true
  end
end

members = the_beatles
members = the_beatles.map &.upcase if shout

puts ""
puts "Group members:"
puts "=============="
members.each do |member|
  puts member
end
```

Running the application with the `-t` option will output:

```console
$ crystal run ./twist_and_shout.cr -- -t

Group members:
==============
JOHN LENNON
PAUL MCCARTNEY
GEORGE HARRISON
RINGO STARR
```

#### Parameterized options

Let’s create another application: *when passing the option `-g` / `--goodbye_hello`, the application will say hello to a given name **passed as a parameter to the option***.

```crystal title="hello_goodbye.cr"
require "option_parser"

the_beatles = [
  "John Lennon",
  "Paul McCartney",
  "George Harrison",
  "Ringo Starr",
]
say_hi_to = ""

option_parser = OptionParser.parse do |parser|
  parser.banner = "Welcome to The Beatles App!"

  parser.on "-v", "--version", "Show version" do
    puts "version 1.0"
    exit
  end
  parser.on "-h", "--help", "Show help" do
    puts parser
    exit
  end
  parser.on "-g NAME", "--goodbye_hello=NAME", "Say hello to whoever you want" do |name|
    say_hi_to = name
  end
end

unless say_hi_to.empty?
  puts ""
  puts "You say goodbye, and #{the_beatles.sample} says hello to #{say_hi_to}!"
end
```

In this case, the block receives a parameter that represents the parameter passed to the option.

Let’s try it!

```console
$ crystal run ./hello_goodbye.cr -- -g "Penny Lane"

You say goodbye, and Ringo Starr says hello to Penny Lane!
```

Great! These applications look awesome! But, **what happens when we pass an option that is not declared?** For example -n

```console
$ crystal run ./hello_goodbye.cr -- -n
Unhandled exception: Invalid option: -n (OptionParser::InvalidOption)
  from ...
```

Oh no! It’s broken: we need to handle **invalid options** and **invalid parameters** given to an option! For these two situations, the `OptionParser` class has two methods: `#invalid_option` and `#missing_option`

So, let's add this option handler and merge all these CLI applications into one fabulous CLI application!

#### All My CLI: The complete application

Here’s the final result, with invalid/missing options handling, plus other new options:

```crystal title="all_my_cli.cr"
require "option_parser"

the_beatles = [
  "John Lennon",
  "Paul McCartney",
  "George Harrison",
  "Ringo Starr",
]
shout = false
say_hi_to = ""
strawberry = false

option_parser = OptionParser.parse do |parser|
  parser.banner = "Welcome to The Beatles App!"

  parser.on "-v", "--version", "Show version" do
    puts "version 1.0"
    exit
  end
  parser.on "-h", "--help", "Show help" do
    puts parser
    exit
  end
  parser.on "-t", "--twist", "Twist and SHOUT" do
    shout = true
  end
  parser.on "-g NAME", "--goodbye_hello=NAME", "Say hello to whoever you want" do |name|
    say_hi_to = name
  end
  parser.on "-r", "--random_goodbye_hello", "Say hello to one random member" do
    say_hi_to = the_beatles.sample
  end
  parser.on "-s", "--strawberry", "Strawberry fields forever mode ON" do
    strawberry = true
  end
  parser.missing_option do |option_flag|
    STDERR.puts "ERROR: #{option_flag} is missing something."
    STDERR.puts ""
    STDERR.puts parser
    exit(1)
  end
  parser.invalid_option do |option_flag|
    STDERR.puts "ERROR: #{option_flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end
end

members = the_beatles
members = the_beatles.map &.upcase if shout

puts "Strawberry fields forever mode ON" if strawberry

puts ""
puts "Group members:"
puts "=============="
members.each do |member|
  puts "#{strawberry ? "🍓" : "-"} #{member}"
end

unless say_hi_to.empty?
  puts ""
  puts "You say goodbye, and I say hello to #{say_hi_to}!"
end
```

### Request for user input

Sometimes, we may need the user to input a value. How do we *read* that value?
Easy, peasy! Let’s create a new application: the Fab Four will sing with us any phrase we want. When running the application, it will request a phrase to the user and the magic will happen!

```crystal title="let_it_cli.cr"
puts "Welcome to The Beatles Sing-Along version 1.0!"
puts "Enter a phrase you want The Beatles to sing"
print "> "
user_input = gets
puts "The Beatles are singing: 🎵#{user_input}🎶🎸🥁"
```

The method [`gets`](https://crystal-lang.org/api/toplevel.html#gets%28*args,**options%29-class-method) will **pause** the execution of the application until the user finishes entering the input (pressing the `Enter` key).
When the user presses `Enter`, then the execution will continue and `user_input` will have the user value.

But what happens if the user doesn’t enter any value? In that case, we would get an empty string (if the user only presses `Enter`) or maybe a `Nil` value (if the input stream is closed, e.g. by pressing `Ctrl+D`).
To illustrate the problem let’s try the following: we want the input entered by the user to be sung loudly:

```crystal title="let_it_cli.cr"
puts "Welcome to The Beatles Sing-Along version 1.0!"
puts "Enter a phrase you want The Beatles to sing"
print "> "
user_input = gets
puts "The Beatles are singing: 🎵#{user_input.upcase}🎶🎸🥁"
```

When running the example, Crystal will reply:

```console
$ crystal run ./let_it_cli.cr
Showing last frame. Use --error-trace for full trace.

In let_it_cli.cr:5:46

 5 | puts "The Beatles are singing: 🎵#{user_input.upper_case}
                                                  ^---------
Error: undefined method 'upper_case' for Nil (compile-time type is (String | Nil))
```

Ah! We should have known better: the type of the user input is the [union type](../syntax_and_semantics/type_grammar.md) `String | Nil`.
So, we have to test for `Nil` and for `empty` and act naturally for each case:

```crystal title="let_it_cli.cr"
puts "Welcome to The Beatles Sing-Along version 1.0!"
puts "Enter a phrase you want The Beatles to sing"
print "> "
user_input = gets

exit if user_input.nil? # Ctrl+D

default_lyrics = "Na, na, na, na-na-na na" \
                 " / " \
                 "Na-na-na na, hey Jude"

lyrics = user_input.presence || default_lyrics

puts "The Beatles are singing: 🎵#{lyrics.upcase}🎶🎸🥁"
```

## Output

Now, we will focus on the second main topic: our application’s output.
For starters, our applications already display information but (I think) we could do better. Let’s add more *life* (i.e. colors!) to the outputs.

And to accomplish this, we will be using the [`Colorize`](https://crystal-lang.org/api/Colorize.html) module.

Let’s build a really simple application that shows a string with colors! We will use a yellow font on a black background:

```crystal title="yellow_cli.cr"
require "colorize"

puts "#{"The Beatles".colorize(:yellow).on(:black)} App"
```

Great! That was easy! Now imagine using this string as the banner for our All My CLI application, it's easy if you try:

```crystal
parser.banner = "#{"The Beatles".colorize(:yellow).on(:black)} App"
```

For our second application, we will add a *text decoration* (`blink`in this case):

```crystal title="let_it_cli.cr"
require "colorize"

puts "Welcome to The Beatles Sing-Along version 1.0!"
puts "Enter a phrase you want The Beatles to sing"
print "> "
user_input = gets

exit if user_input.nil? # Ctrl+D

default_lyrics = "Na, na, na, na-na-na na" \
                 " / " \
                 "Na-na-na na, hey Jude"

lyrics = user_input.presence || default_lyrics

puts "The Beatles are singing: #{"🎵#{lyrics}🎶🎸🥁".colorize.mode(:blink)}"
```

Let’s try the renewed application … and *hear* the difference!!
**Now** we have two fabulous apps!!

You may find a list of **available colors** and **text decorations** in the [API documentation](https://crystal-lang.org/api/Colorize.html).

## Testing

As with any other application, at some point, we would like to [write tests](../guides/testing.md) for the different features.

Right now the code containing the logic of each of the applications always gets executed with the `OptionParser`, i.e. there is no way to include that file without running the whole application. So first we would need to refactor the code, separating the code necessary for parsing options from the logic. Once the refactoring is done, we could start testing the logic and including the file with the logic in the testing files we need. We leave this as an exercise for the reader.

## Using `Readline` and `NCurses`

In case we want to build richer CLI applications, there are libraries that can help us. Here we will name two well-known libraries: `Readline` and `NCurses`.

As stated in the documentation for the [GNU Readline Library](http://www.gnu.org/software/readline/), `Readline` is a library that provides a set of functions for use by applications that allow users to edit command lines as they are typed in.
`Readline` has some great features: filename autocompletion out of the box; custom auto-completion method; keybinding, just to mention a few. If we want to try it then the [crystal-lang/crystal-readline](https://github.com/crystal-lang/crystal-readline) shard will give us an easy API to use `Readline`.

On the other hand, we have `NCurses`(New Curses). This library allows developers to create *graphical* user interfaces in the terminal. As its name implies, it is an improved version of the library named `Curses`, which was developed to support a text-based dungeon-crawling adventure game called Rogue!
As you can imagine, there are already [a couple of shards](https://shardbox.org/search?q=ncurses) in the ecosystem that will allow us to use `NCurses` in Crystal!

And so we have reached The End 😎🎶
# HTTP Server

A slightly more interesting example is an HTTP Server:

```crystal
require "http/server"

server = HTTP::Server.new do |context|
  context.response.content_type = "text/plain"
  context.response.print "Hello world! The time is #{Time.local}"
end

address = server.bind_tcp 8080
puts "Listening on http://#{address}"
server.listen
```

The above code will make sense once you read the whole language reference, but we can already learn some things.

* You can [require](../syntax_and_semantics/requiring_files.md) code defined in other files:

    ```crystal
    require "http/server"
    ```

* You can define [local variables](../syntax_and_semantics/local_variables.md) without the need to specify their type:

    ```crystal
    server = HTTP::Server.new(...)
    ```

* The port of the HTTP server is set by using the method bind_tcp on the object HTTP::Server (the port set to 8080).

    ```crystal
    address = server.bind_tcp 8080
    ```

* You program by invoking [methods](../syntax_and_semantics/classes_and_methods.md) (or sending messages) to objects.

    ```crystal
    HTTP::Server.new(...)
    # ...
    Time.local
    # ...
    address = server.bind_tcp 8080
    # ...
    puts "Listening on http://#{address}"
    # ...
    server.listen
    ```

* You can use code blocks, or simply [blocks](../syntax_and_semantics/blocks_and_procs.md), which are a very convenient way to reuse code and get some features from the functional world:

    ```crystal
    HTTP::Server.new do |context|
      # ...
    end
    ```

* You can easily create strings with embedded content, known as string interpolation. The language comes with other [syntax](../syntax_and_semantics/literals/README.md) as well to create arrays, hashes, ranges, tuples and more:

    ```crystal
    "Hello world! The time is #{Time.local}"
    ```
# Guides

Read these guides to get the best out of Crystal.
# Build Docker Image

When your Crystal application is developed, you can build a Docker image for using it portably. To do this, you can use the Crystal's Docker Image that are available on the [Docker hub](https://hub.docker.com/r/crystallang/crystal/tags?name=1).

For example, let's suppose we create a simple program that displays "Hello World":

```cr title="program.cr"
puts "Hello World"
```

To proceed to the compilation of your program, we can use the Dockerfile and that's what we will look at in this guide.

```dockerfile
FROM crystallang/crystal:1

WORKDIR /app
COPY ./program.cr /app

RUN crystal build program.cr -o program --release --static \
    --progress --stats --no-debug

CMD ["bin/program"]
```

!!!info
    You can also use `shards build` to compile the program.

Once the Dockerfile is configured, we can now build a Docker image by running the command:

```cr
docker build -t program:latest .
```

Finally, the Docker image is built with the matched name.

```sh
$ docker image ls program
REPOSITORY   TAG       IMAGE ID       CREATED         SIZE
program      latest    fd8159825ab7   5 seconds ago   471MB
```

The disadvantage is that the size of this Docker image is large, which leads to things that are not really useful for running a program, such as the Crystal compiler and the `shards` binary. It is possible to optimize the image size by using a multi-step build.

## Multi-stage builds

The Multi-stage builds consist to compile the program in the first image and copying it to another image adapted for production mode.

```dockerfile
# Build stage
FROM crystallang/crystal:1 AS build

COPY . /app
WORKDIR /app

RUN crystal build program.cr -o program --release --static \
--progress --stats --no-debug

# Prod stage
FROM ubuntu AS prod

WORKDIR /usr/local

COPY --from=build /app/program /usr/local/bin/program

CMD ["bin/program"]
```

The advantage is that Docker image will be less heavy, containing only the programs and libraries necessary for it to be operational.

Result: you will get the Docker image with a reasonable size.

```sh
$ docker image ls program
REPOSITORY   TAG       IMAGE ID       CREATED         SIZE
program      latest    42a3633f95c9   4 seconds ago   79.7MB
```

!!! note
    The image size depends on the size of the executable and the libraries.
# Continuous Integration

The ability of having immediate feedback on what we are working should be one of the most important characteristics in software development. Imagine making one change to our source code and having to wait 2 weeks to see if it broke something? oh! That would be a nightmare! For this, Continuous Integration will help a team to have immediate and frequent feedback about the status of what they are building.

Martin Fowler [defines Continuous Integration](https://www.martinfowler.com/articles/continuousIntegration.html) as
*a software development practice where members of a team integrate their work frequently, usually each person integrates at least daily - leading to multiple integrations per day. Each integration is verified by an automated build (including test) to detect integration errors as quickly as possible. Many teams find that this approach leads to significantly reduced integration problems and allows a team to develop cohesive software more rapidly.*

In the next subsections, we are going to present two continuous integration tools: [GitHub Actions](https://docs.github.com/actions) and [Circle CI](https://circleci.com/), and use them with a Crystal example application.

These tools not only will let us build and test our code each time the source has changed but also deploy the result (if the build was successful) or use automatic builds, and maybe test against different platforms, to mention a few.

## The example application

We are going to use Conway's Game of Life as the example application. More precisely, we are going to use only the first iterations in [Conway's Game of Life Kata](http://codingdojo.org/kata/GameOfLife/) solution using [TDD](https://martinfowler.com/bliki/TestDrivenDevelopment.html).

Note that we won't be using TDD in the example itself, but we will mimic as if the example code is the result of the first iterations.

Another important thing to mention is that we are using `crystal init` to [create the application](../../man/crystal/README.md#creating-a-crystal-project).

And here's the implementation:

```crystal title="src/game_of_life.cr"
class Location
  getter x : Int32
  getter y : Int32

  def self.random
    Location.new(Random.rand(10), Random.rand(10))
  end

  def initialize(@x, @y)
  end
end

class World
  @living_cells : Array(Location)

  def self.empty
    new
  end

  def initialize(living_cells = [] of Location)
    @living_cells = living_cells
  end

  def set_living_at(a_location)
    @living_cells << a_location
  end

  def is_empty?
    @living_cells.size == 0
  end
end
```

And the specs:

```crystal title="spec/game_of_life_spec.cr"
require "./spec_helper"

describe "a new world" do
  it "should be empty" do
    world = World.new
    world.is_empty?.should be_true
  end
end

describe "an empty world" do
  it "should not be empty after adding a cell" do
    world = World.empty
    world.set_living_at(Location.random)
    world.is_empty?.should be_false
  end
end
```

And this is all we need for our continuous integration examples! Let's start!

## Continuous Integration step by step

Here's the list of items we want to achieve:

1. Build and run specs using 3 different Crystal's versions:
    * latest
    * nightly
    * 0.31.1 (using a Docker image)
2. Install shards packages
3. Install binary dependencies
4. Use a database (for example MySQL)
5. Cache dependencies to make the build run faster

From here choose your next steps:

* I want to use [GitHub Actions](gh-actions.md)
* I want to use [CircleCI](circleci.md)
# CircleCI

In this section we are going to use [CircleCI](https://circleci.com/) as our continuous-integration service. In a [few words](https://circleci.com/docs/2.0/about-circleci/#section=welcome) CircleCI automates your software builds, tests, and deployments. It supports [different programming languages](https://circleci.com/docs/2.0/demo-apps/#section=welcome) and for our particular case, it supports the [Crystal language](https://circleci.com/docs/2.0/language-crystal/).

In this section we are going to present some configuration examples to see how CircleCI implements some [continuous integration concepts](https://circleci.com/docs/2.0/concepts/).

## CircleCI orbs

Before showing some examples, it’s worth mentioning [CircleCI orbs](https://circleci.com/orbs/). As defined in the official docs:
> Orbs define reusable commands, executors, and jobs so that commonly used pieces of configuration can be condensed into a single line of code.

In our case, we are going to use [Crystal’s Orb](https://circleci.com/orbs/registry/orb/manastech/crystal)

## Build and run specs

### Simple example using `latest`

Let’s start with a simple example. We are going to run the tests **using latest** Crystal release:

```yaml title=".circleci/config.yml"
workflows:
  version: 2
  build:
    jobs:
      - crystal/test

orbs:
  crystal: manastech/crystal@1.0
version: 2.1
```

Yeah! That was simple! With Orbs an abstraction layer is built so that the configuration file is more readable and intuitive.

In case we are wondering what the job [crystal/test](https://circleci.com/orbs/registry/orb/manastech/crystal#jobs-test) does, we always may see the source code.

### Using `nightly`

Using nightly Crystal release is as easy as:

```yaml title=".circleci/config.yml"
workflows:
  version: 2
  build:
    jobs:
      - crystal/test:
          name: test-on-nightly
          executor:
            name: crystal/default
            tag: nightly

orbs:
  crystal: manastech/crystal@1.0
version: 2.1
```

### Using a specific Crystal release

```yaml title=".circleci/config.yml"
workflows:
  version: 2
  build:
    jobs:
      - crystal/test:
          name: test-on-0.30
          executor:
            name: crystal/default
            tag: 0.30.0

orbs:
  crystal: manastech/crystal@1.0
version: 2.1
```

## Installing shards packages

You need not worry about it since the `crystal/test` job runs the `crystal/shard-install` orb command.

## Installing binary dependencies

Our application or maybe some shards may require libraries and packages. This binary dependencies may be installed using the [Apt](https://help.ubuntu.com/lts/serverguide/apt.html) command.

Here is an example installing the `libsqlite3` development package:

```yaml title=".circleci/config.yml"
workflows:
  version: 2
  build:
    jobs:
      - crystal/test:
          pre-steps:
            - run: apt-get update && apt-get install -y libsqlite3-dev

orbs:
  crystal: manastech/crystal@1.0
version: 2.1
```

## Using services

Now, let’s run specs using an external service (for example MySQL):

```yaml title=".circleci/config.yml"
executors:
  crystal_mysql:
    docker:
      - image: 'crystallang/crystal:latest'
        environment:
          DATABASE_URL: 'mysql://root@localhost/db'
      - image: 'mysql:5.7'
        environment:
          MYSQL_DATABASE: db
          MYSQL_ALLOW_EMPTY_PASSWORD: 'yes'

workflows:
  version: 2
  build:
    jobs:
      - crystal/test:
          executor: crystal_mysql
          pre-steps:
            - run:
                name: Waiting for service to start (check dockerize)
                command: sleep 1m
            - checkout
            - run:
                name: Install MySQL CLI; Import dummy data
                command: |
                        apt-get update && apt-get install -y mysql-client
                        mysql -h 127.0.0.1 -u root --password="" db < test-data/setup.sql

orbs:
  crystal: manastech/crystal@1.0
version: 2.1
```

NOTE: The explicit `checkout` in the `pre-steps` is to have the `test-data/setup.sql` file available.

## Caching

Caching is enabled by default when using the job `crystal/test`, because internally it uses the `command` [with-shards-cache](https://circleci.com/orbs/registry/orb/manastech/crystal#commands-with-shards-cache)
# GitHub Actions

## Build and run specs

To continuously test [our example application](README.md#the-example-application) -- both whenever a commit is pushed and when someone opens a [pull request](https://docs.github.com/en/github/collaborating-with-issues-and-pull-requests/about-pull-requests), add this minimal [workflow file](https://docs.github.com/en/actions/learn-github-actions/introduction-to-github-actions#create-an-example-workflow):

```yaml title=".github/workflows/ci.yml"
on:
  push:
  pull_request:
    branches: [master]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Download source
        uses: actions/checkout@v2
      - name: Install Crystal
        uses: crystal-lang/install-crystal@v1
      - name: Run tests
        run: crystal spec
```

To get started with [GitHub Actions](https://docs.github.com/en/actions/guides/about-continuous-integration#about-continuous-integration-using-github-actions), commit this YAML file into your Git repository under the directory `.github/workflows/`, push it to GitHub, and observe the Actions tab.

TIP: **Quickstart.**
Check out [**Configurator for *install-crystal* action**](https://crystal-lang.github.io/install-crystal/configurator.html) to quickly get a config with the CI features you need. Or continue reading for more details.

This runs on GitHub's [default](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners#supported-runners-and-hardware-resources) "latest Ubuntu" container. It downloads the source code from the repository itself (directly into the current directory), installs Crystal via [Crystal's official GitHub Action](https://github.com/crystal-lang/install-crystal), then runs the specs, assuming they are there in the `spec/` directory.

If any step fails, the build will show up as failed, notify the author and, if it's a push, set the overall build status of the project to failing.

TIP:
For a healthier codebase, consider these flags for `crystal spec`:
`--order=random` `--error-on-warnings`

### No specs?

If your test coverage isn't great, consider at least adding an example program, and building it as part of CI:

For a library:

```yaml
          - name: Build example
            run: crystal build examples/hello.cr
```

For an application (very good to do even if you have specs):

```yaml
          - name: Build
            run: crystal build src/game_of_life.cr
```

### Testing with different versions of Crystal

By default, the latest released version of Crystal is installed. But you may want to also test with the "nightly" build of Crystal, and perhaps some older versions that you still support for your project. Change the top of the workflow as follows:

```yaml hl_lines="6 14"
jobs:
  build:
    strategy:
      fail-fast: false
      matrix:
        crystal: [0.35.1, latest, nightly]
    runs-on: ubuntu-latest
    steps:
      - name: Download source
        uses: actions/checkout@v2
      - name: Install Crystal
        uses: crystal-lang/install-crystal@v1
        with:
          crystal: ${{ matrix.crystal }}
      - ...
```

All those versions will be tested for *in parallel*.

By specifying the version of Crystal you could even opt *out* of supporting the latest version (which *is* a moving target), and only support particular ones.

### Testing on multiple operating systems

Typically, developers run tests only on Ubuntu, which is OK if there is no platform-sensitive code. But it's easy to add another [system](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners#supported-runners-and-hardware-resources) into the test matrix, just add the following near the top of your job definition:

```yaml hl_lines="6 7"
jobs:
  build:
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - ...
```

## Installing Shards packages

Most projects will have external dependencies, ["shards"](https://github.com/crystal-lang/shards#usage). Having declared them in `shard.yml`, just add the installation step into your workflow (after `install-crystal` and before any testing):

```yaml
      - name: Install shards
        run: shards install
```

### Latest or locked dependencies?

If your repository has a checked in `shard.lock` file (typically good for applications), consider the effect that this has on CI: `shards install` will always install the exact versions specified in that file. But if you're developing a library, you probably want to be the first to find out in case a new version of a dependency breaks the installation of your library -- otherwise the users will, because the lock doesn't apply transitively. So, strongly consider running `shards update` instead of `shards install`, or don't check in `shard.lock`. And then it makes sense to add [scheduled runs](https://www.jeffgeerling.com/blog/2020/running-github-actions-workflow-on-schedule-and-other-events) to your repository.

## Installing binary dependencies

Our application or some shards may require external libraries. The approach to installing them can vary widely. The typical way is to install packages using the `apt` command in Ubuntu.

Add the installation step somewhere near the beginning. For example, with `libsqlite3`:

```yaml
      - name: Install packages
        run: sudo apt-get -qy install libsqlite3-dev
```

## Enforcing code formatting

If you want to verify that all your code has been formatted with [`crystal tool format`](../writing_shards.md#coding-style), add the according check as a step near the end of the workflow. If someone pushes code that is not formatted correctly, this will break the build just like failing tests would.

```yaml
      - name: Check formatting
        run: crystal tool format --check
```

Consider also adding this check as a *Git pre-commit hook* for yourself.

## Using the official Docker image

We have been using an "action" to install Crystal into the default OS image that GitHub provides. Which [has multiple advantages](https://forum.crystal-lang.org/t/github-action-to-install-crystal-and-shards-unified-ci-across-linux-macos-and-windows/2837). But you may instead choose to use Crystal's official Docker image(s), though that's applicable only to Linux.

The base config becomes this instead:

```yaml title=".github/workflows/ci.yml" hl_lines="4-5 9"
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: crystallang/crystal:latest
    steps:
      - name: Download source
        uses: actions/checkout@v2

      - name: Run tests
        run: crystal spec
```

Some [other options](https://hub.docker.com/r/crystallang/crystal/tags) for containers are `crystallang/crystal:nightly`, `crystallang/crystal:0.36.1`, `crystallang/crystal:latest-alpine`.

## Caching

The process of downloading and installing dependencies (shards specifically) is done from scratch on every run. With caching in GitHub Actions, we can save some of that duplicated work.

The safe approach is to add the [actions/cache](https://github.com/actions/cache) step (**before the step that uses `shards`**) defined as follows:

```yaml
      - name: Cache shards
        uses: actions/cache@v2
        with:
          path: ~/.cache/shards
          key: ${{ runner.os }}-shards-${{ hashFiles('shard.yml') }}
          restore-keys: ${{ runner.os }}-shards-
      - name: Install shards
        run: shards update
```

DANGER: **Important.**
You **must** use the separate [`key` and `restore-keys`](https://docs.github.com/en/actions/guides/caching-dependencies-to-speed-up-workflows#matching-a-cache-key). With just a static key, the cache would save only the state after the very first run and then keep reusing it forever, regardless of any changes.

But this saves us only the time spent *downloading* the repositories initially.

A "braver" approach is to cache the `lib` directory itself, but that works only if you fully rely on `shard.lock` (see [Latest or locked dependencies?](#latest-or-locked-dependencies)):

```yaml
      - name: Cache shards
        uses: actions/cache@v2
        with:
          path: lib
          key: ${{ runner.os }}-shards-${{ hashFiles('**/shard.lock') }}
      - name: Install shards
        run: shards check || shards install
```

Note that we also made the installation conditional on `shards check`. That saves even a little more time.

## Publishing executables

If your project is an application, you likely want to distribute it as an executable ("binary") file. For the case of Linux x86_64, by far the most popular option is to build and [link statically](../static_linking.md) [on Alpine Linux](../static_linking.md#linux). This means that you *cannot* use GitHub's default Ubuntu container and the install action. Instead, just use the official container:

```yaml title=".github/workflows/release.yml" hl_lines="5 8"
jobs:
  release_linux:
    runs-on: ubuntu-latest
    container:
      image: crystallang/crystal:latest-alpine
    steps:
      - uses: actions/checkout@v2
      - run: shards build --production --release --static --no-debug
```

These steps would be followed by some action to publish the produced executable (`bin/*`), in one of the two ways (or both of them):

* As part of a release: [see complete example](https://github.com/Blacksmoke16/oq/blob/56bd3d306ede15e86481d7b5db4af7f89b85a37f/.github/workflows/deployment.yml).
    Then in your README you can link to the latest release using a URL such as https://github.com/:username/:reponame/releases/latest

* As part of the CI done for every commit, via [actions/upload-artifact](https://github.com/actions/upload-artifact).
    Then consider linking to the latest "nightly" build using the external service https://nightly.link/

Distributing executables for macOS ([search for examples](https://github.com/search?q=%22macos-latest%22+%22shards+build%22+%22--release%22+dylib+path%3A.github%2Fworkflows&type=Code)) and Windows ([search for examples](https://github.com/search?l=YAML&q=%22windows-latest%22+%22shards+build%22+%22--release%22+path%3A.github%2Fworkflows&type=Code)) is also possible.
# Concurrency

## Concurrency vs. Parallelism

The definitions of "concurrency" and "parallelism" sometimes get mixed up, but they are not the same.

A concurrent system is one that can be in charge of many tasks, although not necessarily executing them at the same time. You can think of yourself being in the kitchen cooking: you chop an onion, put it to fry, and while it's being fried you chop a tomato, but you are not doing all of those things at the same time: you distribute your time between those tasks. Parallelism would be to stir fry onions with one hand while with the other one you chop a tomato.

At the moment of this writing, Crystal has concurrency support but not parallelism: several tasks can be executed, and a bit of time will be spent on each of these, but two code paths are never executed at the same exact time.

A Crystal program by default executes in a single operating system thread, except for the garbage collector (currently [Boehm GC](http://www.hboehm.info/gc/)). Parallelism is supported, but it is currently considered experimental. Check out [this Crystal Blog post about parallelism](https://crystal-lang.org/2019/09/06/parallelism-in-crystal.html) for more information.

### Fibers

To achieve concurrency, Crystal has fibers. A fiber is in a way similar to an operating system thread except that it's much more lightweight and its execution is managed internally by the process. So, a program will spawn multiple fibers and Crystal will make sure to execute them when the time is right.

### Event loop

For everything I/O related there's an event loop. Some time-consuming operations are delegated to it, and while the event loop waits for that operation to finish the program can continue executing other fibers. A simple example of this is waiting for data to come through a socket.

### Channels

Crystal has Channels inspired by [CSP](https://en.wikipedia.org/wiki/Communicating_sequential_processes). They allow communicating data between fibers without sharing memory and without having to worry about locks, semaphores or other special structures.

## Execution of a program

When a program starts, it fires up a main fiber that will execute your top-level code. There, one can spawn many other fibers. The components of a program are:

* The Runtime Scheduler, in charge of executing all fibers when the time is right.
* The Event Loop, which is just another fiber, being in charge of async tasks, like for example files, sockets, pipes, signals and timers (like doing a `sleep`).
* Channels, to communicate data between fibers. The Runtime Scheduler will coordinate fibers and channels for their communication.
* Garbage Collector: to clean up "no longer used" memory.

### A Fiber

A fiber is an execution unit that is more lightweight than a thread. It's a small object that has an associated [stack](https://en.wikipedia.org/wiki/Call_stack) of 8MB, which is what is usually assigned to an operating system thread.

Fibers, unlike threads, are cooperative. Threads are pre-emptive: the operating system might interrupt a thread at any time and start executing another one. A fiber must explicitly tell the Runtime Scheduler to switch to another fiber. For example if there's I/O to be waited on, a fiber will tell the scheduler "Look, I have to wait for this I/O to be available, you continue executing other fibers and come back to me when that I/O is ready".

The advantage of being cooperative is that a lot of the overhead of doing a context switch (switching between threads) is gone.

A Fiber is much more lightweight than a thread: even though it's assigned 8MB, it starts with a small stack of 4KB.

On a 64-bit machine it lets us spawn millions and millions of fibers. In a 32-bit machine we can only spawn 512 fibers, which is not a lot. But because 32-bit machines are starting to become obsolete, we'll bet on the future and focus more on 64-bit machines.

### The Runtime Scheduler

The scheduler has a queue of:

* Fibers ready to be executed: for example when you spawn a fiber, it's ready to be executed.
* The event loop: which is another fiber. When there are no other fibers ready to be executed, the event loop checks if there is any async operation that is ready, and then executes the fiber waiting for that operation. The event loop is currently implemented with `libevent`, which is an abstraction of other event mechanisms like `epoll` and `kqueue`.
* Fibers that voluntarily asked to wait: this is done with `Fiber.yield`, which means "I can continue executing, but I'll give you some time to execute other fibers if you want".

### Communicating data

Because at this moment there's only a single thread executing your code, accessing and modifying a class variable in different fibers will work just fine. However, once multiple threads (parallelism) is introduced in the language, it might break. That's why the recommended mechanism to communicate data is using channels and sending messages between them. Internally, a channel implements all the locking mechanisms to avoid data races, but from the outside you use them as communication primitives, so you (the user) don't have to use locks.

## Sample code

### Spawning a fiber

To spawn a fiber you use `spawn` with a block:

```crystal
spawn do
  # ...
  socket.gets
  # ...
end

spawn do
  # ...
  sleep 5.seconds
  #  ...
end
```

Here we have two fibers: one reads from a socket and the other does a `sleep`. When the first fiber reaches the `socket.gets` line, it gets suspended, the Event Loop is told to continue executing this fiber when there's data in the socket, and the program continues with the second fiber. This fiber wants to sleep for 5 seconds, so the Event Loop is told to continue with this fiber in 5 seconds. If there aren't other fibers to execute, the Event Loop will wait until either of these events happen, without consuming CPU time.

The reason why `socket.gets` and `sleep` behave like this is because their implementations talk directly with the Runtime Scheduler and the Event Loop, there's nothing magical about it. In general, the standard library already takes care of doing all of this so you don't have to.

Note, however, that fibers don't get executed right away. For example:

```crystal
spawn do
  loop do
    puts "Hello!"
  end
end
```

Running the above code will produce no output and exit immediately.

The reason for this is that a fiber is not executed as soon as it is spawned. So, the main fiber, the one that spawns the above fiber, finishes its execution and the program exits.

One way to solve it is to do a `sleep`:

```crystal
spawn do
  loop do
    puts "Hello!"
  end
end

sleep 1.second
```

This program will now print "Hello!" for one second and then exit. This is because the `sleep` call will schedule the main fiber to be executed in a second, and then executes another "ready to execute" fiber, which in this case is the one above.

Another way is this:

```crystal
spawn do
  loop do
    puts "Hello!"
  end
end

Fiber.yield
```

This time `Fiber.yield` will tell the scheduler to execute the other fiber. This will print "Hello!" until the standard output blocks (the system call will tell us we have to wait until the output is ready), and then execution continues with the main fiber and the program exits. Here the standard output *might* never block so the program will continue executing forever.

If we want to execute the spawned fiber for ever, we can use `sleep` without arguments:

```crystal
spawn do
  loop do
    puts "Hello!"
  end
end

sleep
```

Of course the above program can be written without `spawn` at all, just with a loop. `sleep` is more useful when spawning more than one fiber.

### Spawning a call

You can also spawn by passing a method call instead of a block. To understand why this is useful, let's look at this example:

```crystal
i = 0
while i < 10
  spawn do
    puts(i)
  end
  i += 1
end

Fiber.yield
```

The above program prints "10" ten times. The problem is that there's only one variable `i` that all spawned fibers refer to, and when `Fiber.yield` is executed its value is 10.

To solve this, we can do this:

```crystal
i = 0
while i < 10
  proc = ->(x : Int32) do
    spawn do
      puts(x)
    end
  end
  proc.call(i)
  i += 1
end

Fiber.yield
```

Now it works because we are creating a [Proc](https://crystal-lang.org/api/Proc.html) and we invoke it passing `i`, so the value gets copied and now the spawned fiber receives a copy.

To avoid all this boilerplate, the standard library provides a `spawn` macro that accepts a call expression and basically rewrites it to do the above. Using it, we end up with:

```crystal
i = 0
while i < 10
  spawn puts(i)
  i += 1
end

Fiber.yield
```

This is mostly useful with local variables that change at iterations. This doesn't happen with block arguments. For example, this works as expected:

```crystal
10.times do |i|
  spawn do
    puts i
  end
end

Fiber.yield
```

### Spawning a fiber and waiting for it to complete

We can use a channel for this:

```crystal
channel = Channel(Nil).new

spawn do
  puts "Before send"
  channel.send(nil)
  puts "After send"
end

puts "Before receive"
channel.receive
puts "After receive"
```

This prints:

```
Before receive
Before send
After send
After receive
```

First, the program spawns a fiber but doesn't execute it yet. When we invoke `channel.receive`, the main fiber blocks and execution continues with the spawned fiber. Then `channel.send(nil)` is invoked. Note that this `send` does not occupy space in the channel because there is a `receive` invoked prior to the first `send`, `send` is not blocked. Fibers only switch out when blocked or executing to completion. So the spawned fiber will continue after `send`, and execution will switch back to main fiber once `puts "After send"` is executed.

The main fiber then resumes at `channel.receive`, which was waiting for a value. Then the main fiber continues executing and finishes.

In the above example we used `nil` just to communicate that the fiber ended. We can also use channels to communicate values between fibers:

```crystal
channel = Channel(Int32).new

spawn do
  puts "Before first send"
  channel.send(1)
  puts "Before second send"
  channel.send(2)
end

puts "Before first receive"
value = channel.receive
puts value # => 1

puts "Before second receive"
value = channel.receive
puts value # => 2
```

Output:

```
Before first receive
Before first send
Before second send
1
Before second receive
2

```

Note that when the program executes a `receive`, the current fiber blocks and execution continues with the other fiber. When `channel.send(1)` is executed, execution continues because `send` is non-blocking if the channel is not yet full. However, `channel.send(2)` does cause the fiber to block because the channel (which has a size of 1 by default) is full, so execution continues with the fiber that was waiting on that channel.

Here we are sending literal values, but the spawned fiber might compute this value by, for example, reading a file, or getting it from a socket. When this fiber will have to wait for I/O, other fibers will be able to continue executing code until I/O is ready, and finally when the value is ready and sent through the channel, the main fiber will receive it. For example:

```crystal
require "socket"

channel = Channel(String).new

spawn do
  server = TCPServer.new("0.0.0.0", 8080)
  socket = server.accept
  while line = socket.gets
    channel.send(line)
  end
end

spawn do
  while line = gets
    channel.send(line)
  end
end

3.times do
  puts channel.receive
end
```

The above program spawns two fibers. The first one creates a TCPServer, accepts one connection and reads lines from it, sending them to the channel. There's a second fiber reading lines from standard input. The main fiber reads the first 3 messages sent to the channel, either from the socket or stdin, then the program exits. The `gets` calls will block the fibers and tell the Event Loop to continue from there if data comes.

Likewise, we can wait for multiple fibers to complete execution, and gather their values:

```crystal
channel = Channel(Int32).new

10.times do |i|
  spawn do
    channel.send(i * 2)
  end
end

sum = 0
10.times do
  sum += channel.receive
end
puts sum # => 90
```

You can, of course, use `receive` inside a spawned fiber:

```crystal
channel = Channel(Int32).new

spawn do
  puts "Before send"
  channel.send(1)
  puts "After send"
end

spawn do
  puts "Before receive"
  puts channel.receive
  puts "After receive"
end

puts "Before yield"
Fiber.yield
puts "After yield"
```

Output:

```
Before yield
Before send
Before receive
1
After receive
After send
After yield
```

Here `channel.send` is executed first, but since there's no one waiting for a value (yet), execution continues in other fibers. The second fiber is executed, there's a value on the channel, it's obtained, and execution continues, first with the first fiber, then with the main fiber, because `Fiber.yield` puts a fiber at the end of the execution queue.

### Buffered channels

The above examples use unbuffered channels: when sending a value, if a fiber is waiting on that channel then execution continues on that fiber.

With a buffered channel, invoking `send` won't switch to another fiber unless the buffer is full:

```crystal
# A buffered channel of capacity 2
channel = Channel(Int32).new(2)

spawn do
  puts "Before send 1"
  channel.send(1)
  puts "Before send 2"
  channel.send(2)
  puts "Before send 3"
  channel.send(3)
  puts "After send"
end

3.times do |i|
  puts channel.receive
end
```

Output:

```
Before send 1
Before send 2
Before send 3
After send
1
2
3
```

Note that the first `send` does not occupy space in the channel. This is because there is a `receive` invoked prior to the first `send` whereas the other 2 `send` invocations take place before their respective `receive`. The number of `send` calls do not exceed the bounds of the buffer and so the send fiber runs uninterrupted to completion.

Here's an example where all space in the buffer gets occupied:

```crystal
# A buffered channel of capacity 1
channel = Channel(Int32).new(1)

spawn do
  puts "Before send 1"
  channel.send(1)
  puts "Before send 2"
  channel.send(2)
  puts "Before send 3"
  channel.send(3)
  puts "End of send fiber"
end

3.times do |i|
  puts channel.receive
end
```

Output:

```
Before send 1
Before send 2
Before send 3
1
2
3
```

Note that "End of send fiber" does not appear in the output because we `receive` the 3 `send` calls which means `3.times` runs to completion and in turn unblocks the main fiber which executes to completion.

Here's the same snippet as the one we just saw - with the addition of a `Fiber.yield` call at the very bottom:

```crystal
# A buffered channel of capacity 1
channel = Channel(Int32).new(1)

spawn do
  puts "Before send 1"
  channel.send(1)
  puts "Before send 2"
  channel.send(2)
  puts "Before send 3"
  channel.send(3)
  puts "End of send fiber"
end

3.times do |i|
  puts channel.receive
end

Fiber.yield
```

Output:

```
Before send 1
Before send 2
Before send 3
1
2
3
End of send fiber
```

With the addition of a `Fiber.yield` call at the end of the snippet we see the "End of send fiber" message in the output which would have otherwise been missed due to the main fiber executing to completion.
# Hosting on GitHub

* Create a repository with the same `name` and `description` as specified in your `shard.yml`.

* Add and commit everything:

    ```console
    $ git add -A && git commit -am "shard complete"
    ```

* Add the remote: (Be sure to replace `<YOUR-GITHUB-USERNAME>` and `<YOUR-REPOSITORY-NAME>` accordingly)

    NOTE: If you like, feel free to replace `public` with `origin`, or a remote name of your choosing.

    ```console
    $ git remote add public https://github.com/<YOUR-GITHUB-NAME>/<YOUR-REPOSITORY-NAME>.git
    ```

* Push it:

    ```console
    $ git push public master
    ```

## GitHub Releases

It's good practice to do GitHub Releases.

Add the following markdown build badge below the description in your README to inform users what the most current release is:
(Be sure to replace `<YOUR-GITHUB-USERNAME>` and `<YOUR-REPOSITORY-NAME>` accordingly)

```markdown
[![GitHub release](https://img.shields.io/github/release/<YOUR-GITHUB-USERNAME>/<YOUR-REPOSITORY-NAME>.svg)](https://github.com/<YOUR-GITHUB-USERNAME>/<YOUR-REPOSITORY-NAME>/releases)
```

Start by navigating to your repository's *releases* page.
This can be found at `https://github.com/<YOUR-GITHUB-NAME>/<YOUR-REPOSITORY-NAME>/releases`

Click "Create a new release".

According to [the Crystal Shards README](https://github.com/crystal-lang/shards/blob/master/README.md),
> When libraries are installed from Git repositories, the repository is expected to have version tags following a semver-like format, prefixed with a `v`. Examples: v1.2.3, v2.0.0-rc1 or v2017.04.1

Accordingly, in the input that says `tag version`, type `v0.1.0`. Make sure this matches the `version` in `shard.yml`. Title it `v0.1.0` and write a short description for the release.

Click "Publish release" and you're done!

You'll now notice that the GitHub Release badge has updated in your README.

Follow [Semantic Versioning](http://semver.org/) and create a new release every time your push new code to `master`.

## Continuous integration

GitHub Actions allows you to automatically test your project on every commit. Configure it according to the [dedicated guide](../ci/gh-actions.md).

You can also [add a build status badge](https://docs.github.com/en/actions/managing-workflow-runs/adding-a-workflow-status-badge) below the description in your README.md.

### Hosting your docs on GitHub Pages

As an extension of the GitHub Actions config, you can add the steps to build the API doc site and then upload them, correspondingly:

```yaml
    steps:

      - name: Build docs
        run: crystal docs
      - name: Deploy docs
        if: github.event_name == 'push' && github.ref == 'refs/heads/master'
        uses: ...
        with:
          ...
```

-- where the latter `...` placeholder is any of the generic GitHub Actions to push a directory to the *gh-pages* branch. Some options are:

* [JamesIves/github-pages-deploy-action](https://github.com/JamesIves/github-pages-deploy-action) [[Search](https://github.com/search?q=JamesIves+crystal+path%3A.github%2Fworkflows&type=Code)]
* [crazy-max/ghaction-github-pages](https://github.com/crazy-max/ghaction-github-pages) [[Search](https://github.com/search?q=%22ghaction-github-pages%22+crystal+path%3A.github%2Fworkflows&type=Code)]
* [peaceiris/actions-gh-pages](https://github.com/peaceiris/actions-gh-pages) [[Search](https://github.com/search?q=peaceiris%2Factions-gh-pages+crystal+path%3A.github%2Fworkflows&type=Code)]
* [oprypin/push-to-gh-pages](https://github.com/oprypin/push-to-gh-pages) [[Search](https://github.com/search?q=%22oprypin%2Fpush-to-gh-pages%22+crystal+path%3A.github%2Fworkflows&type=Code)]

This uses Crystal's built-in API doc generator to make a generic site based on your code and comments to the items in it.

Rather than just publishing the generated API docs, consider also making a full textual manual of your project, for a well-rounded introduction.

For one of the options for static site generation, [mkdocs-material](https://squidfunk.github.io/mkdocs-material), there's a solution to tightly integrate API documentation into an overall documentation site: [mkdocstrings-crystal](https://github.com/mkdocstrings/crystal). Consider it as an alternative to `crystal docs`.
# Hosting on GitLab

* Add and commit everything:

    ```console
    $ git add -A && git commit -am "shard complete"
    ```

* Create a GitLab project with the same `name` and `description` as specified in your `shard.yml`.

* Add the remote: (Be sure to replace `<YOUR-GITLAB-USERNAME>` and `<YOUR-REPOSITORY-NAME>` accordingly)

    ```console
    $ git remote add origin https://gitlab.com/<YOUR-GITLAB-USERNAME>/<YOUR-REPOSITORY-NAME>.git
    ```

    or if you use SSH

    ```console
    $ git remote add origin git@gitlab.com:<YOUR-GITLAB-USERNAME>/<YOUR-REPOSITORY-NAME>.git
    ```

* Push it:

    ```console
    $ git push origin master
    ```

## Pipelines

Next, let's setup a [GitLab Pipeline](https://docs.gitlab.com/ee/ci/pipelines.html) that can run our tests and build/deploy the docs when we push code to the repo.

Simply, you can just add the following file to the root of the repo and name it `.gitlab-ci.yml`

```yaml
image: "crystallang/crystal:latest"

before_script:
  - shards install

cache:
  paths:
  - lib/

spec & format:
  script:
  - crystal spec
  - crystal tool format --check

pages:
  stage: deploy
  script:
  - crystal docs -o public src/palindrome-example.cr
  artifacts:
    paths:
    - public
  only:
  - master
```

This creates two jobs. The first one is titled "spec & format" (you can use any name you like) and by default goes in the "test" stage of the pipeline. It just runs the array of commands in `script` on a brand new instance of the docker container specified by `image`. You'll probably want to lock that container to the version of crystal you're using (the one specified in your shard.yml) but for this example we'll just use the `latest` tag.

The test stage of the pipeline will either pass (each element of the array returned a healthy exit code) or it will fail (one of the elements returned an error).

If it passes, then the pipeline will move onto the second job we defined here which [we must name](https://docs.gitlab.com/ee/ci/yaml/#pages) "pages". This is a special job just for deploying content to your gitlab pages site! This one is executed after tests have passed because we specified that it should occur in the "deploy" stage. It again runs the commands in `script` (this time building the docs), but this time we tell it to preserve the path `public` (where we stashed the docs) as an artifact of the job.

The result of naming this job `pages` and putting our docs in the `public` directory and specifying it as an `artifact` is that GitLab will deploy the site in that directory to the default URL `https://<YOUR-GITLAB-USERNAME>.gitlab.io/<YOUR-REPOSITORY-NAME>`.

The `before_script` and `cache` keys in the file are for running the same script in every job (`shards install`) and for hanging onto the files that were created (`cache`). They're not necessary if your shard doesn't have any dependencies.

If you commit the above file to your project and push, you'll trigger your first run of the new pipeline.

```console
$ git add -A && git commit -am 'Add .gitlab-ci.yml' && git push origin master
```

### Some Badges

While that pipeline is running, let's attach some badges to the project to show off our docs and the (hopefully) successful state of our pipeline. (You might want to read the [badges docs](https://gitlab.com/help/user/project/badges).)

A badge is just a link with an image. So let's create a link to our pipeline and fetch a badge image from the [Gitlab Pipeline Badges API](https://docs.gitlab.com/ee/user/project/pipelines/settings.html#pipeline-badges).

In the *Badges* section of the *General* settings, we'll first add a release badge. The link is: `https://gitlab.com/<YOUR-GITLAB-USERNAME>/<YOUR-REPOSITORY-NAME>/pipelines` and the *Badge Image URL* is: `https://gitlab.com/<YOUR-GITLAB-USERNAME>/<YOUR-REPOSITORY-NAME>/badges/master/pipeline.svg`.

And now if the pipeline has finished we'll have docs and we can link to them with a generic badge from `shields.io`.

* Link: `https://<YOUR-GITLAB-USERNAME>.gitlab.io/<YOUR-REPOSITORY-NAME>`
* Image: `https://img.shields.io/badge/docs-available-brightgreen.svg`

## Releases

A release is just a special commit in your history with a name (see [tagging](https://git-scm.com/book/en/v2/Git-Basics-Tagging)).

According to [the Crystal Shards README](https://github.com/crystal-lang/shards/blob/master/README.md),

> When libraries are installed from Git repositories, the repository is expected to have version tags following a semver-like format, prefixed with a `v`. Examples: v1.2.3, v2.0.0-rc1 or v2017.04.1

GitLab also has a [releases feature](https://docs.gitlab.com/ee/workflow/releases.html) that let's you associate files and a description with this tag. That way you can (for example) distribute binaries.

As you'll see from the [releases docs](https://docs.gitlab.com/ee/workflow/releases.html), you can either create an *annotated* tag along with release notes/files in the UI:

![gitlab new tags UI](./gitlab_tags_new.png)

or you can create the tag from the command line like so:

```console
$ git tag -a v0.1.0 -m "Release v0.1.0"
```

push it up

```console
$ git push origin master --follow-tags
```

and then use the UI to add/edit the release note and attach files.

**Best Practices:**

* Use the `-a` option to create an annotated tag for releases.
* Follow [Semantic Versioning](http://semver.org/).

### Release Badge

If you'd like you can also add a `shields.io` badge for the release. GitLab doesn't have full support for this kind of thing, and until someone adds a [version badge for gitlab](https://github.com/badges/shields/blob/master/doc/TUTORIAL.md) to shields.io, we'll have to just code in the version number in the URLs directly.

* Link: `https://img.shields.io/badge/release-<VERSION>-brightgreen.svg`
* Image: `https://img.shields.io/badge/release-<VERSION>-brightgreen.svg`

where `<VERSION>` is the version number prefixed with a `v` like this: `v0.1.0`.

### Mirror to GitHub

Projects on GitHub have typically more exposure and better integration with other services, so if you want your library to be hosted there as well, you can set up a "push mirror" from GitLab to GitHub.

1. Create a GitHub repository with the same name as your project.
2. Follow the instructions here: https://docs.gitlab.com/ee/workflow/repository_mirroring.html#setting-up-a-push-mirror-from-gitlab-to-github-core
3. Edit your GitHub description. You could use the following
    * Description: Words that are the same forwards and backwards. This is a mirror of:
    * Link: `https://gitlab.com/<YOUR-GITLAB-USERNAME>/<YOUR-REPOSITORY-NAME>/`

This is a push mirror and that means changes will only propagate one way. So be sure to let potential collaborators know that pull requests and issues should be submitted to your GitLab project.
# Performance

Follow these tips to get the best out of your programs, both in speed and memory terms.

## Premature optimization

Donald Knuth once said:

> We should forget about small efficiencies, say about 97% of the time: premature optimization is the root of all evil. Yet we should not pass up our opportunities in that critical 3%.

However, if you are writing a program and you realize that writing a semantically equivalent, faster version involves just minor changes, you shouldn't miss that opportunity.

And always be sure to profile your program to learn what its bottlenecks are. For profiling, on macOS you can use [Instruments Time Profiler](https://developer.apple.com/library/prerelease/content/documentation/DeveloperTools/Conceptual/InstrumentsUserGuide/Instrument-TimeProfiler.html), which comes with XCode, or one of the [sampling profilers](https://stackoverflow.com/questions/11445619/profiling-c-on-mac-os-x). On Linux, any program that can profile C/C++ programs, like [perf](https://perf.wiki.kernel.org/index.php/Main_Page) or [Callgrind](http://valgrind.org/docs/manual/cl-manual.html), should work.  For both Linux and OS X, you can detect most hotspots by running your program within a debugger then hitting "ctrl+c" to interrupt it occasionally and issuing a gdb `backtrace` command to look for patterns in backtraces (or use the [gdb poor man's profiler](https://poormansprofiler.org/) which does the same thing for you, or OS X `sample` command.

Make sure to always profile programs by compiling or running them with the `--release` flag, which turns on optimizations.

## Avoiding memory allocations

One of the best optimizations you can do in a program is avoiding extra/useless memory allocation. A memory allocation happens when you create an instance of a **class**, which ends up allocating heap memory. Creating an instance of a **struct** uses stack memory and doesn't incur a performance penalty. If you don't know the difference between stack and heap memory, be sure to [read this](https://stackoverflow.com/questions/79923/what-and-where-are-the-stack-and-heap).

Allocating heap memory is slow, and it puts more pressure on the Garbage Collector (GC) as it will later have to free that memory.

There are several ways to avoid heap memory allocations. The standard library is designed in a way to help you do that.

### Don't create intermediate strings when writing to an IO

To print a number to the standard output you write:

```crystal
puts 123
```

In many programming languages what will happen is that `to_s`, or a similar method for converting the object to its string representation, will be invoked, and then that string will be written to the standard output. This works, but it has a flaw: it creates an intermediate string, in heap memory, only to write it and then discard it. This, involves a heap memory allocation and gives a bit of work to the GC.

In Crystal, `puts` will invoke `to_s(io)` on the object, passing it the IO to which the string representation should be written.

So, you should never do this:

```crystal
puts 123.to_s
```

as it will create an intermediate string. Always append an object directly to an IO.

When writing custom types, always be sure to override `to_s(io)`, not `to_s`, and avoid creating intermediate strings in that method. For example:

```crystal
class MyClass
  # Good
  def to_s(io)
    # appends "1, 2" to IO without creating intermediate strings
    x = 1
    y = 2
    io << x << ", " << y
  end

  # Bad
  def to_s(io)
    x = 1
    y = 2
    # using a string interpolation creates an intermediate string.
    # this should be avoided
    io << "#{x}, #{y}"
  end
end
```

This philosophy of appending to an IO instead of returning an intermediate string results in better performance than handling intermediate strings. You should use this strategy in your API definitions too.

Let's compare the times:

```crystal title="io_benchmark.cr"
require "benchmark"

io = IO::Memory.new

Benchmark.ips do |x|
  x.report("without to_s") do
    io << 123
    io.clear
  end

  x.report("with to_s") do
    io << 123.to_s
    io.clear
  end
end
```

Output:

```console
$ crystal run --release io_benchmark.cr
without to_s  77.11M ( 12.97ns) (± 1.05%)       fastest
   with to_s  18.15M ( 55.09ns) (± 7.99%)  4.25× slower
```

Always remember that it's not just the time that has improved: memory usage is also decreased.

### Use string interpolation instead of concatenation

Sometimes you need to work directly with strings built from combining string literals with other values. You shouldn't just concatenate these strings with `String#+(String)` but rather use [string interpolation](../syntax_and_semantics/literals/string.md#interpolation) which allows to embed expressions into a string literal: `"Hello, #{name}"` is better than `"Hello, " +  name.to_s`.

Interpolated strings are transformed by the compiler to append to a string IO so that it automatically avoids intermediate strings. The example above translates to:

```crystal
String.build do |io|
  io << "Hello, " << name
end
```

### Avoid IO allocation for string building

Prefer to use the dedicated `String.build` optimized for building strings, instead of creating an intermediate `IO::Memory` allocation.

```crystal
require "benchmark"

Benchmark.ips do |bm|
  bm.report("String.build") do
    String.build do |io|
      99.times do
        io << "hello world"
      end
    end
  end

  bm.report("IO::Memory") do
    io = IO::Memory.new
    99.times do
      io << "hello world"
    end
    io.to_s
  end
end
```

Output:

```console
$ crystal run --release str_benchmark.cr
String.build 597.57k (  1.67µs) (± 5.52%)       fastest
  IO::Memory 423.82k (  2.36µs) (± 3.76%)  1.41× slower
```

### Avoid creating temporary objects over and over

Consider this program:

```crystal
lines_with_language_reference = 0
while line = gets
  if ["crystal", "ruby", "java"].any? { |string| line.includes?(string) }
    lines_with_language_reference += 1
  end
end
puts "Lines that mention crystal, ruby or java: #{lines_with_language_reference}"
```

The above program works but has a big performance problem: on every iteration a new array is created for `["crystal", "ruby", "java"]`. Remember: an array literal is just syntax sugar for creating an instance of an array and adding some values to it, and this will happen over and over on each iteration.

There are two ways to solve this:

1. Use a tuple. If you use `{"crystal", "ruby", "java"}` in the above program it will work the same way, but since a tuple doesn't involve heap memory it will be faster, consume less memory, and give more chances for the compiler to optimize the program.

    ```crystal
    lines_with_language_reference = 0
    while line = gets
      if {"crystal", "ruby", "java"}.any? { |string| line.includes?(string) }
        lines_with_language_reference += 1
      end
    end
    puts "Lines that mention crystal, ruby or java: #{lines_with_language_reference}"
    ```

2. Move the array to a constant.

    ```crystal
    LANGS = ["crystal", "ruby", "java"]

    lines_with_language_reference = 0
    while line = gets
      if LANGS.any? { |string| line.includes?(string) }
        lines_with_language_reference += 1
      end
    end
    puts "Lines that mention crystal, ruby or java: #{lines_with_language_reference}"
    ```

Using tuples is the preferred way.

Explicit array literals in loops is one way to create temporary objects, but these can also be created via method calls. For example `Hash#keys` will return a new array with the keys each time it's invoked. Instead of doing that, you can use `Hash#each_key`, `Hash#has_key?` and other methods.

### Use structs when possible

If you declare your type as a **struct** instead of a **class**, creating an instance of it will use stack memory, which is much cheaper than heap memory and doesn't put pressure on the GC.

You shouldn't always use a struct, though. Structs are passed by value, so if you pass one to a method and the method makes changes to it, the caller won't see those changes, so they can be bug-prone. The best thing to do is to only use structs with immutable objects, especially if they are small.

For example:

```crystal title="class_vs_struct.cr"
require "benchmark"

class PointClass
  getter x
  getter y

  def initialize(@x : Int32, @y : Int32)
  end
end

struct PointStruct
  getter x
  getter y

  def initialize(@x : Int32, @y : Int32)
  end
end

Benchmark.ips do |x|
  x.report("class") { PointClass.new(1, 2) }
  x.report("struct") { PointStruct.new(1, 2) }
end
```

Output:

```console
$ crystal run --release class_vs_struct.cr
 class  28.17M (± 2.86%) 15.29× slower
struct 430.82M (± 6.58%)       fastest
```

## Iterating strings

Strings in Crystal always contain UTF-8 encoded bytes. UTF-8 is a variable-length encoding: a character may be represented by several bytes, although characters in the ASCII range are always represented by a single byte. Because of this, indexing a string with `String#[]` is not an `O(1)` operation, as the bytes need to be decoded each time to find the character at the given position. There's an optimization that Crystal's `String` does here: if it knows all the characters in the string are ASCII, then `String#[]` can be implemented in `O(1)`. However, this isn't generally true.

For this reason, iterating a String in this way is not optimal, and in fact has a complexity of `O(n^2)`:

```crystal
string = "foo"
while i < string.size
  char = string[i]
  # ...
end
```

There's a second problem with the above: computing the `size` of a String is also slow, because it's not simply the number of bytes in the string (the `bytesize`). However, once a String's size has been computed, it is cached.

The way to improve performance in this case is to either use one of the iteration methods (`each_char`, `each_byte`, `each_codepoint`), or use the more low-level `Char::Reader` struct. For example, using `each_char`:

```crystal
string = "foo"
string.each_char do |char|
  # ...
end
```
# Runtime Tracing

The Crystal runtime has a tracing feature for low level functionality. It prints diagnostic info about runtime internals.

A program must be built with the flag `-Dtracing` to support tracing.
At runtime, the individual tracing components can be enabled via the environment variable `CRYSTAL_TRACE`. It receives a comma separated list of sections to enable.

* `CRYSTAL_TRACE=none` Disable tracing (default)
* `CRYSTAL_TRACE=gc`: Enable tracing for the garbage collector
* `CRYSTAL_TRACE=sched`: Enable tracing for the scheduler
* `CRYSTAL_TRACE=gc,sched`: Enable tracing for the garbage collector and scheduler
* `CRYSTAL_TRACE=all` Enable all tracing (equivalent to `gc,sched`)

Example:

```console
$ crystal build -Dtracing hello-world.cr
$ CRYSTAL_TRACE=sched ./hello-world
sched.spawn 70569399740240 thread=0x7f48d7dc9740:? fiber=0x7f48d7cd0f00:main fiber=0x7f48d7cd0dc0:Signal Loop
sched.enqueue 70569399831716 thread=0x7f48d7dc9740:? fiber=0x7f48d7cd0f00:main fiber=0x7f48d7cd0dc0:Signal Loop duration=163
Hello World
```

The traces are printed to the standard error by default.
This can be changed at runtime with the `CRYSTAL_TRACE_FILE` environment variable.

For example, `CRYSTAL_TRACE_FILE=trace.log` prints all tracing output to a file `trace.log`.

## Tracing Format

Each trace entry stands on a single line, terminated by linefeed, and is at most 512 bytes long.

Each entry starts with an identifier consisting of section and operation names, separated by a dot (e.g. `gc.malloc`).
Then comes a timestamp represented as an integer in nanoseconds.
Finally, a list of metadata properties in the form `key=value` separated by single spaces.

The first two properties are always the originating `thread` and `fiber`. Both are identified by id and name, separated by a colon (e.g `0x7f48d7cd0f00:main`).

* The thread id is the OS handle, so we can match a thread to a debugger session for example.
* The fiber id is an internal address in the Crystal runtime. Names are optional and not necessarily unique.

Trace items from early in the runtime startup may be missing fiber metadata and thread names.

More metadata properties can follow depending on the specific trace entry.

For example, `gc.malloc` indicates how much memory is being allocated.

Reported values are typically represented as integers with the following semantics:

* Times and durations are in nanoseconds as per the monotonic clock of the operating system (e.g. `123` is `123ns`, `5000000000` is `5s`).
* Memory sizes are in bytes (e.g. `1024` is `1KB`).
# Static Linking

Crystal supports static linking, i.e. it can link a binary with static libraries so that these libraries don't need to be available as runtime dependencies. This improves portability at the cost of larger binaries.

Static linking can be enabled using the `--static` compiler flag. See [the usage instructions](../man/crystal/README.md#creating-a-statically-linked-executable) in the language reference.

When `--static` is given, linking static libraries is enabled, but it's not exclusive. The produced binary won't be fully static linked if the dynamic version of a library is higher in the compiler's library lookup chain than the static variant (or if the static library is entirely missing). In order to build a static binary you need to make sure that static versions of the linked libraries are available and the compiler can find them.

The compiler uses the `CRYSTAL_LIBRARY_PATH` environment variable as a first lookup destination for static and dynamic libraries that are to be linked. This can be used to provide static versions of libraries that are also available as dynamic libraries.

Not all libraries work well with being statically linked, so there may be some issues. `openssl` for example is known for complications, as well as `glibc` (see [Fully Static Linking](#fully-static-linking)).

Some package managers provide specific packages for static libraries, where `foo` provides the dynamic library and `foo-static` for example provides the static library. Sometimes static libraries are also included in development packages.

## Fully Static Linking

A fully statically linked program has no dynamic library dependencies at all. This is useful for delivering portable, pre-compiled binaries. Prominent examples of fully statically linked Crystal programs are the `crystal` and `shards` binaries from the official distribution packages.

In order to link a program fully statically, all dependencies need to be available as static libraries at compile time. This can be tricky sometimes, especially with common `libc` libraries.

### Linux

#### `glibc`

`glibc` is the most common `libc` implementation on Linux systems. Unfortunately, it doesn't play nicely with static linking and it's highly discouraged.

Instead, static linking against [`musl-libc`](#musl-libc) is the recommended option on Linux. Since it's statically linked, a binary linked against `musl-libc` will also run on a glibc system. That's the entire point of it.

It is however completely fine to statically link other libraries besides a dynamically linked `glibc`.

#### `musl-libc`

[`musl-libc`](https://musl.libc.org/) is a clean, efficient `libc` implementation with excellent static linking support.

The recommended way to build a statically linked Crystal program is [Alpine Linux](https://alpinelinux.org/), a minimal Linux distribution based on `musl-libc`.

Official [Docker Images based on Alpine Linux](https://crystal-lang.org/2020/02/02/alpine-based-docker-images.html) are available on Docker Hub at [`crystallang/crystal`](https://hub.docker.com/r/crystallang/crystal/). The latest release is tagged as `crystallang/crystal:latest-alpine`. The Dockerfile source is available at [crystal-lang/distribution-scripts](https://github.com/crystal-lang/distribution-scripts/blob/master/docker/alpine.Dockerfile).

With pre-installed `crystal` compiler, `shards`, and static libraries of all of stdlib's dependencies these Docker images allow to easily build static Crystal binaries even from `glibc`-based systems. The official Crystal compiler builds for Linux are created using these images.

Here's an example how the Docker image can be used to build a statically linked *Hello World* program:

```console
$ echo 'puts "Hello World!"' > hello-world.cr
$ docker run --rm -it -v $(pwd):/workspace -w /workspace crystallang/crystal:latest-alpine \
    crystal build hello-world.cr --static
$ ./hello-world
Hello World!
$ ldd hello-world
        statically linked
```

Alpine’s package manager APK is also easy to work with to install static libraries. Available packages can be found at [pkgs.alpinelinux.org](https://pkgs.alpinelinux.org/packages).

### macOS

macOS doesn't [officially support fully static linking](https://developer.apple.com/library/content/qa/qa1118/_index.html) because the required system libraries are not available as static libraries.

### Windows

#### MSVC

Windows doesn't support fully static linking because the Win32 libraries are not available as static libraries.

In order to distinguish static libraries from DLL import libraries, when the compiler searches for a library `foo.lib` in a given directory, `foo-static.lib` will be attempted first while linking statically, and `foo-dynamic.lib` will be attempted first while linking dynamically. The official Windows MSVC packages are distributed with both static and DLL import libraries for all third-party dependencies, except for LLVM, which is only available as an import library.

Static linking implies using the static version of Microsoft's Universal C Runtime (`/MT`), and dynamic linking implies the dynamic version (`/MD`); extra C libraries should be built with this in mind to avoid linker warnings about mixing CRT versions. All dynamically linked binaries, including the Crystal compiler itself, also require the [Microsoft Visual C++ Redistributable](https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170#latest-microsoft-visual-c-redistributable-version) to be installed. There is currently no way to use the dynamic CRT while linking statically.

#### MinGW-w64

MinGW-w64 provides only import libraries for the Win32 APIs and the C runtimes; therefore, unlike the MSVC toolchain, all libraries link against the C runtime dynamically, even for static builds. These binaries do not require the VC++ Redistributable since they use GCC's C++ ABI instead.

The default C runtime depends on MinGW-w64's build-time configuration, and this default is always called `libmsvcrt.a`. On an MSYS2 UCRT64 environment, this is a copy of `libucrt.a`, the Universal C Runtime, whereas on a MINGW64 environment, this is a copy of `libmsvcrt-os.a` instead, the old system MSVCRT runtime. This can be overridden using `--link-flags=-mcrtdll=ucrt` or `--link-flags=-mcrtdll=msvcrt-os`, provided the MinGW-w64 installation understands it.

## Identifying Static Dependencies

If you want to statically link dependencies, you need to have their static libraries available.
Most systems don't install static libraries by default, so you need to install them explicitly.
First you have to know which libraries your program links against.

NOTE:
Static libraries have the file extension `.a` on POSIX (including MinGW-w64) and `.lib` on Windows MSVC. DLL import libraries on Windows have the `.dll.a` extension for MinGW-w64 and `.lib` for MSVC.
Dynamic libraries have `.so` on Linux and most other POSIX platforms, `.dylib` on macOS and `.dll` on Windows.

On most POSIX systems the tool `ldd` shows which dynamic libraries an executable links to. The equivalent
on macOS is `otool -L` and the equivalent on Windows is `dumpbin /dependents`.

The following example shows the output of `ldd` for a simple *Hello World* program built with Crystal 0.36.1 and LLVM 10.0 on Ubuntu 18.04 LTS (in the `crystallang/crystal:0.36.1` docker image). The result varies on other systems and versions.

```console
$ ldd hello-world_glibc
    linux-vdso.so.1 (0x00007ffeaf990000)
    libpcre.so.3 => /lib/x86_64-linux-gnu/libpcre.so.3 (0x00007fc393624000)
    libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007fc393286000)
    libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007fc393067000)
    libevent-2.1.so.6 => /usr/lib/x86_64-linux-gnu/libevent-2.1.so.6 (0x00007fc392e16000)
    libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007fc392c12000)
    libgcc_s.so.1 => /lib/x86_64-linux-gnu/libgcc_s.so.1 (0x00007fc3929fa000)
    libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fc392609000)
    /lib64/ld-linux-x86-64.so.2 (0x00007fc393dde000)
```

These libraries are the minimal dependencies of Crystal's standard library.
Even an empty program requires these libraries for setting up the Crystal runtime.

This looks like a lot, but most of these libraries are actually part of the libc distribution.

On Alpine Linux the list is much smaller because musl includes more symbols directly into a
single binary. The following example shows the output of the same program built with Crystal 0.36.1 and LLVM 10.0 on Alpine Linux 3.12 (in the `crystallang/crystal:0.36.1-alpine` docker image).

```console
$ ldd hello-world_musl
    /lib/ld-musl-x86_64.so.1 (0x7fe14b05b000)
    libpcre.so.1 => /usr/lib/libpcre.so.1 (0x7fe14af1d000)
    libgc.so.1 => /usr/lib/libgc.so.1 (0x7fe14aead000)
    libgcc_s.so.1 => /usr/lib/libgcc_s.so.1 (0x7fe14ae99000)
    libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7fe14b05b000)
```

The individual libraries are `libpcre`, `libgc` and the rest is `musl` (`libc`). The same libraries are used in the Ubuntu example.

In order to link this program statically, we need static versions of these three libraries.

NOTE:
The `*-alpine` docker images ship with static versions of all libraries used by the standard library.
If your program links no other libraries then adding the `--static` flag to the build command is all you need to link fully statically.
# Code Coverage Reporting

Writing [tests](../testing.md) is an important part of creating an easy to maintain codebase by providing an automated way to ensure your program is doing what it should be.
But how do you know if you’re testing the right things, or how effective your tests actually are? Simple: code coverage reporting.

Code coverage reporting is a process in which your specs are ran, and some tool keeps track of what lines of code in your program were executed.
From here, the report may then be used to influence where to focus your efforts to improve the coverage percentage, or more ideally ensure all newly added code is covered.

## Crystal Code Coverage

Unfortunately there is no super straightforward way to do this via a single `--coverage` flag when running `crystal spec` for example.
But the overall process is not overly complex, just consists of a few steps:

1. Generate the “core” coverage report
2. Generate another report representing unreachable methods
3. Generate a report for macros

### Core Report

*The process for this section all was inspired from a [blog post](https://hannes.kaeufler.net/posts/measuring-code-coverage-in-crystal-with-kcov) by* @hanneskaeufler

Given there is no internal way to generate this report within Crystal itself, we need to look for alternatives.
The simplest of which is to make use of the fact Crystal uses [DWARF](https://dwarfstd.org/) for its debug information (the internal data used to power stack traces and such).
Knowing this we can use a tool like [kcov](https://github.com/SimonKagstrom/kcov) to read this information to produce our coverage report.

The one problem with `kcov` however, is that it needs to run against a built binary; meaning we can’t just leverage or tap into `crystal spec`, but instead must first build a binary that would run the specs when executed.
Because there is not single entrypoint into your specs, the easiest way to do this is by creating a file that requires all files within the `spec/` directory, then use that as the entrypoint.
Something like this, from the root of your shard:

```sh
echo 'require "./spec/**"' > './all_specs.cr'
mkdir ./bin
crystal build './all_specs.cr' -o './bin/all_specs'
```

From here you can run `kcov` against `./bin/all_specs`:

```sh
kcov --clean --include-path="./src" ./coverage ./bin/all_specs --order=random
```

Let’s break this down:

* `--clean` makes it so only the latest run is kept
* `--include-path` will only include `src/` in the report. I.e. we don’t want code from Crystal’s stdlib or external dependencies to be included
* `./coverage` represents the directory the report will be written to

The second argument is our built spec binary, which can still accept spec runner options like `--order=random`.

If all went well you should now have a `coverage/index.html` file that you can open in your browser to view your core coverage report.
It also includes various machine readable coverage report formats that we’ll get to later.

### Unreachable Code

Crystal’s compiler removes dead code automatically when building a binary, or in other words, things that are unused (methods, types, etc) will not be included at all in the resulting binary.
This is usually a good thing as it’s less code, thus reducing the final binary size.

However, the con of this feature is that because the compiler just totally ignores these unused methods, no type checking occurs on them.
This can lead to a sense of false security in that your code could compile just fine, but then start to fail once one of those unused methods starts being used if there is a syntax error within its definition for example.
Additionally, `kcov` is entirely unaware these methods exist and as such do not mark them as missed.

Fortunately for us, there is a built-in tool we can use to identify these unused methods:

```sh
crystal tool unreachable --format=codecov ./all_specs.cr > ./coverage/unreachable.codecov.json
```

This will output a report marking unreachable methods as missed.
More on the `--format=codecov` in the [Tooling](#tooling) section later on.

### Macro Code

Up until now, all of the coverage reporting we’ve generated are for the program at runtime.
However, Crystal’s [macros](../../syntax_and_semantics/macros/README.md) can be quite complex as well.
We can leverage another `crystal tool` to generate a coverage report for your program’s compile time macro code.
This step can be skipped of course if you don’t use any custom macros at all.

```sh
crystal tool macro_code_coverage ./all_specs.cr > ./coverage/macro_coverage.root.codecov.json
```

## Tooling

At this point you will have multiple files that each represent a portion of your program’s code coverage.
But it’s not super clear how they all fit together.
Taking things a step further we can leverage a vendor like [Codecov](https://about.codecov.io/) to provide extra capabilities to both make understanding your reports easier, integrate CI checks, and allow sharing results of your project.

All of the reports we generated are in the [codecov custom coverage format](https://docs.codecov.com/docs/codecov-custom-coverage-format).
(`kcov` also generates others which Codecov supports as well).
As such, we can upload all of them and Codecov will take care of merging them together into a single view of coverage.

This is as simple as setting up the [Codecov Action](https://github.com/codecov/codecov-action) if you’re using GitHub Actions.
For our case, the key thing we need to set is what files to upload, setting the `files` input to `'**/cov.xml,**/unreachable.codecov.json,**/macro_coverage.*.codecov.json'` to ensure all the files are uploaded.

There is a lot more nuance to code coverage than what is covered here.
The big one being that having 100% test coverage does not imply that your code is bug free, or that it’s even worth trying to get to that level.
Instead a good middle ground, for Codecov at least, is to set the target `patch` percentage to `100%` and set `project` target to `auto`.
These will ensure that all *new* code is fully covered and does not reduce the overall coverage of the codebase.
# Testing Crystal Code

Crystal comes with a fully-featured spec library in the [`Spec` module](https://crystal-lang.org/api/Spec.html). It provides a structure for writing executable examples of how your code should behave.

Inspired by [Rspec](http://rspec.info/), it includes a domain specific language (DSL) that allows you to write examples in a way similar to plain english.

A basic spec looks something like this:

```crystal
require "spec"

describe Array do
  describe "#size" do
    it "correctly reports the number of elements in the Array" do
      [1, 2, 3].size.should eq 3
    end
  end

  describe "#empty?" do
    it "is true when no elements are in the array" do
      ([] of Int32).empty?.should be_true
    end

    it "is false if there are elements in the array" do
      [1].empty?.should be_false
    end
  end
end
```

## Anatomy of a spec file

To use the spec module and DSL, you need to add `require "spec"` to your spec files. Many projects use a custom [spec helper](#spec-helper) which organizes these includes.

Concrete test cases are defined in `it` blocks. An optional (but strongly recommended) descriptive string states it's purpose and a block contains the main logic performing the test.

Test cases that have been defined or outlined but are not yet expected to work can be defined using `pending` instead of `it`. They will not be run but show up in the spec report as pending.

An `it` block contains an example that should invoke the code to be tested and define what is expected of it. Each example can contain multiple expectations, but it should test only one specific behaviour.

When `spec` is included, every object has the instance methods `#should` and `#should_not`. These methods are invoked on the value being tested with an expectation as argument. If the expectation is met, code execution continues. Otherwise the example has *failed* and other code in this block will not be executed.

In test files, specs are structured by example groups which are defined by `describe` and `context` sections. Typically a top level `describe` defines the outer unit (such as a class) to be tested by the spec. Further `describe` sections can be nested within the outer unit to specify smaller units under test (such as individual methods).

For unit tests, it is recommended to follow the conventions for method names: Outer `describe` is the name of the class, inner `describe` targets methods. Instance methods are prefixed with `#`, class methods with `.`.

To establish certain contexts - think *empty array* versus *array with elements* - the `context` method may be used to communicate this to the reader. It has a different name, but behaves exactly like `describe`.

`describe` and `context` take a description as argument (which should usually be a string) and a block containing the individual specs or nested groupings.

## Expectations

Expectations define if the value being tested (*actual*) matches a certain value or specific criteria.

### Equivalence, Identity and Type

There are methods to create expectations which test for equivalence (`eq`), identity (`be`), type (`be_a`), and nil (`be_nil`).
Note that the identity expectation uses `.same?` which tests if [`#object_id`](https://crystal-lang.org/api/Reference.html#object_id%3AUInt64-instance-method) are identical. This is only true if the expected value points to *the same object* instead of *an equivalent one*. This is only possible for reference types and won't work for value types like structs or numbers.

```crystal
actual.should eq(expected)   # passes if actual == expected
actual.should be(expected)   # passes if actual.same?(expected)
actual.should be_a(expected) # passes if actual.is_a?(expected)
actual.should be_nil         # passes if actual.nil?
```

### Truthiness

```crystal
actual.should be_true   # passes if actual == true
actual.should be_false  # passes if actual == false
actual.should be_truthy # passes if actual is truthy (neither nil nor false nor Pointer.null)
actual.should be_falsey # passes if actual is falsey (nil, false or Pointer.null)
```

### Comparisons

```crystal
actual.should be < expected  # passes if actual <  expected
actual.should be <= expected # passes if actual <= expected
actual.should be > expected  # passes if actual >  expected
actual.should be >= expected # passes if actual >= expected
```

### Other matchers

```crystal
actual.should be_close(expected, delta) # passes if actual is within delta of expected:
#                                         (actual - expected).abs <= delta
actual.should contain(expected) # passes if actual.includes?(expected)
actual.should match(expected)   # passes if actual =~ expected
```

### Expecting errors

These matchers run a block and pass if it raises a certain exception.

```crystal
expect_raises(MyError) do
  # Passes if this block raises an exception of type MyError.
end

expect_raises(MyError, "error message") do
  # Passes if this block raises an exception of type MyError
  # and the error message contains "error message".
end

expect_raises(MyError, /error \w{7}/) do
  # Passes if this block raises an exception of type MyError
  # and the error message matches the regular expression.
end
```

`expect_raises` returns the rescued exception so it can be used for further expectations, for example to verify specific properties of the exception.

```crystal
ex = expect_raises(MyError) do
  # Passes if this block raises an exception of type MyError.
end
ex.my_error_value.should eq "foo"
```

## Focusing on a group of specs

`describe`, `context` and `it` blocks can be marked with `focus: true`, like this:

```crystal
it "adds", focus: true do
  (2 + 2).should_not eq(5)
end
```

If any such thing is marked with `focus: true` then only those examples will run.

## Tagging specs

Tags can be used to group specs, allowing to only run a subset of specs when providing a `--tag` argument to the spec runner (see [Using the compiler](../man/crystal/README.md)).

`describe`, `context` and `it` blocks can be tagged, like this:

```crystal
it "is slow", tags: "slow" do
  sleep 60
  true.should be_true
end

it "is fast", tags: "fast" do
  true.should be_true
end
```

Tagging an example group (`describe` or `context`) extends to all of the contained examples.

Multiple tags can be specified by giving an [`Enumerable`](https://crystal-lang.org/api/Enumerable.html), such as [`Array`](https://crystal-lang.org/api/Array.html) or [`Set`](https://crystal-lang.org/api/Set.html).

## Running specs

The Crystal compiler has a `spec` command with tools to constrain which examples get run and tailor the output. All specs of a project are compiled and executed through the command `crystal spec`.

By convention, specs live in the `spec/` directory of a project. Spec files must end with `_spec.cr` to be recognizable as such by the compiler command.

You can compile and run specs from folder trees, individual files, or specific lines in a file. If the specified line is the beginning of a `describe` or `context` section, all specs inside that group are run.

The default formatter outputs the file and line style command for failing specs which makes it easy to rerun just this individual spec.

You can turn off colors with the switch `--no-color`.

### Randomizing order of specs

Specs, by default, run in the order defined, but can be run in a random order by passing `--order random` to `crystal spec`.

Specs run in random order will display a seed value upon completion. This seed value can be used to rerun the specs in that same order by passing the seed value to `--order`.

### Examples

```bash
# Run all specs in files matching spec/**/*_spec.cr
crystal spec

# Run  all specs in files matching spec/**/*_spec.cr without colors
crystal spec --no-color

# Run all specs in files matching spec/my/test/**/*_spec.cr
crystal spec spec/my/test/

# Run all specs in spec/my/test/file_spec.cr
crystal spec spec/my/test/file_spec.cr

# Run the spec or group defined in line 14 of spec/my/test/file_spec.cr
crystal spec spec/my/test/file_spec.cr:14

# Run all specs tagged with "fast"
crystal spec --tag 'fast'

# Run all specs not tagged with "slow"
crystal spec --tag '~slow'
```

There are additional options for running specs by name, adjusting output formats, doing dry-runs, etc, see [Using the compiler](../man/crystal/README.md#crystal-spec).

## Spec helper

Many projects use a custom spec helper file, usually named `spec/spec_helper.cr`.

This file is used to require `spec` and other includes like code from the project needed for every spec file. This is also a good place to define global helper methods that make writing specs easier and avoid code duplication.

```crystal title="spec/spec_helper.cr"
require "spec"
require "../src/my_project.cr"

def create_test_object(name)
  project = MyProject.new(option: false)
  object = project.create_object(name)
  object
end
```

```crystal title="spec/my_project_spec.cr"
require "./spec_helper"

describe "MyProject::Object" do
  it "is created" do
    object = create_test_object(name)
    object.should_not be_nil
  end
end
```
# Writing Shards

How to write and release Crystal Shards.

## *What's a Shard?*

Simply put, a Shard is a package of Crystal code, made to be shared-with and used-by other projects.

See [the Shards command](../man/shards/README.md) for details.

## Introduction

In this tutorial, we'll be making a Crystal library called *palindrome-example*.

> For those who don't know, a palindrome is a word which is spelled the same way forwards as it is backwards. e.g. racecar, mom, dad, kayak, madam

### Requirements

In order to release a Crystal Shard, and follow along with this tutorial, you will need the following:

* A working installation of the [Crystal compiler](../man/crystal/README.md)
* A working installation of [Git](https://git-scm.com)
* A [GitHub](https://github.com) or [GitLab](https://gitlab.com/) account

### Creating the Project

Begin by using [the Crystal compiler](../man/crystal/README.md)'s `init lib` command to create a Crystal library with the standard directory structure.

In your terminal: `crystal init lib <YOUR-SHARD-NAME>`

e.g.

```console
$ crystal init lib palindrome-example
    create  palindrome-example/.gitignore
    create  palindrome-example/.editorconfig
    create  palindrome-example/LICENSE
    create  palindrome-example/README.md
    create  palindrome-example/shard.yml
    create  palindrome-example/src/palindrome-example.cr
    create  palindrome-example/spec/spec_helper.cr
    create  palindrome-example/spec/palindrome-example_spec.cr
Initialized empty Git repository in /<YOUR-DIRECTORY>/.../palindrome-example/.git/
```

...and `cd` into the directory:

e.g.

```bash
cd palindrome-example
```

Then `add` & `commit` to start tracking the files with Git:

```console
$ git add -A
$ git commit -am "First Commit"
[master (root-commit) 77bad84] First Commit
 8 files changed, 104 insertions(+)
 create mode 100644 .editorconfig
 create mode 100644 .gitignore
 create mode 100644 LICENSE
 create mode 100644 README.md
 create mode 100644 shard.yml
 create mode 100644 spec/palindrome-example_spec.cr
 create mode 100644 spec/spec_helper.cr
 create mode 100644 src/palindrome-example.cr
```

### Writing the Code

The code you write is up to you, but how you write it impacts whether people want to use your library and/or help you maintain it.

#### Testing the Code

* Test your code. All of it. It's the only way for anyone, including you, to know if it works.
* Crystal has [a built-in testing library](https://crystal-lang.org/api/Spec.html). Use it!

#### Documentation

* Document your code with comments. All of it. Even the private methods.
* Crystal has [a built-in documentation generator](../syntax_and_semantics/documenting_code.md). Use it!

Run `crystal docs` to convert your code and comments into interlinking API documentation. Open the files in the `/docs/` directory with a web browser to see how your documentation is looking along the way.

See below for instructions on hosting your compiler-generated docs on GitHub/GitLab Pages.

Once your documentation is ready and available, you can add a documentation badge to your repository so users know that it exists. In GitLab this badge belongs to the project so we'll cover it in the GitLab instructions below, for GitHub it is common to place it below the description in your README.md like so:
(Be sure to replace `<LINK-TO-YOUR-DOCUMENTATION>` accordingly)

```markdown
[![Docs](https://img.shields.io/badge/docs-available-brightgreen.svg)](<LINK-TO-YOUR-DOCUMENTATION>)
```

### Writing a README

A good README can make or break your project.
[Awesome README](https://github.com/matiassingers/awesome-readme) is a nice curation of examples and resources on the topic.

Most importantly, your README should explain:

1. What your library is
2. What it does
3. How to use it

This explanation should include a few examples along with subheadings.

NOTE: Be sure to replace all instances of `[your-github-name]` in the Crystal-generated README template with your GitHub/GitLab username. If you're using GitLab, you'll also want to change all instances of `github` with `gitlab`.

#### Coding Style

* It's fine to have your own style, but sticking to [some core rubrics defined by the Crystal team](../conventions/coding_style.md) can help keep your code consistent, readable and usable for other developers.
* Utilize Crystal's [built-in code formatter](../syntax_and_semantics/documenting_code.md) to automatically format all `.cr` files in a directory.

e.g.

```
crystal tool format
```

To check if your code is formatted correctly, or to check if using the formatter wouldn't produce any changes, simply add `--check` to the end of this command.

e.g.

```
crystal tool format --check
```

This check is good to add as a step in [continuous integration](ci/README.md).

### Writing a `shard.yml`

[The spec](https://github.com/crystal-lang/shards/blob/master/docs/shard.yml.adoc) is your rulebook. Follow it.

#### Name

Your `shard.yml`'s `name` property should be concise and descriptive.

* Search any of the available [shard databases](https://crystal-lang.org/community/#shards) to check if your name is already taken.

e.g.

```yaml
name: palindrome-example
```

#### Description

Add a `description` to your `shard.yml`.

A `description` is a single line description used to search for and find your shard.

A description should be:

1. Informative
2. Discoverable

#### Optimizing

It's hard for anyone to use your project if they can't find it.
There are several services for discovering shards, a list is available on the [Crystal Community page](https://crystal-lang.org/community/#shards).

There are people looking for the *exact* functionality of our library and the *general* functionality of our library.
e.g. Bob needs a palindrome library, but Felipe is just looking for libraries involving text and Susan is looking for libraries involving spelling.

Our `name` is already descriptive enough for Bob's search of "palindrome". We don't need to repeat the *palindrome* keyword. Instead, we'll catch Susan's search for "spelling" and Felipe's search for "text".

```yaml
description: |
  A textual algorithm to tell if a word is spelled the same way forwards as it is backwards.
```

### Hosting

From here the guide differs depending on whether you are hosting your repo on GitHub or GitLab. If you're hosting somewhere else, please feel free to write up a guide and add it to this book!

* [Hosting on GitHub](./hosting/github.md)
* [Hosting on GitLab](./hosting/gitlab.md)
# Manuals

Technical details about commands and tools of Crystal.
# Using the compiler

## Compiling and running at once

To compile and run a program in a single shot, invoke [`crystal run`](#crystal-run) with a single filename:

```console
$ echo 'puts "Hello World!"' > hello_world.cr
$ crystal run hello_world.cr
Hello World!
```

The `run` command compiles the source file `hello_world.cr` to a binary executable in a temporary location
and immediately executes it.

## Creating an executable

The [`crystal build`](#crystal-build) command builds a binary executable.
The output file has the same name as the source file minus the extension `.cr`.

```console
$ crystal build hello_world.cr
$ ./hello_world
Hello World!
```

### Release builds

By default, the generated executables are not fully optimized. The `--release` flag can be used to enable optimizations.

```console
$ crystal build hello_world.cr --release
```

Compiling without release mode is much faster and the resulting binaries still offer pretty good performance.

Building in release mode should be used for production-ready executables and when performing benchmarks.
For simple development builds, there is usually no reason to do so.

To reduce the binary size for distributable files, the `--no-debug` flag can be used. This removes debug symbols reducing file size, but obviously making debugging more difficult.

### Creating a statically-linked executable

The `--static` flag can be used to build a statically-linked executable:

```console
$ crystal build hello_world.cr --release --static
```

NOTE: Building fully statically linked executables is currently only supported on Alpine Linux.

More information about statically linking [can be found in the Static Linking guide](../../guides/static_linking.md).

The compiler uses the `CRYSTAL_LIBRARY_PATH` environment variable as a first lookup destination for static and dynamic libraries that are to be linked. This can be used to provide static versions of libraries that are also available as dynamic libraries.

### Creating a Crystal project

The [`crystal init`](#crystal-init) command helps to initialize a Crystal project folder, setting
up a basic project structure. `crystal init app <name>` is used for an application,
`crystal init lib <name>` for a library.

```console
$ crystal init app myapp
    create  myapp/.gitignore
    create  myapp/.editorconfig
    create  myapp/LICENSE
    create  myapp/README.md
    create  myapp/shard.yml
    create  myapp/src/myapp.cr
    create  myapp/spec/spec_helper.cr
    create  myapp/spec/myapp_spec.cr
Initialized empty Git repository in /home/crystal/myapp/.git/
```

Not all of these files are required for every project, and some might need more customization, but `crystal init` creates a good default environment for developing Crystal applications and libraries.

## Compiler commands

* [`crystal init`](#crystal-init): generate a new project
* [`crystal build`](#crystal-build): build an executable
* [`crystal docs`](#crystal-docs): generate documentation
* [`crystal env`](#crystal-env): print Crystal environment information
* [`crystal eval`](#crystal-eval): eval code from args or standard input
* [`crystal play`](#crystal-play): starts Crystal playground server
* [`crystal run`](#crystal-run): build and run program
* [`crystal spec`](#crystal-spec): build and run specs
* [`crystal tool`](#crystal-tool): run a compiler tool
* [`crystal clear_cache`](#crystal-clear_cache): clear the compiler cache
* `crystal help`: show help about commands and options
* [`crystal version`](#crystal-version): show version

To see the available options for a particular command, use `--help` after a command:

### `crystal run`

The `run` command compiles a source file to a binary executable and immediately runs it.

```
crystal [run] [<options>] <programfile> [-- <argument>...]
```

Arguments to the compiled binary can be separated with double dash `--` from the compiler arguments.
The binary executable is stored in a temporary location between compiling and running.

Example:

```console
$ echo 'puts "Hello #{ARGV[0]?}!"' > hello_world.cr
$ crystal run hello_world.cr -- Crystal
Hello Crystal!
```

**Common options:**

* `-O LEVEL`: Define optimization level: 0 (default), 1, 2, 3. See [Optimizations](#optimizations) for details.
* `--release`: Compile in release mode. Equivalent to `-O3 --single-module`.
* `--progress`: Show progress during compilation.
* `--static`: Link statically.

More options are described in the integrated help: `crystal run --help` or man page `man crystal`.

### `crystal build`

The `crystal build` command builds a dynamically-linked binary executable.

```
crystal build [<options>] <programfile>
```

Unless specified, the resulting binary will have the same name as the source file minus the extension `.cr`.

Example:

```console
$ echo 'puts "Hello #{ARGV[0]?}!"' > hello_world.cr
$ crystal build hello_world.cr
$ ./hello_world Crystal
Hello Crystal!
```

**Common options:**

* `--cross-compile`: Generate a .o file, and print the command to generate an executable to stdout.
* `-D FLAG, --define FLAG`: Define a compile-time flag.
* `-o <path>`, `--output <path>`: Path to the output file. If a directory, the filename is derived from the first source file (default: current directory).
* `-O LEVEL`: Define optimization level: 0 (default), 1, 2, 3. See [Optimizations](#optimizations) for details.
* `--release`: Compile in release mode. Equivalent to `-O3 --single-module`.
* `--link-flags FLAGS`: Additional flags to pass to the linker.
* `--no-debug`: Skip any symbolic debug info, reducing the output file size.
* `--progress`: Show progress during compilation.
* `--static`: Link statically.
* `--verbose`: Display executed commands.

More options are described in the integrated help: `crystal build --help` or man page `man crystal`.

### `crystal eval`

The `crystal eval` command reads Crystal source code from command line or stdin, compiles it to a binary executable and immediately runs it.

```
crystal eval [<options>] [<source>]
```

If no `source` argument is provided, the Crystal source is read from standard input. The binary executable is stored in a temporary location between compiling and running.

Example:

```console
$ crystal eval 'puts "Hello World"'
Hello World!
$ echo 'puts "Hello World"' | crystal eval
Hello World!
```

NOTE: When running interactively, stdin can usually be closed by typing the end of transmission character (`Ctrl+D`).

**Common options:**

* `-o <output_file>`: Define the name of the binary executable.
* `-O LEVEL`: Define optimization level: 0 (default), 1, 2, 3. See [Optimizations](#optimizations) for details.
* `--release`: Compile in release mode. Equivalent to `-O3 --single-module`.
* `--no-debug`: Skip any symbolic debug info, reducing the output file size.
* `--progress`: Show progress during compilation.
* `--static`: Link statically.

More options are described in the integrated help: `crystal eval --help` or man page `man crystal`.

### `crystal version`

The `crystal version` command prints the Crystal version, LLVM version and default target triple.

```
crystal version
```

Example:

```console
$ crystal version
--8<-- "crystal-version.txt"
```

### `crystal init`

The `crystal init` command initializes a Crystal project folder.

```
crystal init (lib|app) <name> [<dir>]
```

The first argument is either `lib` or `app`. A `lib` is a reusable library whereas `app` describes
an application not intended to be used as a dependency. A library doesn't have a `shard.lock` file
in its repository and no build target in `shard.yml`, but instructions for using it as a dependency.

Example:

```console
$ crystal init lib my_cool_lib
    create  my_cool_lib/.gitignore
    create  my_cool_lib/.editorconfig
    create  my_cool_lib/LICENSE
    create  my_cool_lib/README.md
    create  my_cool_lib/shard.yml
    create  my_cool_lib/src/my_cool_lib.cr
    create  my_cool_lib/spec/spec_helper.cr
    create  my_cool_lib/spec/my_cool_lib_spec.cr
Initialized empty Git repository in ~/my_cool_lib/.git/
```

### `crystal docs`

The `crystal docs` command generates API documentation from inline docstrings in Crystal files (see [*Documenting Code*](../../syntax_and_semantics/documenting_code.md)).

```bash
crystal docs [--output=<output_dir>] [--canonical-base-url=<url>] [<source_file>...]
```

The command creates a static website in `output_dir` (default `./docs`), consisting of HTML files for each Crystal type,
in a folder structure mirroring the Crystal namespaces. The entrypoint `docs/index.html` can be opened by any web browser.
The entire API docs are also stored as a JSON document in `$output_dir/index.json`.

By default, all Crystal files in `./src` will be appended (i.e. `src/**/*.cr`).
In order to account for load-order dependencies, `source_file` can be used to specify one (or multiple)
entrypoints for the docs generator.

```bash
crystal docs src/my_app.cr
```

**Common options:**

* `--project-name=NAME`: Set the project name. The default value is extracted from `shard.yml` if available. In case no default can be found, this option is mandatory.
* `--project-version=VERSION`: Set the project version. The default value is extracted from current git commit or `shard.yml` if available. In case no default can be found, this option is mandatory.
* `--output=DIR, -o DIR`: Set the output directory (default: `./docs`)
* `--canonical-base-url=URL, -b URL`: Set the [canonical base url](https://en.wikipedia.org/wiki/Canonical_link_element)

For the above example to output the docs at `public` with custom canonical base url, and entrypoint `src/my_app.cr`,
the following arguments can be used:

```bash
crystal docs --output public --canonical-base-url http://example.com/ src/my_app.cr
```

### `crystal env`

The `crystal env` command prints environment variables used by Crystal.

```bash
crystal env [<var>...]
```

By default, it prints information as a shell script. If one or more `var` arguments are provided,
the value of each named variable is printed on its own line.

Example:

```console
$ crystal env
CRYSTAL_CACHE_DIR=/home/crystal/.cache/crystal
CRYSTAL_PATH=lib:/usr/bin/../share/crystal/src
CRYSTAL_VERSION=1.9.0
CRYSTAL_LIBRARY_PATH=/usr/bin/../lib/crystal
CRYSTAL_LIBRARY_RPATH=''
CRYSTAL_OPTS=''
$ crystal env CRYSTAL_VERSION
1.9.0
```

### `crystal spec`

The `crystal spec` command compiles and runs a Crystal spec suite.

```
crystal spec [<options>] [<file>[:line] | <folder>]... [-- [<runner_options>]]
```

All `files` arguments are concatenated into a single Crystal source. If an argument points to a folder, all spec
files inside that folder (and its recursive subfolders) named `*_spec.cr` are appended.
If no `files` argument is provided, the default is the `./spec` folder.
A filename can be suffixed by `:` and a line number, providing this location to the `--location` runner option (see below).

Run `crystal spec --options` for available preceding options.

**Runner options:**

`runner_options` are provided to the compiled binary executable which runs the specs. They should be separated from
the other arguments by a double dash (`--`).

* `--verbose`, `-v`: Prints verbose output, including all example names.
* `--profile`, `-p`: Prints the 10 slowest specs.
* `--fail-fast`: Abort the spec run on first failure.
* `--junit_output <output_dir>`: Generates JUnit XML output.
* `--tap`: Generates output for the [*Test Anything Protocol* (TAP)](https://testanything.org/).
* `--(no-)color`: Enables ANSI colored output. The default mode automatically enables color if STDOUT is a TTY.
* `--order <mode>`: Run examples in the given order. `<mode>` is either `default` (definition order), `random`, or a numeric seed value. Default value is `default`.
* `--list-tags`: Lists all defined tags and exits.
* `--dry-run`: Passes all tests without actually executing them.
* `--help`, `-h`: Prints help and exits.

The following runner options can be combined to filter the list of specs to run.

* `--example <name>`, `-e <name>`: Runs examples whose full nested names include `<name>`.
* `--line <line>`, `-l <line>`: Runs examples whose line matches `<line>`.
* `--location <file>:<line>`: Runs example(s) at `<line>` in `<file>` (multiple options allowed).
* `--tag <tag>`: Runs examples with the specified tag, or excludes examples by adding `~` before the tag (multiple options allowed).
    * `--tag a --tag b` will include specs tagged with `a` OR `b`.
    * `--tag ~a --tag ~b` will include specs not tagged with `a` AND not tagged with `b`.
    * `--tag a --tag ~b` will include specs tagged with `a`, but not tagged with `b`

Example:

```console
$ crystal spec
F

Failures:

  1) Myapp works
     Failure/Error: false.should eq(true)

       Expected: true
            got: false

     # spec/myapp_spec.cr:7

Finished in 880 microseconds
1 examples, 1 failures, 0 errors, 0 pending

Failed examples:

crystal spec spec/myapp_spec.cr:6 # Myapp works
```

### `crystal play`

The `crystal play` command starts a webserver serving an interactive Crystal playground.

```
crystal play [--port <port>] [--binding <host>] [--verbose] [file]
```

![Screenshot of Crystal playground](crystal-play.png)

### `crystal tool`

* `crystal tool context`: Show context for given location
* [`crystal tool dependencies`](#crystal-tool-dependencies): Show tree of required source files
* `crystal tool expand`: Show macro expansion for given location
* `crystal tool flags`: Print all macro `flag?` values
* [`crystal tool format`](#crystal-tool-format): Format Crystal files
* `crystal tool hierarchy`: Show type hierarchy
* `crystal tool implementations`: Show implementations for given call in location
* `crystal tool types`: Show types of main variables
* [`crystal tool unreachable`](#crystal-tool-unreachable): Show methods that are never called.

### `crystal tool dependencies`

Show tree of required source files.

```
crystal tool dependencies [options] [programfile]
```

Options:

* `-D FLAG`, `--define FLAG`: Define a compile-time flag. This is useful to
  conditionally define types, methods, or commands based on flags available at
  compile time. The default flags are from the target triple given with
  `--target-triple` or the hosts default, if none is given.
* `-f FORMAT`, `--format FORMAT`: Output format `tree` (default), `flat`, `dot`, or `mermaid`.
* `-i PATH`, `--include PATH`: Include path in output.
* `-e PATH`, `--exclude PATH`: Exclude path in output.
* `--verbose`: Show skipped and heads of filtered paths
* `--error-trace`: Show full error trace.
* `-h`, `--help`: Show this message
* `--prelude PATH`: Specify prelude to use. The default one initializes the garbage
  collector. You can also use `--prelude=empty` to use no preludes. This can be
  useful for checking code generation for a specific source code file.
* `-s`, `--stats`: Enable statistics output
* `-p`, `--progress`: Enable progress output
* `-t`, `--time`: Enable execution time output
* `--stdin-filename`: Source file name to be read from STDIN

### `crystal tool format`

The `crystal tool format` command applies default format to Crystal source files.

```
crystal tool format [--check] [<path>...]
```

`path` can be a file or folder name and include all Crystal files in that folder tree. Omitting `path` is equal to
specifying the current working directory.

The formatter also applies to Crystal code blocks in comments (see [*Documenting Code*](../../syntax_and_semantics/documenting_code.md)).

### `crystal tool unreachable`

Show methods that are never called.

```
crystal tool unreachable [options] [programfile]
```

The text output is a list of lines with columns separated by tab.

Output fields:

* `count`: sum of all calls to this method (only with `--tallies` option; otherwise skipped)
* `location`: pathname, line and column, all separated by colon
* `name`
* `lines`: length of the def in lines
* `annotations`

Options:

* `-D FLAG`, `--define FLAG`: Define a compile-time flag
* `-f FORMAT`, `--format FORMAT`: Output format `text` (default), `json`, or `csv`
* `--tallies`: Print reachable methods and their call counts as well.
* `--check`: Exit with error if there is any unreachable code.
* `--error-trace`: Show full error trace
* `-h`, `--help`: Show this message
* `-i PATH`, `--include PATH`: Include path
* `-e PATH`, `--exclude PATH`: Exclude path (default: `lib`)
* `--no-color`: Disable colored output
* `--prelude PATH`: Use given file as prelude
* `-s`, `--stats`: Enable statistics output
* `-p`, `--progress`: Enable progress output
* `-t`, `--time`: Enable execution time output
* `--stdin-filename`: Source file name to be read from STDIN

### `crystal clear_cache`

Clears the compiler cache located at [`CRYSTAL_CACHE_DIR`](#environment-variables).

## Optimizations

The optimization level specifies the codegen effort for producing optimal code.
It's a trade-off between compilation performance (decreasing per optimization level) and runtime performance (increasing per optimization level).

Production builds should usually have the highest optimization level.
Best results are achieved with `--release` which also implies `--single-module`.

* `-O0`: No optimization (default)
* `-O1`: Low optimization
* `-O2`: Middle optimization
* `-O3`: High optimization
* `-Os`: Middle optimization with focus on file size
* `-Oz`: Middle optimization aggressively focused on file size

## Environment variables

The following environment variables are used by the Crystal compiler if set in the environment. Otherwise the compiler will populate them with default values. Their values can be inspected using [`crystal env`](#crystal-env).

* `CRYSTAL_CACHE_DIR`: Defines path where Crystal caches partial compilation results for faster subsequent builds. This path is also used to temporarily store executables when Crystal programs are run with [`crystal run`](#crystal-run) rather than [`crystal build`](#crystal-build).
  Default value is the first directory that either exists or can be created of `${XDG_CACHE_HOME}/crystal` (if `XDG_CACHE_HOME` is defined), `${HOME}/.cache/crystal`, `${HOME}/.crystal`, `./.crystal`. If `CRYSTAL_CACHE_DIR` is set but points to a path that is not writeable, the default values are used instead.
* `CRYSTAL_EXEC_PATH`: Determines the path where *crystal* looks for external sub-commands.
* `CRYSTAL_PATH`: Defines paths where Crystal searches for required files.
* `CRYSTAL_VERSION` is only available as output of [`crystal env`](#crystal-env). The compiler neither sets nor reads it.
* `CRYSTAL_LIBRARY_PATH`: The compiler uses the paths in this variable as a first lookup destination for static and dynamic libraries that are to be linked. For example, if static libraries are put in `build/libs`, setting the environment variable accordingly will tell the compiler to look for libraries there.

The compiler conforms to [`NO_COLOR`](https://no-color.org/) and turns off ANSI color escapes in the terminal when the environment variable `NO_COLOR` is present (has a value other than the empty string).
# Required libraries

This is a list of third-party libraries used by the Crystal compiler and the standard library.

## Core runtime dependencies

The libraries in this section are always required by Crystal's stdlib runtime. They must be present for building or running any Crystal program that uses the standard library.
Avoiding these dependencies is only possible when not using the standard library (`--prelude=empty` compiler option).

### System library

A major component is the system library. Selection depends on the target platform and multiple are supported.
This usually includes the C standard library as well as additional system libraries such as `libdl`, `libm`, `libpthread`, `libcmt`, or `libiconv`
which may be part of the C library or standalone libraries. On most platforms all these libraries are provided by the operating system.

| Library | Description | License |
|---------|-------------|---------|
| [glibc][glibc]<br>[![latest packaged version(s)](https://repology.org/badge/latest-versions/glibc.svg?header=latest)](https://repology.org/project/glibc/versions) | standard C library for Linux <br>**Supported versions:** GNU libc 2.26+ | [LGPL](https://www.gnu.org/licenses/lgpl-3.0.en.html) |
| [musl libc][musl-libc]<br>[![latest packaged version(s)](https://repology.org/badge/latest-versions/musl.svg?header=latest)](https://repology.org/project/musl/versions) | standard C library for Linux <br>**Supported versions:** MUSL libc 1.2+ | [MIT](https://git.musl-libc.org/cgit/musl/tree/COPYRIGHT) |
| [FreeBSD libc][freebsd-libc]<br>[![latest packaged version(s)](https://repology.org/badge/latest-versions/freebsd.svg?header=latest)](https://repology.org/project/freebsd/versions) | standard C library for FreeBSD <br>**Supported versions:** 12+ | [BSD](https://www.freebsd.org/copyright/freebsd-license/) |
| [NetBSD libc][netbsd-libc] | standard C library for NetBSD | [BSD](http://www.netbsd.org/about/redistribution.html) |
| [OpenBSD libc][openbsd-libc]<br>[![latest packaged version(s)](https://repology.org/badge/latest-versions/openbsd.svg?header=latest)](https://repology.org/project/openbsd/versions) | standard C library for OpenBSD <br>**Supported versions:** 6+ | [BSD](https://www.openbsd.org/policy.html) |
| [Dragonfly libc][dragonfly-libc] | standard C library for DragonflyBSD | [BSD](https://www.dragonflybsd.org/docs/developer/DragonFly_BSD_License/) |
| [macOS libsystem][macos-libsystem] | standard C library for macOS <br>**Supported versions:** 11+ | [Apple](https://github.com/apple-oss-distributions/Libsystem/blob/main/APPLE_LICENSE) |
| [MSVCRT][msvcrt] | standard C library for Visual Studio 2013 or below | |
| [UCRT][ucrt] | Universal CRT for Windows / Visual Studio 2015+ | [MIT subset available](https://www.nuget.org/packages/Microsoft.Windows.SDK.CRTSource/10.0.22621.3/License) |
| [WASI][wasi]<br>[![latest packaged version(s)](https://repology.org/badge/latest-versions/wasi-libc.svg?header=latest)](https://repology.org/project/wasi-libc/versions) | WebAssembly System Interface | [Apache v2 and others](https://github.com/WebAssembly/wasi-libc/blob/main/LICENSE) |
| [bionic libc][bionic-libc] | C library for Android <br>**Supported versions:** ABI Level 24+ | [BSD-like](https://android.googlesource.com/platform/bionic/+/refs/heads/master/libc/NOTICE) |

### Other runtime libraries

| Library | Description | License |
|---------|-------------|---------|
| [Boehm GC][libgc]<br>[![latest packaged version(s)](https://repology.org/badge/latest-versions/boehm-gc.svg?header=latest)](https://repology.org/project/boehm-gc/versions) | The Boehm-Demers-Weiser conservative garbage collector. Performs automatic memory management.<br>**Supported versions:** 8.2.0+; earlier versions require a patch for MT support | [MIT-style](https://github.com/ivmai/bdwgc/blob/master/LICENSE) |
| [Libevent][libevent]<br>[![latest packaged version(s)](https://repology.org/badge/latest-versions/llvm.svg?header=latest)](https://repology.org/project/llvm/versions) | An event notification library. Implements the event loop on OpenBSD, NetBSD, DragonflyBSD and Solaris by default and on other Unix-like systems with `-Devloop=libevent` ([availability](https://github.com/crystal-lang/rfcs/blob/main/text/0009-lifetime-event_loop.md#availability)). Never used on Windows or WASI. | [Modified BSD](https://github.com/libevent/libevent/blob/master/LICENSE) |
| [compiler-rt builtins][compiler-rt] | Provides optimized implementations for low-level routines required by code generation, such as integer multiplication. Several of these routines are ported to Crystal directly. | [MIT / UIUC][compiler-rt] |

## Optional standard library dependencies

These libraries are required by different parts of the standard library, only when explicitly used.

### Regular Expression engine

Engine implementation for the [`Regex`](https://crystal-lang.org/api/Regex.html) class.
PCRE2 support was added in Crystal 1.7 and it's the default since 1.8 (see [Regex documentation](../syntax_and_semantics/literals/regex.md)).

| Library | Description | License |
|---------|-------------|---------|
| [PCRE2][libpcre]<br>[![latest packaged version(s)](https://repology.org/badge/latest-versions/pcre2.svg?header=latest)](https://repology.org/project/pcre2/versions) | Perl Compatible Regular Expressions, version 2.<br>**Supported versions:** all (recommended: 10.36+) | [BSD](http://www.pcre.org/licence.txt) |
| [PCRE][libpcre]<br>[![latest packaged version(s)](https://repology.org/badge/latest-versions/pcre.svg?header=latest)](https://repology.org/project/pcre/versions) | Perl Compatible Regular Expressions. | [BSD](http://www.pcre.org/licence.txt) |

### Big Numbers

Implementations for `Big` types such as [`BigInt`](https://crystal-lang.org/api/BigInt.html).

| Library | Description | License |
|---------|-------------|---------|
| [GMP][libgmp]<br>[![latest packaged version(s)](https://repology.org/badge/latest-versions/gmp.svg?header=latest)](https://repology.org/project/gmp/versions) | GNU multiple precision arithmetic library. | [LGPL v3+ / GPL v2+](https://gmplib.org/manual/Copying) |
| [MPIR][libmpir]<br>[![latest packaged version(s)](https://repology.org/badge/latest-versions/mpir.svg?header=latest)](https://repology.org/project/mpir/versions) | Multiple Precision Integers and Rationals, forked from GMP. Used on Windows MSVC. | [GPL-3.0](https://github.com/wbhart/mpir/blob/master/COPYING) and [LGPL-3.0](https://github.com/wbhart/mpir/blob/master/COPYING.LIB) |

### Internationalization conversion

This is either a standalone library or may be provided as part of the system library on some platforms. May be disabled with the `-Dwithout_iconv` compile-time flag.
Using a standalone library over the system library implementation can be enforced with the `-Duse_libiconv` compile-time flag.

| Library | Description | License |
|---------|-------------|---------|
| [libiconv][libiconv-gnu] (GNU)<br>[![latest packaged version(s)](https://repology.org/badge/latest-versions/libiconv.svg?header=latest)](https://repology.org/project/libiconv/versions) | Internationalization conversion library. | [LGPL-3.0](https://www.gnu.org/licenses/lgpl.html) |

### TLS

TLS protocol implementation and general-purpose cryptographic routines for the [`OpenSSL`](https://crystal-lang.org/api/OpenSSL.html) API. May be disabled with the `-Dwithout_openssl` [compile-time flag](../syntax_and_semantics/compile_time_flags.md#stdlib-features).

Both `OpenSSL` and `LibreSSL` are supported and the bindings automatically detect which library and API version is available on the host system.

| Library | Description | License |
|---------|-------------|---------|
| [OpenSSL][openssl]<br>[![latest packaged version(s)](https://repology.org/badge/latest-versions/openssl.svg?header=latest)](https://repology.org/project/openssl/versions) | Implementation of the SSL and TLS protocols <br>**Supported versions:** 1.1.1+–3.4+ | [Apache v2 (3.0+), OpenSSL / SSLeay (1.x)](https://www.openssl.org/source/license.html) |
| [LibreSSL][libressl]<br>[![latest packaged version(s)](https://repology.org/badge/latest-versions/libressl.svg?header=latest)](https://repology.org/project/libressl/versions) | Implementation of the SSL and TLS protocols; forked from OpenSSL in 2014 <br>**Supported versions:** 3.0–4.0+ | [ISC / OpenSSL / SSLeay](https://github.com/libressl-portable/openbsd/blob/master/src/lib/libssl/LICENSE) |

### Other stdlib libraries

| Library | Description | License |
|---------|-------------|---------|
| [LibXML2][libxml2]<br>[![latest packaged version(s)](https://repology.org/badge/latest-versions/libxml2.svg?header=latest)](https://repology.org/project/libxml2/versions) | XML parser developed for the Gnome project. Implements the [`XML`](https://crystal-lang.org/api/XML.html) module.<br>**Supported versions:** LibXML2 2.9–2.14 | [MIT](https://gitlab.gnome.org/GNOME/libxml2/-/blob/master/Copyright) |
| [LibYAML][libyaml]<br>[![latest packaged version(s)](https://repology.org/badge/latest-versions/libyaml.svg?header=latest)](https://repology.org/project/libyaml/versions) | YAML parser and emitter library. Implements the [`YAML`](https://crystal-lang.org/api/YAML.html) module. | [MIT](https://github.com/yaml/libyaml/blob/master/License) |
| [zlib][zlib]<br>[![latest packaged version(s)](https://repology.org/badge/latest-versions/zlib.svg?header=latest)](https://repology.org/project/zlib/versions) | Lossless data compression library. Implements the [`Compress`](https://crystal-lang.org/api/Compress.html) module. May be disabled with the `-Dwithout_zlib` compile-time flag. | [zlib](http://zlib.net/zlib_license.html) |
| [LLVM][libllvm]<br>[![latest packaged version(s)](https://repology.org/badge/latest-versions/llvm.svg?header=latest)](https://repology.org/project/llvm/versions) | Target-independent code generator and optimizer. Implements the [`LLVM`](https://crystal-lang.org/api/LLVM.html) API. <br>**Supported versions:** LLVM 8-22 (aarch64 requires LLVM 13+) | [Apache v2 with LLVM exceptions](https://llvm.org/docs/DeveloperPolicy.html#new-llvm-project-license-framework) |

## Compiler dependencies

In addition to the [core runtime dependencies](#core-runtime-dependencies), these libraries are needed to build the Crystal compiler.

| Library | Description | License |
|---------|-------------|---------|
| [PCRE2][libpcre] | See above. | |
| [LLVM][libllvm] | See above. | [Apache v2 with LLVM exceptions](https://llvm.org/docs/DeveloperPolicy.html#new-llvm-project-license-framework) |
| [libffi][libffi]<br>[![latest packaged version(s)](https://repology.org/badge/latest-versions/libffi.svg?header=latest)](https://repology.org/project/libffi/versions) | Foreign function interface. Used for implementing binary interfaces in the interpreter. May be disabled with the `-Dwithout_interpreter` compile-time flag. | [MIT](https://github.com/libffi/libffi/blob/master/LICENSE) |

[bionic-libc]: https://android.googlesource.com/platform/bionic/+/refs/heads/master/libc/
[compiler-rt]: https://compiler-rt.llvm.org/
[dragonfly-libc]: http://gitweb.dragonflybsd.org/dragonfly.git/tree/refs/heads/master:/lib/libc
[freebsd-libc]: https://svn.freebsd.org/base/head/lib/libc/
[glibc]: https://www.gnu.org/software/libc/
[libevent]: https://libevent.org/
[libffi]: https://sourceware.org/libffi/
[libgc]: https://github.com/ivmai/bdwgc
[libgmp]: https://gmplib.org/
[libiconv-gnu]: https://www.gnu.org/software/libiconv/
[libllvm]: https://llvm.org/
[libmpir]: https://github.com/wbhart/mpir
[libpcre]: http://www.pcre.org/
[libressl]: https://www.libressl.org/
[libxml2]: http://xmlsoft.org/
[libyaml]: https://pyyaml.org/wiki/LibYAML
[macos-libsystem]: https://github.com/apple-oss-distributions/Libsystem
[msvcrt]: https://web.archive.org/web/20150630135610/https://msdn.microsoft.com/en-us/library/abx4dbyh.aspx
[musl-libc]: https://musl.libc.org/
[netbsd-libc]: http://cvsweb.netbsd.org/bsdweb.cgi/src/lib/libc/?only_with_tag=MAIN
[openbsd-libc]: http://cvsweb.openbsd.org/cgi-bin/cvsweb/src/lib/libc/
[openssl]: https://www.openssl.org/
[ucrt]: https://learn.microsoft.com/en-us/cpp/windows/universal-crt-deployment?view=msvc-170
[wasi]: https://wasi.dev/
[zlib]: http://zlib.net/
# The shards command

Crystal is typically accompanied by Shards, its dependency manager.

It manages dependencies for Crystal projects and libraries with reproducible
installs across computers and systems.

## Installation

Shards is usually distributed with Crystal itself. Alternatively, a separate `shards` package may be available for your system.

To install from source, download or clone [the repository](https://github.com/crystal-lang/shards) and run `make CRFLAGS=--release`. The compiled binary is in `bin/shards` and should be added to `PATH`.

## Usage

`shards` requires the presence of a `shard.yml` file in the project folder (working directory). This file describes the project and lists dependencies that are required to build it.
A default file can be created by running [`shards init`](#shards-install).
The file's contents are explained in the [*Writing a Shard* guide](../../guides/writing_shards.md) and a detailed description of the file format is provided by the [shard.yml specification](https://github.com/crystal-lang/shards/blob/master/docs/shard.yml.adoc).

Running [`shards install`](#shards-install) resolves and installs the specified dependencies.
The installed versions are written into a `shard.lock` file for using the exact same dependency versions when running `shards install` again.

If your shard builds an application, both `shard.yml` and `shard.lock` should be checked into version control to provide reproducible dependency installs.
If it is only a library for other shards to depend on, `shard.lock` should *not* be checked in, only `shard.yml`. It's good advice to add it to `.gitignore` (the [`crystal init`](../crystal/README.md#crystal-init) does this automatically when initializing a `lib` repository).

## Shards commands

```bash
shards [<options>...] [<command>]
```

If no command is given, `install` will be run by default.

* [`shards build`](#shards-build): Builds an executable
* [`shards check`](#shards-check): Verifies dependencies are installed
* [`shards init`](#shards-init): Generates a new `shard.yml`
* [`shards install`](#shards-install): Resolves and installs dependencies
* [`shards list`](#shards-list): Lists installed dependencies
* [`shards prune`](#shards-prune): Removes unused dependencies
* [`shards update`](#shards-update): Resolves and updates dependencies
* [`shards version`](#shards-version): Shows version of a shard

To see the available options for a particular command, use `--help` after a command.

**Common options:**

* `--version`: Prints the version of `shards`.
* `-h, --help`: Prints usage synopsis.
* `--no-color`: Disabled colored output.
* `--production`: Runs in release mode. Development dependencies won't be installed and only locked dependencies will be installed. Commands will fail if dependencies in `shard.yml` and `shard.lock` are out of sync (used by `install`, `update`, `check` and `list` command)
* `-q, --quiet`: Decreases the log verbosity, printing only warnings and errors.
* `-v, --verbose`: Increases the log verbosity, printing all debug statements.

### `shards build`

```bash
shards build [<targets>] [<options>...]
```

Builds the specified targets in `bin` path. If no targets are specified, all are built.
This command ensures all dependencies are installed, so it is not necessary to run `shards install` before.

All options following the command are delegated to `crystal build`.

### `shards check`

```bash
shards check
```

Verifies that all dependencies are installed and requirements are satisfied.

Exit status:

* `0`: Dependencies are satisfied.
* `1`: Dependencies are not satisfied.

### `shards init`

```bash
shards init
```

Initializes a shard folder and creates a `shard.yml`.

### `shards install`

```bash
shards install
```

Resolves and installs dependencies into the `lib` folder. If not already present, generates a `shard.lock` file from resolved dependencies, locking version
numbers or Git commits.

Reads and enforces locked versions and commits if a `shard.lock` file is present. The install command may fail if a locked version doesn't match a requirement, but may succeed if a new dependency was added, as long as it doesn't generate a conflict, thus generating a new `shard.lock` file.

### `shards list`

```bash
shards list
```

Lists the installed dependencies and their versions.

### `shards prune`

```bash
shards prune
```

Removes unused dependencies from lib folder.

### `shards update`

```bash
shards update
```

Resolves and updates all dependencies into the lib folder again, whatever the locked versions and commits in the `shard.lock` file. Eventually generates a
new `shard.lock` file.

### `shards version`

```bash
shards version [<path>]
```

Prints the version of the shard.

## Fixing Dependency Version Conflicts

A `shard.override.yml` file allows overriding the source and restriction of dependencies. An alternative location can be configured with the env var `SHARDS_OVERRIDE`.

The file contains a YAML document with a single `dependencies` key. It has the same semantics as in `shard.yml`. Dependency configuration takes precedence over the configuration in `shard.yml` or any dependency’s `shard.yml`.

Use cases are local working copies, forcing a specific dependency version despite mismatching constraints, fixing a dependency, checking compatibility with unreleased dependency versions.

Example file contents

```yaml
dependencies:
  # Assuming we have a conflict with the version of the Redis shard
  # This will override any specified version and use the `master` branch instead
  redis:
    github: jgaskins/redis
    branch: master
```
# Release Policy

Crystal releases have a version indicated by a major, minor and patch number.

The current major branch number is `1`.

New features are added in minor releases (`1.x.0`) which are regularly scheduled every three months.

Patch releases contain only important bug fixes and are released when necessary.
They usually only appear for the latest minor branch.

New releases are announced at [crystal-lang.org/releases](https://crystal-lang.org/releases) ([RSS feed](https://crystal-lang.org/releases)).

There are currently no plans for a new major release.

## Backwards compatibility

Minor and patch releases are backwards compatible: Well-defined behaviours and documented APIs in a given version
will continue working on future versions within the same major branch.

As a result, migrating to a new minor release is usually seamless.

### Reservations

Although we expect the vast majority of programs to remain compatible over time,
it is impossible to guarantee that no future change will break any program.
Under some unlikely circumstances, we may introduce changes that break existing code.
Rest assured we are committed to keep the impact as minimal as possible.

* Security: a security issue in the implementation may arise whose resolution requires backwards incompatible changes. We reserve the right to address such security issues.

* Bugs: if an API has undesired behaviour, a program that depends on the buggy behaviour may break if the bug is fixed. We reserve the right to fix such bugs.

* Compiler front-end: improvements may be done to the compiler, introducing new warnings for ambiguous modes and providing more detailed error messages. Those can lead to compilation errors (when building with `--error-on-warnings`) or tooling failures when asserting on specific error messages (although one should avoid such). We reserve the right to do such improvements.

* Feature additions: When introducing new features into the language or core library, there can be collisions with the names of types, methods, etc. defined in user code. We reserve the right to add new names when necessary.

The changelog and release notes highlight any changes that have a considerable potential for breaking existing code, even if it uses experimental, undocumented or unsupported features.

### Experimental features

The only exception to the compatibility guarantees are experimental features, which are explicitly designated as such with the [`@[Experimental]`](https://crystal-lang.org/api/Experimental.html) annotation.
There is no compatibility guarantee until they are stabilized (at which point the annotation is dropped).
# About this guide

This is a formal specification of the Crystal language.

You can read this document from top to bottom, but it’s advisable to jump through sections because some concepts are interrelated and can’t be explained in isolation.

The [Language Introduction tutorial](../tutorials/basics/README.md) offers a more focused learning experience for beginners.

In code examples, a comment starting with `# =>` shows the value of an expression.

```crystal
1 + 2 # => 3
```

A comment starting with `# :` shows the type of an expression.

```crystal
"hello" # : String
```
# alias

With `alias` you can give a type a different name:

```crystal
alias PInt32 = Pointer(Int32)

ptr = PInt32.malloc(1) # : Pointer(Int32)
```

Every time you use an alias the compiler replaces it with the type it refers to.

Aliases are useful to avoid writing long type names, but also to be able to talk about recursive types:

```crystal
alias RecArray = Array(Int32) | Array(RecArray)

ary = [] of RecArray
ary.push [1, 2, 3]
ary.push ary
ary # => [[1, 2, 3], [...]]
```

A real-world example of a recursive type is json:

```crystal
module Json
  alias Type = Nil |
               Bool |
               Int64 |
               Float64 |
               String |
               Array(Type) |
               Hash(String, Type)
end
```
# alignof

The `alignof` expression returns an `Int32` with the ABI alignment in bytes of a given type. For example:

```crystal
alignof(Int32) # => 4
alignof(Int64) # => 8

struct Foo
  def initialize(@x : Int8, @y : Int16)
  end
end

@[Extern]
@[Packed]
struct Bar
  def initialize(@x : Int8, @y : Int16)
  end
end

alignof(Foo) # => 2
alignof(Bar) # => 1
```

For [Reference](https://crystal-lang.org/api/Reference.html) types, the alignment is the same as the alignment of a pointer:

```crystal
# On a 64-bit machine
alignof(Pointer(Int32)) # => 8
alignof(String)         # => 8
```

This is because `Reference`'s memory is allocated on the heap and a pointer to it is passed around. To get the effective alignment of a class, use [instance_alignof](instance_alignof.md).

The argument to alignof is a [type](type_grammar.md) and is often combined with [typeof](typeof.md):

```crystal
a = 1
alignof(typeof(a)) # => 4
```

`alignof` can be used in the macro language, but only on types with stable size and alignment. See the API docs of [`alignof`](https://crystal-lang.org/api/Crystal/Macros.html#alignof(type):NumberLiteral-instance-method) for details.
# && - Logical AND Operator

An `&&` (and) evaluates its left hand side. If it's *truthy*, it evaluates its right hand side and has that value. Otherwise it has the value of the left hand side. Its type is the union of the types of both sides.

You can think an `&&` as syntax sugar of an `if`:

```crystal
some_exp1 && some_exp2
```

The above is equivalent to:

```crystal
tmp = some_exp1
if tmp
  some_exp2
else
  tmp
end
```
# Annotations

Annotations can be used to add metadata to certain features in the source code. Types, methods, instance variables, and method/macro parameters may be annotated.  User-defined annotations, such as the standard library's [JSON::Field](https://crystal-lang.org/api/JSON/Field.html), are defined using the `annotation` keyword.  A number of [built-in annotations](built_in_annotations.md) are provided by the compiler.

Users can define their own annotations using the `annotation` keyword, which works similarly to defining a `class` or `struct`.

```crystal
annotation MyAnnotation
end
```

The annotation can then be applied to various items, including:

* Instance and class methods
* Instance variables
* Classes, structs, enums, and modules
* Method and macro parameters (though the latter are currently inaccessible)

```crystal
annotation MyAnnotation
end

@[MyAnnotation]
def foo
  "foo"
end

@[MyAnnotation]
class Klass
end

@[MyAnnotation]
module MyModule
end

def method1(@[MyAnnotation] foo)
end

def method2(
  @[MyAnnotation]
  bar,
)
end

def method3(@[MyAnnotation] & : String ->)
end
```

## Applications

Annotations are best used to store metadata about a given instance variable, type, or method so that it can be read at compile time using macros.  One of the main benefits of annotations is that they are applied directly to instance variables/methods, which causes classes to look more natural since a standard macro is not needed to create these properties/methods.

A few applications for annotations:

### Object Serialization

Have an annotation that when applied to an instance variable determines if that instance variable should be serialized, or with what key. Crystal's [`JSON::Serializable`](https://crystal-lang.org/api/JSON/Serializable.html) and [`YAML::Serializable`](https://crystal-lang.org/api/YAML/Serializable.html) are examples of this.

### ORMs

An annotation could be used to designate a property as an ORM column. The name and type of the instance variable can be read off the `TypeNode` in addition to the annotation; removing the need for any ORM specific macro. The annotation itself could also be used to store metadata about the column, such as if it is nullable, the name of the column, or if it is the primary key.

## Fields

Data can be stored within an annotation.

```crystal
annotation MyAnnotation
end

# The fields can either be a key/value pair
@[MyAnnotation(key: "value", value: 123)]

# Or positional
@[MyAnnotation("foo", 123, false)]
```

### Key/value

The values of annotation key/value pairs can be accessed at compile time via the [`[]`](https://crystal-lang.org/api/Crystal/Macros/Annotation.html#%5B%5D%28name%3ASymbolLiteral%7CStringLiteral%7CMacroId%29%3AASTNode-instance-method) method.

```crystal
annotation MyAnnotation
end

@[MyAnnotation(value: 2)]
def annotation_value
  # The name can be a `String`, `Symbol`, or `MacroId`
  {{ @def.annotation(MyAnnotation)[:value] }}
end

annotation_value # => 2
```

The `named_args` method can be used to read all key/value pairs on an annotation as a `NamedTupleLiteral`.  This method is defined on all annotations by default, and is unique to each applied annotation.

```crystal
annotation MyAnnotation
end

@[MyAnnotation(value: 2, name: "Jim")]
def annotation_named_args
  {{ @def.annotation(MyAnnotation).named_args }}
end

annotation_named_args # => {value: 2, name: "Jim"}
```

Since this method returns a `NamedTupleLiteral`, all of the [methods](https://crystal-lang.org/api/Crystal/Macros/NamedTupleLiteral.html) on that type are available for use.  Especially `#double_splat` which makes it easy to pass annotation arguments to methods.

```crystal
annotation MyAnnotation
end

class SomeClass
  def initialize(@value : Int32, @name : String); end
end

@[MyAnnotation(value: 2, name: "Jim")]
def new_test
  {% begin %}
    SomeClass.new {{ @def.annotation(MyAnnotation).named_args.double_splat }}
  {% end %}
end

new_test # => #<SomeClass:0x5621a19ddf00 @name="Jim", @value=2>
```

### Positional

Positional values can be accessed at compile time via the [`[]`](<https://crystal-lang.org/api/Crystal/Macros/Annotation.html#%5B%5D%28index%3ANumberLiteral%29%3AASTNode-instance-method>) method; however, only one index can be accessed at a time.

```crystal
annotation MyAnnotation
end

@[MyAnnotation(1, 2, 3, 4)]
def annotation_read
  {% for idx in [0, 1, 2, 3, 4] %}
    {% value = @def.annotation(MyAnnotation)[idx] %}
    pp "{{ idx }} = {{ value }}"
  {% end %}
end

annotation_read

# Which would print
"0 = 1"
"1 = 2"
"2 = 3"
"3 = 4"
"4 = nil"
```

The `args` method can be used to read all positional arguments on an annotation as a `TupleLiteral`.  This method is defined on all annotations by default, and is unique to each applied annotation.

```crystal
annotation MyAnnotation
end

@[MyAnnotation(1, 2, 3, 4)]
def annotation_args
  {{ @def.annotation(MyAnnotation).args }}
end

annotation_args # => {1, 2, 3, 4}
```

Since the return type of `TupleLiteral` is iterable, we can rewrite the previous example in a better way.  By extension, all of the [methods](https://crystal-lang.org/api/Crystal/Macros/TupleLiteral.html) on `TupleLiteral` are available for use as well.

```crystal
annotation MyAnnotation
end

@[MyAnnotation(1, "foo", true, 17.0)]
def annotation_read
  {% for value, idx in @def.annotation(MyAnnotation).args %}
    pp "{{ idx }} = #{{{ value }}}"
  {% end %}
end

annotation_read

# Which would print
"0 = 1"
"1 = foo"
"2 = true"
"3 = 17.0"
```

## Reading

Annotations can be read off of a [`TypeNode`](https://crystal-lang.org/api/Crystal/Macros/TypeNode.html), [`Def`](https://crystal-lang.org/api/Crystal/Macros/Def.html), [`MetaVar`](https://crystal-lang.org/api/Crystal/Macros/MetaVar.html), or [`Arg`](https://crystal-lang.org/api/Crystal/Macros/Arg.html) using the `.annotation(type : TypeNode)` method.  This method return an [`Annotation`](https://crystal-lang.org/api/Crystal/Macros/Annotation.html) object representing the applied annotation of the supplied type.

NOTE: If multiple annotations of the same type are applied, the `.annotation` method will return the *last* one.

The [`@type`](../macros/README.md#type-information) and [`@def`](../macros/README.md#method-information) variables can be used to get a `TypeNode` or `Def` object to use the `.annotation` method on.  However, it is also possible to get `TypeNode`/`Def` types using other methods on `TypeNode`.  For example `TypeNode.all_subclasses` or `TypeNode.methods`, respectively.

TIP: Checkout the [`parse_type`](../macros/README.md#parse_type) method for a more advanced way to obtain a `TypeNode`.

The `TypeNode.instance_vars` can be used to get an array of instance variable `MetaVar` objects that would allow reading annotations defined on those instance variables.

NOTE: `TypeNode.instance_vars` currently only works in the context of an instance/class method.

```crystal
annotation MyClass
end

annotation MyMethod
end

annotation MyIvar
end

annotation MyParameter
end

@[MyClass]
class Foo
  pp {{ @type.annotation(MyClass).stringify }}

  @[MyIvar]
  @num : Int32 = 1

  @[MyIvar]
  property name : String = "jim"

  def properties
    {% for ivar in @type.instance_vars %}
      pp {{ ivar.annotation(MyIvar).stringify }}
    {% end %}
  end
end

@[MyMethod]
def my_method
  pp {{ @def.annotation(MyMethod).stringify }}
end

def method_params(
  @[MyParameter(index: 0)]
  value : Int32,
  @[MyParameter(index: 1)] metadata,
  @[MyParameter(index: 2)] & : -> String
)
  pp {{ @def.args[0].annotation(MyParameter).stringify }}
  pp {{ @def.args[1].annotation(MyParameter).stringify }}
  pp {{ @def.block_arg.annotation(MyParameter).stringify }}
end

Foo.new.properties
my_method
method_params 10, false do
  "foo"
end
pp {{ Foo.annotation(MyClass).stringify }}

# Which would print
"@[MyClass]"
"@[MyIvar]"
"@[MyIvar]"
"@[MyMethod]"
"@[MyParameter(index: 0)]"
"@[MyParameter(index: 1)]"
"@[MyParameter(index: 2)]"
"@[MyClass]"
```

WARNING: Annotations can only be read off of typed block parameters. See https://github.com/crystal-lang/crystal/issues/5334.

### Reading Multiple Annotations

The `#annotations` method returns an `ArrayLiteral` of *all* annotations on a type. Optionally, a `TypeNode` argument with the `#annotations(type : TypeNode)` method filters only annotations of the provided *type*.

```crystal
annotation MyAnnotation; end
annotation OtherAnnotation; end

@[MyAnnotation("foo")]
@[MyAnnotation(123)]
@[OtherAnnotation(456)]
def annotation_read
  {% for ann in @def.annotations(MyAnnotation) %}
    pp "{{ann.name}}: {{ ann[0].id }}"
  {% end %}

  puts

  {% for ann in @def.annotations %}
    pp "{{ann.name}}: {{ ann[0].id }}"
  {% end %}
end

annotation_read

# Which would print:
"MyAnnotation: foo"
"MyAnnotation: 123"

"MyAnnotation: foo"
"MyAnnotation: 123"
"OtherAnnotation: 456"
```
# Built-in annotations

The language comes with some pre-defined annotations listed here.
The compiler uses them for code generation and other purposes such as deprecation warnings.

The Crystal standard library defines more annotations.

## Link

Tells the compiler how to link a C library. This is explained in the
[lib](../c_bindings/lib.md) section.

!!! info
    See the [API docs for `Link`](https://crystal-lang.org/api/Link.html) for more details.

## Extern

Marking a Crystal struct with this annotation makes it possible to use it in lib declarations:

```crystal
@[Extern]
struct MyStruct
end

lib MyLib
  fun my_func(s : MyStruct) # OK (gives an error without the Extern annotation)
end
```

You can also make a struct behave like a C union (this can be pretty unsafe):

```crystal
# A struct to easily convert between Int32 codepoints and Chars
@[Extern(union: true)]
struct Int32OrChar
  property int = 0
  property char = '\0'
end

s = Int32OrChar.new
s.char = 'A'
s.int # => 65

s.int = 66
s.char # => 'B'
```

## ThreadLocal

The `@[ThreadLocal]` annotation can be applied to class variables and C external variables. It makes them be thread local.

```crystal
class DontUseThis
  # One for each thread
  @[ThreadLocal]
  @@values = [] of Int32
end
```

ThreadLocal is used in the standard library to implement the runtime and shouldn't be
needed or used outside it.

## Packed

Marks a [C struct](../c_bindings/struct.md) as packed, which prevents the automatic insertion of padding bytes between fields. This is typically only needed if the C library explicitly uses packed structs.

## AlwaysInline

Gives a hint to the compiler to always inline a method:

```crystal
@[AlwaysInline]
def foo
  1
end
```

## NoInline

Tells the compiler to never inline a method call. This has no effect if the method yields, since functions which yield are always inlined.

```crystal
@[NoInline]
def foo
  1
end
```

## ReturnsTwice

Marks a method or [lib fun](../c_bindings/fun.md) as returning twice. The C `setjmp` is an example of such a function.

## Raises

Marks a method or [lib fun](../c_bindings/fun.md) as potentially raising an exception. This is explained in the [callbacks](../c_bindings/callbacks.md) section.

## CallConvention

Indicates the call convention of a [lib fun](../c_bindings/fun.md). For example:

```crystal
lib LibFoo
  @[CallConvention("X86_StdCall")]
  fun foo : Int32
end
```

The list of valid call conventions is:

* C (the default)
* Fast
* Cold
* WebKit_JS
* AnyReg
* X86_StdCall
* X86_FastCall

!!! info
    See [LLVM
    documentation](http://llvm.org/docs/LangRef.html#calling-conventions) for more details.

## Flags

Marks an [enum](../enum.md) as a "flags enum", which changes the behaviour of some of its methods, like `to_s`.

!!! info
    See the [API docs for `Flags`](https://crystal-lang.org/api/Flags.html) for more details.

## Deprecated

Marks a feature (e.g. a method, type or parameter) as deprecated.

Deprecations are shown in the API docs and the compiler prints a warning when
using a deprecated feature.

!!! info
    See the [API docs for `Deprecated`](https://crystal-lang.org/api/Deprecated.html) for more details.
# as

The `as` pseudo-method restricts the types of an expression. For example:

```crystal
if some_condition
  a = 1
else
  a = "hello"
end

# a : Int32 | String
```

In the above code, `a` is a union of `Int32 | String`. If for some reason we are sure `a` is an `Int32` after the `if`, we can force the compiler to treat it like one:

```crystal
a_as_int = a.as(Int32)
a_as_int.abs # works, compiler knows that a_as_int is Int32
```

The `as` pseudo-method performs a runtime check: if `a` wasn't an `Int32`, an [exception](exception_handling.md) is raised.

The argument to the expression is a [type](type_grammar.md).

If it is impossible for a type to be restricted by another type, a compile-time error is issued:

```crystal
1.as(String) # Compile-time error
```

NOTE:
You can't use `as` to convert a type to an unrelated type: `as` is not like a `cast` in other languages. Methods on integers, floats and chars are provided for these conversions. Alternatively, use pointer casts as explained below.

## Converting between pointer types

The `as` pseudo-method also allows to cast between pointer types:

```crystal
ptr = Pointer(Int32).malloc(1)
ptr.as(Int8*) # :: Pointer(Int8)
```

In this case, no runtime checks are done: pointers are unsafe and this type of casting is usually only needed in C bindings and low-level code.

## Converting between pointer types and other types

Conversion between pointer types and Reference types is also possible:

```crystal
array = [1, 2, 3]

# object_id returns the address of an object in memory,
# so we create a pointer with that address
ptr = Pointer(Void).new(array.object_id)

# Now we cast that pointer to the same type, and
# we should get the same value
array2 = ptr.as(Array(Int32))
array2.same?(array) # => true
```

No runtime checks are performed in these cases because, again, pointers are involved. The need for this cast is even more rare than the previous one, but allows to implement some core types (like String) in Crystal itself, and it also allows passing a Reference type to C functions by casting it to a void pointer.

## Usage for casting to a bigger type

The `as` pseudo-method can be used to cast an expression to a "bigger" type. For example:

```crystal
a = 1
b = a.as(Int32 | Float64)
b # :: Int32 | Float64
```

The above might not seem to be useful, but it is when, for example, mapping an array of elements:

```crystal
ary = [1, 2, 3]

# We want to create an array 1, 2, 3 of Int32 | Float64
ary2 = ary.map { |x| x.as(Int32 | Float64) }

ary2        # :: Array(Int32 | Float64)
ary2 << 1.5 # OK
```

The `Array#map` method uses the block's type as the generic type for the Array. Without the `as` pseudo-method, the inferred type would have been `Int32` and we wouldn't have been able to add a `Float64` into it.

## Usage for when the compiler can't infer the type of a block

Sometimes the compiler can't infer the type of a block. This can happen in recursive calls that depend on each other. In those cases you can use `as` to let it know the type:

```crystal
some_call { |v| v.method.as(ExpectedType) }
```
# As a suffix

An `if` can be written as an expression’s suffix:

```crystal
a = 2 if some_condition

# The above is the same as:
if some_condition
  a = 2
end
```

This sometimes leads to code that is more natural to read.
# As an expression

The value of an `if` is the value of the last expression found in each of its branches:

```crystal
a = if 2 > 1
      3
    else
      4
    end
a # => 3
```

If an `if` branch is empty, or it’s missing, it’s considered as if it had `nil` in it:

```crystal
if 1 > 2
  3
end

# The above is the same as:
if 1 > 2
  3
else
  nil
end

# Another example:
if 1 > 2
else
  3
end

# The above is the same as:
if 1 > 2
  nil
else
  3
end
```
# as?

The `as?` pseudo-method is similar to `as`, except that it returns `nil` instead of raising an exception when the type doesn't match. It also can't be used to cast between pointer types and other types.

Example:

```crystal
value = rand < 0.5 ? -3 : nil
result = value.as?(Int32) || 10

value.as?(Int32).try &.abs
```
# asm

The `asm` keyword can be used to insert inline assembly, which is needed for a very small set of features such as fiber switching and system calls:

```crystal
# x86-64 targets only
dst = 0
asm("mov $$1234, $0" : "=r"(dst))
dst # => 1234
```

An `asm` expression consists of up to 5 colon-separated sections, and components inside each section are separated by commas. For example:

```crystal
asm(
  # the assembly template string, following the
  # syntax for LLVM's integrated assembler
  "nop" :
  # output operands
  "=r"(foo), "=r"(bar) :
  # input operands
  "r"(1), "r"(baz) :
  # names of clobbered registers
  "eax", "memory" :
  # optional flags, corresponding to the LLVM IR
  # sideeffect / alignstack / inteldialect / unwind attributes
  "volatile", "alignstack", "intel", "unwind"
)
```

Only the template string is mandatory, all other sections can be empty or omitted:

```crystal
asm("nop")
asm("nop" :: "b"(1), "c"(2)) # output operands are empty
```

For more details, refer to the [LLVM documentation's section on inline assembler expressions](https://llvm.org/docs/LangRef.html#inline-assembler-expressions).
# Assignment

An assignment expression assigns a value to a named identifier (usually a variable).
The [assignment operator](operators.md#assignments) is the equals sign (`=`).

The target of an assignment can be:

* a [local variable](local_variables.md)
* an [instance variable](methods_and_instance_variables.md)
* a [class variable](class_variables.md)
* a [constant](constants.md)
* an assignment method

```crystal
# Assigns to a local variable
local = 1

# Assigns to an instance variable
@instance = 2

# Assigns to a class variable
@@class = 3

# Assigns to a constant
CONST = 4

# Assigns to a setter method
foo.method = 5
foo[0] = 6
```

## Method as assignment target

A method ending with an equals sign (`=`) is called a setter method. It can be used
as the target of an assignment. The semantics of the assignment operator apply as
a form of syntax sugar to the method call.

Calling setter methods requires an explicit receiver. The receiver-less syntax `x = y`
is always parsed as an assignment to a local variable, never a call to a method `x=`.
Even adding parentheses does not force a method call, as it would when reading from a local variable.

The following example shows two calls to a setter method in typical method notation and with assignment operator.
Both assignment expressions are equivalent.

```crystal
class Thing
  def name=(value); end
end

thing = Thing.new

thing.name=("John")
thing.name = "John"
```

The following example shows two calls to an indexed assignment method in typical method notation and with index assignment operator.
Both assignment expressions are equivalent.

```crystal
class List
  def []=(key, value); end
end

list = List.new

list.[]=(2, 3)
list[2] = 3
```

## Combined assignments

[Combined assignments](operators.md#combined-assignments) are a combination of an
assignment operator and another operator.
This works with any target type except constants.

Some syntax sugar that contains the `=` character is available:

```{.crystal nocheck}
local += 1  # same as: local = local + 1
```

This assumes that the corresponding target `local` is assignable, either as a variable or via the respective getter and setter methods.

The `=` operator syntax sugar is also available to setter and index assignment methods.
Note that `||` and `&&` use the `[]?` method to check for key presence.

```crystal
person.age += 1 # same as: person.age = person.age + 1

person.name ||= "John" # same as: person.name || (person.name = "John")
person.name &&= "John" # same as: person.name && (person.name = "John")

objects[1] += 2 # same as: objects[1] = objects[1] + 2

objects[1] ||= 2 # same as: objects[1]? || (objects[1] = 2)
objects[1] &&= 2 # same as: objects[1]? && (objects[1] = 2)
```

## Chained assignment

The same value can be assigned to multiple targets using chained assignment.
This works with any target type except constants.

```crystal
a = b = c = 123

# Now a, b and c have the same value:
a # => 123
b # => 123
c # => 123
```

## Multiple assignment

You can declare/assign multiple variables at the same time by separating expressions with a comma (`,`).
This works with any target type except constants.

```crystal
name, age = "Crystal", 1

# The above is the same as this:
temp1 = "Crystal"
temp2 = 1
name = temp1
age = temp2
```

Note that because expressions are assigned to temporary variables it is possible to exchange variables’ contents in a single line:

```crystal
a = 1
b = 2
a, b = b, a
a # => 2
b # => 1
```

Multiple assignment is also available to methods that end with `=`:

```crystal
person.name, person.age = "John", 32

# Same as:
temp1 = "John"
temp2 = 32
person.name = temp1
person.age = temp2
```

And it is also available to [index assignments](operators.md#assignments) (`[]=`):

```crystal
objects[1], objects[2] = 3, 4

# Same as:
temp1 = 3
temp2 = 4
objects[1] = temp1
objects[2] = temp2
```

### One-to-many assignment

If the right-hand side contains just one expression, the type is indexed for each variable on the left-hand side like so:

```crystal
name, age, source = "Crystal, 123, GitHub".split(", ")

# The above is the same as this:
temp = "Crystal, 123, GitHub".split(", ")
name = temp[0]
age = temp[1]
source = temp[2]
```

Additionally, if the [`strict_multi_assign` flag](compile_time_flags.md) is provided, the number of elements must match the number of targets, and the right-hand side must be an [`Indexable`](https://crystal-lang.org/api/Indexable.html):

```crystal
name, age, source = "Crystal, 123, GitHub".split(", ")

# The above is the same as this:
temp = "Crystal, 123, GitHub".split(", ")
if temp.size != 3 # number of targets
  raise IndexError.new("Multiple assignment count mismatch")
end
name = temp[0]
age = temp[1]
source = temp[2]

a, b = {0 => "x", 1 => "y"} # Error: right-hand side of one-to-many assignment must be an Indexable, not Hash(Int32, String)
```

### Splat assignment

The left-hand side of an assignment may contain one splat, which collects any values not assigned to the other targets. A [range](literals/range.md) index is used if the right-hand side has one expression:

```crystal
head, *rest = [1, 2, 3, 4, 5]

# Same as:
temp = [1, 2, 3, 4, 5]
head = temp[0]
rest = temp[1..]
```

Negative indices are used for targets after the splat:

```crystal
*rest, tail1, tail2 = [1, 2, 3, 4, 5]

# Same as:
temp = [1, 2, 3, 4, 5]
rest = temp[..-3]
tail1 = temp[-2]
tail2 = temp[-1]
```

If the expression does not have enough elements and the splat appears in the middle of the targets, [`IndexError`](https://crystal-lang.org/api/IndexError.html) is raised:

```crystal
a, b, *c, d, e, f = [1, 2, 3, 4]

# Same as:
temp = [1, 2, 3, 4]
if temp.size < 5 # number of non-splat assignment targets
  raise IndexError.new("Multiple assignment count mismatch")
end
# note that the following assignments would incorrectly not raise if the above check is absent
a = temp[0]
b = temp[1]
c = temp[2..-4]
d = temp[-3]
e = temp[-2]
f = temp[-1]
```

The right-hand side expression must be an [`Indexable`](https://crystal-lang.org/api/Indexable.html). Both the size check and the `Indexable` check occur even without the `strict_multi_assign` flag (see [One-to-many assignment](#one-to-many-assignment) above).

A [`Tuple`](https://crystal-lang.org/api/Tuple.html) is formed if there are multiple values:

```crystal
*a, b, c = 3, 4, 5, 6, 7

# Same as:
temp1 = {3, 4, 5}
temp2 = 6
temp3 = 7
a = temp1
b = temp2
c = temp3
```

## Underscore

The underscore can appear on the left-hand side of any assignment. Assigning a value to it has no effect and the underscore cannot be read from:

```crystal
_ = 1     # no effect
_ = "123" # no effect
puts _    # Error: can't read from _
```

It is useful in multiple assignment when some of the values returned by the right-hand side are unimportant:

```crystal
before, _, after = "main.cr".partition(".")

# The above is the same as this:
temp = "main.cr".partition(".")
before = temp[0]
_ = temp[1] # this line has no effect
after = temp[2]
```

Assignments to `*_` are dropped altogether, so multiple assignments can be used to extract the first and last elements in a value efficiently, without creating an intermediate object for the elements in the middle:

```crystal
first, *_, last = "127.0.0.1".split(".")

# Same as:
temp = "127.0.0.1".split(".")
if temp.size < 2
  raise IndexError.new("Multiple assignment count mismatch")
end
first = temp[0]
last = temp[-1]
```
# Type autocasting

Crystal transparently casts elements of certain types when there is no ambiguity.

## Number autocasting

Values of a numeric type autocast to a larger one if no precision is lost:

```crystal
def foo(x : Int32) : Int32
  x
end

def bar(x : Float32) : Float32
  x
end

def bar64(x : Float64) : Float64
  x
end

foo 0xFFFF_u16 # OK, an UInt16 always fit an Int32
foo 0xFFFF_u64 # OK, this particular UInt64 fit in an Int32
bar(foo 1)     # Fails, casting an Int32 to a Float32 might lose precision
bar64(bar 1)   # OK, a Float32 can be autocasted to a Float64
```

Number literals are always casted when the actual value of the literal fits the target type, despite of its type.

Expressions are casted (like in the last example above), unless the flag `no_number_autocast` is passed to the compiler (see [Compiler features](compile_time_flags.md#language-features)).

If there is ambiguity, for instance, because there is more than one option, the compiler throws an error:

```crystal
def foo(x : Int64)
  x
end

def foo(x : Int128)
  x
end

foo 1_i32 # Error: ambiguous call, implicit cast of Int32 matches all of Int64, Int128
```

Autocasting at the moment works only in two scenarios: at function calls, as shown so far, and at class/instance variable initialization. The following example shows an example of two situations for an instance variable: casting at initialization works, but casting at an assignment doesn't:

```crystal
class Foo
  @x : Int64 = 10 # OK, 10 fits in an Int64

  def set_x(y)
    @x = y
  end
end

Foo.new.set_x 1 # Error: "at line 5: instance variable '@x' of Foo must be Int64, not Int32"
```

## Symbol autocasting

Symbols are autocasted as enum members, therefore enabling to write them more succinctly:

```crystal
enum TwoValues
  A
  B
end

def foo(v : TwoValues)
  case v
  in TwoValues::A
    p "A"
  in TwoValues::B
    p "B"
  end
end

foo :a # autocasted to TwoValues::A
```
# Block forwarding

To forward captured blocks, you use a block argument, prefixing an expression with `&`:

```crystal
def capture(&block)
  block
end

def invoke(&block)
  block.call
end

proc = capture { puts "Hello" }
invoke(&proc) # prints "Hello"
```

In the above example, `invoke` receives a block. We can't pass `proc` directly to it because `invoke` doesn't receive regular arguments, just a block argument. We use `&` to specify that we really want to pass `proc` as the block argument. Otherwise:

```crystal
invoke(proc) # Error: wrong number of arguments for 'invoke' (1 for 0)
```

You can actually pass a proc to a method that yields:

```crystal
def capture(&block)
  block
end

def twice(&)
  yield
  yield
end

proc = capture { puts "Hello" }
twice &proc
```

The above is simply rewritten to:

```crystal
proc = capture { puts "Hello" }
twice do
  proc.call
end
```

Or, combining the `&` and `->` syntaxes:

```crystal
twice &-> { puts "Hello" }
```

Or:

```crystal
def say_hello
  puts "Hello"
end

twice &->say_hello
```

## Forwarding non-captured blocks

To forward non-captured blocks, you must use `yield`:

```crystal
def foo(&)
  yield 1
end

def wrap_foo(&)
  puts "Before foo"
  foo do |x|
    yield x
  end
  puts "After foo"
end

wrap_foo do |i|
  puts i
end

# Output:
# Before foo
# 1
# After foo
```

You can also use the `&block` syntax to forward blocks, but then you have to at least specify the input types, and the generated code will involve closures and will be slower:

```crystal
def foo(&)
  yield 1
end

def wrap_foo(&block : Int32 -> _)
  puts "Before foo"
  foo(&block)
  puts "After foo"
end

wrap_foo do |i|
  puts i
end

# Output:
# Before foo
# 1
# After foo
```

Try to avoid forwarding blocks like this if doing `yield` is enough. There's also the issue that `break` and `next` are not allowed inside captured blocks, so the following won't work when using `&block` forwarding:

```crystal
foo_forward do |i|
  break # error
end
```

In short, avoid `&block` forwarding when `yield` is involved.
# Blocks and Procs

Methods can accept a block of code that is executed
with the `yield` keyword. For example:

```crystal
def twice(&)
  yield
  yield
end

twice do
  puts "Hello!"
end
```

The above program prints "Hello!" twice, once for each `yield`.

To define a method that receives a block, simply use `yield` inside it and the compiler will know. You can make this more evident by declaring a dummy block parameter, indicated as a last parameter prefixed with ampersand (`&`). In the example above we did this, making the argument anonymous (writing just the `&`). But it can be given a name:

```crystal
def twice(&block)
  yield
  yield
end
```

The block parameter name is irrelevant in this example, but will be relevant in more advanced uses.

To invoke a method and pass a block, you use `do ... end` or `{ ... }`. All of these are equivalent:

```crystal
twice() do
  puts "Hello!"
end

twice do
  puts "Hello!"
end

twice { puts "Hello!" }
```

The difference between using `do ... end` and `{ ... }` is that `do ... end` binds to the left-most call, while `{ ... }` binds to the right-most call:

```crystal
foo bar do
  something
end

# The above is the same as
foo(bar) do
  something
end

foo bar { something }

# The above is the same as

foo(bar { something })
```

The reason for this is to allow creating Domain Specific Languages (DSLs) using `do ... end` to have them be read as plain English:

```crystal
open file "foo.cr" do
  something
end

# Same as:
open(file("foo.cr")) do
  something
end
```

You wouldn't want the above to be:

```crystal
open(file("foo.cr") do
  something
end)
```

## Overloads

Two methods, one that yields and another that doesn't, are considered different overloads, as explained in the [overloading](overloading.md) section.

## Yield arguments

The `yield` expression is similar to a call and can receive arguments. For example:

```crystal
def twice(&)
  yield 1
  yield 2
end

twice do |i|
  puts "Got #{i}"
end
```

The above prints "Got 1" and "Got 2".

A curly braces notation is also available:

```crystal
twice { |i| puts "Got #{i}" }
```

You can `yield` many values:

```crystal
def many(&)
  yield 1, 2, 3
end

many do |x, y, z|
  puts x + y + z
end

# Output: 6
```

A block can specify fewer parameters than the arguments yielded:

```crystal
def many(&)
  yield 1, 2, 3
end

many do |x, y|
  puts x + y
end

# Output: 3
```

It's an error specifying more block parameters than the arguments yielded:

```crystal
def twice(&)
  yield
  yield
end

twice do |i| # Error: too many block parameters
end
```

Each block parameter has the type of every yield expression in that position. For example:

```crystal
def some(&)
  yield 1, 'a'
  yield true, "hello"
  yield 2, nil
end

some do |first, second|
  # first is Int32 | Bool
  # second is Char | String | Nil
end
```

The [underscore](assignment.md#underscore) is also allowed as a block parameter:

```crystal
def pairs(&)
  yield 1, 2
  yield 2, 4
  yield 3, 6
end

pairs do |_, second|
  print second
end

# Output: 246
```

## Short one-parameter syntax

If a block has a single parameter and invokes a method on it, the block can be replaced with the short syntax argument.

This:

```crystal
method do |param|
  param.some_method
end
```

and

```crystal
method { |param| param.some_method }
```

can both be written as:

```crystal
method &.some_method
```

Or like:

```crystal
method(&.some_method)
```

In either case, `&.some_method` is an argument passed to `method`.  This argument is syntactically equivalent to the block variants.  It is only syntactic sugar and does not have any performance penalty.

If the method has other required arguments, the short syntax argument should also be supplied in the method's argument list.

```crystal
["a", "b"].join(",", &.upcase)
```

Is equivalent to:

```crystal
["a", "b"].join(",") { |s| s.upcase }
```

Arguments can be used with the short syntax argument as well:

```crystal
["i", "o"].join(",", &.upcase(Unicode::CaseOptions::Turkic))
```

Operators can be invoked too:

```crystal
method &.+(2)
method(&.[index])
```

## yield value

The `yield` expression itself has a value: the last expression of the block. For example:

```crystal
def twice(&)
  v1 = yield 1
  puts v1

  v2 = yield 2
  puts v2
end

twice do |i|
  i + 1
end
```

The above prints "2" and "3".

A `yield` expression's value is mostly useful for transforming and filtering values. The best examples of this are [Enumerable#map](https://crystal-lang.org/api/Enumerable.html#map%28%26block%3AT-%3EU%29forallU-instance-method) and [Enumerable#select](https://crystal-lang.org/api/Enumerable.html#select%28%26block%3AT-%3E%29-instance-method):

```crystal
ary = [1, 2, 3]
ary.map { |x| x + 1 }         # => [2, 3, 4]
ary.select { |x| x % 2 == 1 } # => [1, 3]
```

A dummy transformation method:

```crystal
def transform(value, &)
  yield value
end

transform(1) { |x| x + 1 } # => 2
```

The result of the last expression is `2` because the last expression of the `transform` method is `yield`, whose value is the last expression of the block.

## Type restrictions

The type of the block in a method that uses `yield` can be restricted using the `&block` syntax. For example:

```crystal
def transform_int(start : Int32, &block : Int32 -> Int32)
  result = yield start
  result * 2
end

transform_int(3) { |x| x + 2 } # => 10
transform_int(3) { |x| "foo" } # Error: expected block to return Int32, not String
```

## break

A `break` expression inside a block exits early from the method:

```crystal
def thrice(&)
  puts "Before 1"
  yield 1
  puts "Before 2"
  yield 2
  puts "Before 3"
  yield 3
  puts "After 3"
end

thrice do |i|
  if i == 2
    break
  end
end
```

The above prints "Before 1" and "Before 2". The `thrice` method didn't execute the `puts "Before 3"` expression because of the `break`.

`break` can also accept arguments: these become the method's return value. For example:

```crystal
def twice(&)
  yield 1
  yield 2
end

twice { |i| i + 1 }         # => 3
twice { |i| break "hello" } # => "hello"
```

The first call's value is 3 because the last expression of the `twice` method is `yield`, which gets the value of the block. The second call's value is "hello" because a `break` was performed.

If there are conditional breaks, the call's return value type will be a union of the type of the block's value and the type of the many `break`s:

```crystal
value = twice do |i|
  if i == 1
    break "hello"
  end
  i + 1
end
value # :: Int32 | String
```

If a `break` receives many arguments, they are automatically transformed to a [Tuple](https://crystal-lang.org/api/Tuple.html):

```crystal
values = twice { break 1, 2 }
values # => {1, 2}
```

If a `break` receives no arguments, it's the same as receiving a single `nil` argument:

```crystal
value = twice { break }
value # => nil
```

If a `break` is used within more than one nested block, only the immediate enclosing block is broken out of:

```crystal
def foo(&)
  pp "before yield"
  yield
  pp "after yield"
end

foo do
  pp "start foo1"
  foo do
    pp "start foo2"
    break
    pp "end foo2"
  end
  pp "end foo1"
end

# Output:
# "before yield"
# "start foo1"
# "before yield"
# "start foo2"
# "end foo1"
# "after yield"
```

Notice you do not get two `"after yield"` nor an `"end foo2"`.

## next

The `next` expression inside a block exits early from the block (not the method). For example:

```crystal
def twice(&)
  yield 1
  yield 2
end

twice do |i|
  if i == 1
    puts "Skipping 1"
    next
  end

  puts "Got #{i}"
end

# Output:
# Skipping 1
# Got 2
```

The `next` expression accepts arguments, and these give the value of the `yield` expression that invoked the block:

```crystal
def twice(&)
  v1 = yield 1
  puts v1

  v2 = yield 2
  puts v2
end

twice do |i|
  if i == 1
    next 10
  end

  i + 1
end

# Output
# 10
# 3
```

If a `next` receives many arguments, they are automatically transformed to a [Tuple](https://crystal-lang.org/api/Tuple.html). If it receives no arguments it's the same as receiving a single `nil` argument.

## with ... yield

A `yield` expression can be modified, using the `with` keyword, to specify an object to use as the default receiver of method calls within the block:

```crystal
class Foo
  def one
    1
  end

  def yield_with_self(&)
    with self yield
  end

  def yield_normally(&)
    yield
  end
end

def one
  "one"
end

Foo.new.yield_with_self { one } # => 1
Foo.new.yield_normally { one }  # => "one"
```

## Unpacking block parameters

A block parameter can specify sub-parameters enclosed in parentheses:

```crystal
array = [{1, "one"}, {2, "two"}]
array.each do |(number, word)|
  puts "#{number}: #{word}"
end
```

The above is simply syntax sugar of this:

```crystal
array = [{1, "one"}, {2, "two"}]
array.each do |arg|
  number = arg[0]
  word = arg[1]
  puts "#{number}: #{word}"
end
```

That means that any type that responds to `[]` with integers can be unpacked in a block parameter.

Parameter unpacking can be nested.

```crystal
ary = [
  {1, {2, {3, 4}}},
]

ary.each do |(w, (x, (y, z)))|
  w # => 1
  x # => 2
  y # => 3
  z # => 4
end
```

Splat parameters are supported.

```crystal
ary = [
  [1, 2, 3, 4, 5],
]

ary.each do |(x, *y, z)|
  x # => 1
  y # => [2, 3, 4]
  z # => 5
end
```

For [Tuple](https://crystal-lang.org/api/Tuple.html) parameters you can take advantage of auto-splatting and do not need parentheses:

```crystal
array = [{1, "one", true}, {2, "two", false}]
array.each do |number, word, bool|
  puts "#{number}: #{word} #{bool}"
end
```

[Hash(K, V)#each](https://crystal-lang.org/api/Hash.html#each(&):Nil-instance-method) passes `Tuple(K, V)` to the block so iterating key-value pairs works with auto-splatting:

```crystal
h = {"foo" => "bar"}
h.each do |key, value|
  key   # => "foo"
  value # => "bar"
end
```

## Performance

When using blocks with `yield`, the blocks are **always** inlined: no closures, calls or function pointers are involved. This means that this:

```crystal
def twice(&)
  yield 1
  yield 2
end

twice do |i|
  puts "Got: #{i}"
end
```

is exactly the same as writing this:

```crystal
i = 1
puts "Got: #{i}"
i = 2
puts "Got: #{i}"
```

For example, the standard library includes a `times` method on integers, allowing you to write:

```crystal
3.times do |i|
  puts i
end
```

This looks very fancy, but is it as fast as a C for loop? The answer is: yes!

This is `Int#times` definition:

```crystal
struct Int
  def times(&)
    i = 0
    while i < self
      yield i
      i += 1
    end
  end
end
```

Because a non-captured block is always inlined, the above method invocation is **exactly the same** as writing this:

```crystal
i = 0
while i < 3
  puts i
  i += 1
end
```

Have no fear using blocks for readability or code reuse, it won't affect the resulting executable performance.
# break

You can use `break` to break out of a `while` loop:

```crystal
a = 2
while (a += 1) < 20
  if a == 10
    break # goes to 'puts a'
  end
end
puts a # => 10
```

`break` can also take an argument which will then be the value that gets returned:

```crystal
def foo
  loop do
    break "bar"
  end
end

puts foo # => "bar"
```

If a `break` is used within more than one nested `while` loop, only the immediate enclosing loop is broken out of:

```crystal
while true
  pp "start1"
  while true
    pp "start2"
    break
    pp "end2"
  end
  pp "end1"
  break
end

# Output:
# "start1"
# "start2"
# "end1"
```
# C bindings

Crystal allows you to bind to existing C libraries without writing a single line in C.

Additionally, it provides some conveniences like `out` and `to_unsafe` so writing bindings is as painless as possible.
# alias

An `alias` declaration inside a `lib` declares a C `typedef`:

```crystal
lib X
  alias MyInt = Int32
end
```

Now `Int32` and `MyInt` are interchangeable:

```crystal
lib X
  alias MyInt = Int32

  fun some_fun(value : MyInt)
end

X.some_fun 1 # OK
```

An `alias` is most useful to avoid writing long types over and over, but also to declare a type based on compile-time flags:

```crystal
lib C
  {% if flag?(:x86_64) %}
    alias SizeT = Int64
  {% else %}
    alias SizeT = Int32
  {% end %}

  fun memcmp(p1 : Void*, p2 : Void*, size : C::SizeT) : Int32
end
```

Refer to the [type grammar](../type_grammar.md) for the notation used in alias types.
# Callbacks

You can use function types in C declarations:

```crystal
lib X
  # In C:
  #
  #    void callback(int (*f)(int));
  fun callback(f : Int32 -> Int32)
end
```

Then you can pass a function (a [Proc](https://crystal-lang.org/api/Proc.html)) like this:

```crystal
f = ->(x : Int32) { x + 1 }
X.callback(f)
```

If you define the function inline in the same call you can omit the parameter types, the compiler will add the types for you based on the `fun` signature:

```crystal
X.callback ->(x) { x + 1 }
```

Note, however, that functions passed to C can't form closures. If the compiler detects at compile-time that a closure is being passed, an error will be issued:

```crystal
y = 2
X.callback ->(x) { x + y } # Error: can't send closure to C function
```

If the compiler can't detect this at compile-time, an exception will be raised at runtime.

Refer to the [type grammar](../type_grammar.md) for the notation used in callbacks and procs types.

If you want to pass `NULL` instead of a callback, just pass `nil`:

```crystal
# Same as callback(NULL) in C
X.callback nil
```

## Passing a closure to a C function

Most of the time a C function that allows setting a callback also provides a parameter for custom data. This custom data is then sent as an argument to the callback. For example, suppose a C function that invokes a callback at every tick, passing that tick:

```crystal
lib LibTicker
  fun on_tick(callback : (Int32, Void* ->), data : Void*)
end
```

To properly define a wrapper for this function we must send the Proc as the callback data, and then convert that callback data to the Proc and finally invoke it.

```crystal
module Ticker
  # The callback for the user doesn't have a Void*
  @@box : Pointer(Void)?

  def self.on_tick(&callback : Int32 ->)
    # Since Proc is a {Void*, Void*}, we can't turn that into a Void*, so we
    # "box" it: we allocate memory and store the Proc there
    boxed_data = Box.box(callback)

    # We must save this in Crystal-land so the GC doesn't collect it (*)
    @@box = boxed_data

    # We pass a callback that doesn't form a closure, and pass the boxed_data as
    # the callback data
    LibTicker.on_tick(->(tick, data) {
      # Now we turn data back into the Proc, using Box.unbox
      data_as_callback = Box(typeof(callback)).unbox(data)
      # And finally invoke the user's callback
      data_as_callback.call(tick)
    }, boxed_data)
  end
end

Ticker.on_tick do |tick|
  puts tick
end
```

Note that we save the boxed callback in `@@box`. The reason is that if we don't do it, and our code doesn't reference it anymore, the GC will collect it. The C library will of course store the callback, but Crystal's GC has no way of knowing that.

## Raises annotation

If a C function executes a user-provided callback that might raise, it must be annotated with the `@[Raises]` annotation.

The compiler infers this annotation for a method if it invokes a method that is marked as `@[Raises]` or raises (recursively).

However, some C functions accept callbacks to be executed by other C functions. For example, suppose a fictitious library:

```crystal
lib LibFoo
  fun store_callback(callback : ->)
  fun execute_callback
end

LibFoo.store_callback -> { raise "OH NO!" }
LibFoo.execute_callback
```

If the callback passed to `store_callback` raises, then `execute_callback` will raise. However, the compiler doesn't know that `execute_callback` can potentially raise because it is not marked as `@[Raises]` and the compiler has no way to figure this out. In these cases you have to manually mark such functions:

```crystal
lib LibFoo
  fun store_callback(callback : ->)

  @[Raises]
  fun execute_callback
end
```

If you don't mark them, `begin/rescue` blocks that surround this function's calls won't work as expected.
# Constants

You can also declare constants inside a `lib` declaration:

```crystal
@[Link("pcre")]
lib PCRE
  INFO_CAPTURECOUNT = 2
end

PCRE::INFO_CAPTURECOUNT # => 2
```
# enum

An `enum` declaration inside a `lib` declares a C enum:

```crystal
lib X
  # In C:
  #
  #  enum SomeEnum {
  #    Zero,
  #    One,
  #    Two,
  #    Three,
  #  };
  enum SomeEnum
    Zero
    One
    Two
    Three
  end
end
```

As in C, the first member of the enum has a value of zero and each successive value is incremented by one.

To use a value:

```crystal
X::SomeEnum::One # => One
```

You can specify the value of a member:

```crystal
lib X
  enum SomeEnum
    Ten       = 10
    Twenty    = 10 * 2
    ThirtyTwo = 1 << 5
  end
end
```

As you can see, some basic math is allowed for a member value: `+`, `-`, `*`, `/`, `&`, `|`, `<<`, `>>` and `%`.

The type of an enum member is `Int32` by default.  It's an error to specify a different type in a constant value.

```crystal
lib X
  enum SomeEnum
    A = 1_u32 # Error: enum value must be an Int32
  end
end
```

However, you can change this default type:

```crystal
lib X
  enum SomeEnum : Int8
    Zero
    Two  = 2
  end
end

X::SomeEnum::Zero # => 0_i8
X::SomeEnum::Two  # => 2_i8
```

You can use an enum as a type in a `fun` parameter or `struct` or `union` members:

```crystal
lib X
  enum SomeEnum
    One
    Two
  end

  fun some_fun(value : SomeEnum)
end
```
# fun

A `fun` declaration inside a `lib` binds to a C function.

```crystal
lib C
  # In C: double cos(double x)
  fun cos(value : Float64) : Float64
end
```

Once you bind it, the function is available inside the `C` type as if it was a class method:

```crystal
C.cos(1.5) # => 0.0707372
```

You can omit the parentheses if the function doesn't have parameters (and omit them in the call as well):

```crystal
lib C
  fun getch : Int32
end

C.getch
```

If the return type is void you can omit it:

```crystal
lib C
  fun srand(seed : UInt32)
end

C.srand(1_u32)
```

You can bind to variadic functions:

```crystal
lib X
  fun variadic(value : Int32, ...) : Int32
end

X.variadic(1, 2, 3, 4)
```

Note that there are no implicit conversions (except `to_unsafe`, which is explained later) when invoking a C function: you must pass the exact type that is expected. For integers and floats you can use the various `to_...` methods.

## Function names

Function names in a `lib` definition can start with an upper case letter. That's different from methods and function definitions outside a `lib`, which must start with a lower case letter.

Function names in Crystal can be different from the C name. The following example shows how to bind the C function name `SDL_Init` as `LibSDL.init` in Crystal.

```crystal
lib LibSDL
  fun init = SDL_Init(flags : UInt32) : Int32
end
```

The C name can be put in quotes to be able to write a name that is not a valid identifier:

```crystal
lib LLVMIntrinsics
  fun ceil_f32 = "llvm.ceil.f32"(value : Float32) : Float32
end
```

This can also be used to give shorter, nicer names to C functions, as these tend to be long and are usually prefixed with the library name.

## Types in C Bindings

The valid types to use in C bindings are:

* Primitive types (`Int8`, ..., `Int64`, `UInt8`, ..., `UInt64`, `Float32`, `Float64`)
* Pointer types (`Pointer(Int32)`, which can also be written as `Int32*`)
* Static arrays (`StaticArray(Int32, 8)`, which can also be written as `Int32[8]`)
* Function types (`Proc(Int32, Int32)`, which can also be written as `Int32 -> Int32`)
* Other `struct`, `union`, `enum`, `type` or `alias` declared previously.
* `Void`: the absence of a return value.
* `NoReturn`: similar to `Void`, but the compiler understands that no code can be executed after that invocation.
* Crystal structs marked with the `@[Extern]` annotation

Refer to the [type grammar](../type_grammar.md) for the notation used in fun types.

The standard library defines the [LibC](https://github.com/crystal-lang/crystal/blob/master/src/lib_c.cr) lib with aliases for common C types, like `int`, `short`, `size_t`. Use them in bindings like this:

```crystal
lib MyLib
  fun my_fun(some_size : LibC::SizeT)
end
```

NOTE: The C `char` type is `UInt8` in Crystal, so a `char*` or a `const char*` is `UInt8*`. The `Char` type in Crystal is a unicode codepoint so it is represented by four bytes, making it similar to an `Int32`, not to an `UInt8`. There's also the alias `LibC::Char` if in doubt.
# lib

A `lib` declaration groups C functions and types that belong to a library.

```crystal
@[Link("pcre")]
lib LibPCRE
end
```

Although not enforced by the compiler, a `lib`'s name usually starts with `Lib`.

Attributes are used to pass flags to the linker to find external libraries:

* `@[Link("pcre")]` will pass `-lpcre` to the linker, but the compiler will first try to use [pkg-config](http://en.wikipedia.org/wiki/Pkg-config).
* `@[Link(ldflags: "...")]` will pass those flags directly to the linker, without modification. For example: `@[Link(ldflags: "-lpcre")]`. A common technique is to use backticks to execute commands: ``@[Link(ldflags: "`pkg-config libpcre --libs`")]``.
* `@[Link(framework: "Cocoa")]` will pass `-framework Cocoa` to the linker (only useful in macOS).

Attributes can be omitted if the library is implicitly linked, as in the case of libc.

## Reflection

Lib functions are visible in the macro language anywhere in the program using the method [`TypeNode#methods`](https://crystal-lang.org/api/Crystal/Macros/TypeNode.html#methods%3AArrayLiteral%28Def%29-instance-method):

```crystal
lib LibFoo
  fun foo
end

{{ LibFoo.methods }} # => [fun foo]
```
# out

Consider the [waitpid](http://www.gnu.org/software/libc/manual/html_node/Process-Completion.html) function:

```crystal
lib C
  fun waitpid(pid : Int32, status_ptr : Int32*, options : Int32) : Int32
end
```

The documentation of the function says:

```
The status information from the child process is stored in the object
that status_ptr points to, unless status_ptr is a null pointer.
```

We can use this function like this:

```crystal
status_ptr = uninitialized Int32

C.waitpid(pid, pointerof(status_ptr), options)
```

In this way we pass a pointer of `status_ptr` to the function for it to fill its value.

There's a simpler way to write the above by using an `out` parameter:

```crystal
C.waitpid(pid, out status_ptr, options)
```

The compiler will automatically declare a `status_ptr` variable of type `Int32`, because the parameter's type is `Int32*`.

This will work for any `fun` parameter, as long as its type is a pointer (and, of course, as long as the function does fill the value the pointer is pointing to).
# struct

A `struct` declaration inside a `lib` declares a C struct.

```crystal
lib C
  # In C:
  #
  #  struct TimeZone {
  #    int minutes_west;
  #    int dst_time;
  #  };
  struct TimeZone
    minutes_west : Int32
    dst_time : Int32
  end
end
```

You can also specify many fields of the same type:

```crystal
lib C
  struct TimeZone
    minutes_west, dst_time : Int32
  end
end
```

Recursive structs work just like you expect them to:

```crystal
lib C
  struct LinkedListNode
    prev, _next : LinkedListNode*
  end

  struct LinkedList
    head : LinkedListNode*
  end
end
```

Structs that are defined inside a `lib` can be included, like modules, internally in other `lib` defined structs, for example:

```crystal
lib Lib
  struct Foo
    x : Int32
    y : Int16
  end

  struct Bar
    include Foo
    z : Int8
  end
end

Lib::Bar.new # => Lib::Bar(@x=0, @y=0, @z=0)
```

To create an instance of a struct use `new`:

```crystal
tz = C::TimeZone.new
```

This allocates the struct on the stack.

A C struct starts with all its fields set to "zero": integers and floats start at zero, pointers start with an address of zero, etc.

To avoid this initialization you can use `uninitialized`:

```crystal
tz = uninitialized C::TimeZone
tz.minutes_west # => some garbage value
```

You can set and get its properties:

```crystal
tz = C::TimeZone.new
tz.minutes_west = 1
tz.minutes_west # => 1
```

If the assigned value is not exactly the same as the property's type, [to_unsafe](to_unsafe.md) will be tried.

You can also initialize some fields with a syntax similar to [named arguments](../default_and_named_arguments.md):

```crystal
tz = C::TimeZone.new minutes_west: 1, dst_time: 2
tz.minutes_west # => 1
tz.dst_time     # => 2
```

A C struct is passed by value (as a copy) to functions and methods, and also passed by value when it is returned from a method:

```crystal
def change_it(tz)
  tz.minutes_west = 1
end

tz = C::TimeZone.new
change_it tz
tz.minutes_west # => 0
```

Refer to the [type grammar](../type_grammar.md) for the notation used in struct field types.
# to_unsafe

If a type defines a `to_unsafe` method, when passing it to C the value returned by this method will be passed. For example:

```crystal
lib C
  fun exit(status : Int32) : NoReturn
end

class IntWrapper
  def initialize(@value : Int32)
  end

  def to_unsafe
    @value
  end
end

wrapper = IntWrapper.new(1)
C.exit(wrapper) # wrapper.to_unsafe is passed to C function which has type Int32
```

This is very useful for defining wrappers of C types without having to explicitly transform them to their wrapped values.

For example, the `String` class implements `to_unsafe` to return `UInt8*`:

```crystal
lib C
  fun printf(format : UInt8*, ...) : Int32
end

a = 1
b = 2
C.printf "%d + %d = %d\n", a, b, a + b
```
# type

A `type` declaration inside a `lib` declares a kind of C `typedef`, but stronger:

```crystal
lib X
  type MyInt = Int32
end
```

Unlike C, `Int32` and `MyInt` are not interchangeable:

```crystal
lib X
  type MyInt = Int32

  fun some_fun(value : MyInt)
end

X.some_fun 1 # Error: argument 'value' of 'X#some_fun' must be X::MyInt, not Int32
```

Thus, a `type` declaration is useful for opaque types that are created by the C library you are wrapping. An example of this is the C `FILE` type, which you can obtain with `fopen`.

Refer to the [type grammar](../type_grammar.md) for the notation used in typedef types.
# union

A `union` declaration inside a `lib` declares a C union:

```crystal
lib U
  # In C:
  #
  #  union IntOrFloat {
  #    int some_int;
  #    double some_float;
  #  };
  union IntOrFloat
    some_int : Int32
    some_float : Float64
  end
end
```

To create an instance of a union use `new`:

```crystal
value = U::IntOrFloat.new
```

This allocates the union on the stack.

A C union starts with all its fields set to "zero": integers and floats start at zero, pointers start with an address of zero, etc.

To avoid this initialization you can use `uninitialized`:

```crystal
value = uninitialized U::IntOrFloat
value.some_int # => some garbage value
```

You can set and get its properties:

```crystal
value = U::IntOrFloat.new
value.some_int = 1
value.some_int   # => 1
value.some_float # => 4.94066e-324
```

If the assigned value is not exactly the same as the property's type, [to_unsafe](to_unsafe.md) will be tried.

A C union is passed by value (as a copy) to functions and methods, and also passed by value when it is returned from a method:

```crystal
def change_it(value)
  value.some_int = 1
end

value = U::IntOrFloat.new
change_it value
value.some_int # => 0
```

Refer to the [type grammar](../type_grammar.md) for the notation used in union field types.
# Variables

Variables exposed by a C library can be declared inside a `lib` declaration using a global-variable-like declaration:

```crystal
lib C
  $errno : Int32
end
```

Then it can be get and set:

```crystal
C.errno # => some value
C.errno = 0
C.errno # => 0
```

A variable can be marked as thread local with an annotation:

```crystal
lib C
  @[ThreadLocal]
  $errno : Int32
end
```

Refer to the [type grammar](../type_grammar.md) for the notation used in external variables types.
# Capturing blocks

A block can be captured and turned into a `Proc`, which represents a block of code with an associated context: the closured data.

To capture a block you must specify it as a method's block parameter, give it a name and specify the input and output types. For example:

```crystal
def int_to_int(&block : Int32 -> Int32)
  block
end

proc = int_to_int { |x| x + 1 }
proc.call(1) # => 2
```

The above code captures the block of code passed to `int_to_int` in the `block` variable, and returns it from the method. The type of `proc` is [`Proc(Int32, Int32)`](https://crystal-lang.org/api/Proc.html), a function that accepts a single `Int32` argument and returns an `Int32`.

In this way a block can be saved as a callback:

```crystal
class Model
  def on_save(&block)
    @on_save_callback = block
  end

  def save
    if callback = @on_save_callback
      callback.call
    end
  end
end

model = Model.new
model.on_save { puts "Saved!" }
model.save # prints "Saved!"
```

In the above example the type of `&block` wasn't specified: this just means that the captured block doesn't take any arguments and doesn't return anything.

Note that if the return type is not specified, nothing gets returned from the proc call:

```crystal
def some_proc(&block : Int32 ->)
  block
end

proc = some_proc { |x| x + 1 }
proc.call(1) # => nil
```

To have something returned, either specify the return type or use an underscore to allow any return type:

```crystal
def some_proc(&block : Int32 -> _)
  block
end

proc = some_proc { |x| x + 1 }
proc.call(1) # 2

proc = some_proc { |x| x.to_s }
proc.call(1) # "1"
```

## break and next

`return` and `break` can't be used inside a captured block. `next` can be used and will exit and give the value of the captured block.

## with ... yield

The default receiver within a captured block can't be changed by using `with ... yield`.
# case

A `case` is a control expression which functions a bit like pattern matching. It allows writing a chain of if-else-if with a small change in semantic and some more powerful constructs.

In its basic form, it allows matching a value against other values:

```crystal
case exp
when value1, value2
  do_something
when value3
  do_something_else
else
  do_another_thing
end

# The above is the same as:
tmp = exp
if value1 === tmp || value2 === tmp
  do_something
elsif value3 === tmp
  do_something_else
else
  do_another_thing
end
```

For comparing an expression against a `case`'s subject, the compiler uses the [*case subsumption operator* `===`](./operators.md#subsumption). It is defined as a method on [`Object`](https://crystal-lang.org/api/Object.html#%3D%3D%3D%28other%29-instance-method) and can be overridden by subclasses to provide meaningful semantics in case statements. For example, [`Class`](https://crystal-lang.org/api/Class.html#%3D%3D%3D%28other%29-instance-method) defines case subsumption as when an object is an instance of that class, [`Regex`](https://crystal-lang.org/api/Regex.html#%3D%3D%3D%28other%3AString%29-instance-method) as when the value matches the regular expression and [`Range`](https://crystal-lang.org/api/Range.html#%3D%3D%3D%28value%29-instance-method) as when the value is included in that range.

If a `when`'s expression is a type, `is_a?` is used. Additionally, if the case expression is a variable or a variable assignment the type of the variable is restricted:

```crystal
case var
when String
  # var : String
  do_something
when Int32
  # var : Int32
  do_something_else
else
  # here var is neither a String nor an Int32
  do_another_thing
end

# The above is the same as:
if var.is_a?(String)
  do_something
elsif var.is_a?(Int32)
  do_something_else
else
  do_another_thing
end
```

You can invoke a method on the `case`'s expression in a `when` by using the implicit-object syntax:

```crystal
case num
when .even?
  do_something
when .odd?
  do_something_else
end

# The above is the same as:
tmp = num
if tmp.even?
  do_something
elsif tmp.odd?
  do_something_else
end
```

You may use `then` after the `when` condition to place the body on a single line.

```crystal
case exp
when value1, value2 then do_something
when value3         then do_something_else
else                     do_another_thing
end
```

Finally, you can omit the `case`'s value:

```crystal
case
when cond1, cond2
  do_something
when cond3
  do_something_else
end

# The above is the same as:
if cond1 || cond2
  do_something
elsif cond3
  do_something_else
end
```

This sometimes leads to code that is more natural to read.

## Tuple literal

When a case expression is a tuple literal there are a few semantic differences if a `when` condition is also a tuple literal.

### Tuple size must match

```{.crystal nocheck}
case {value1, value2}
when {0, 0} # OK, 2 elements
  # ...
when {1, 2, 3} # Syntax error: wrong number of tuple elements (given 3, expected 2)
  # ...
end
```

### Underscore allowed

```crystal
case {value1, value2}
when {0, _}
  # Matches if 0 === value1, no test done against value2
when {_, 0}
  # Matches if 0 === value2, no test done against value1
end
```

### Implicit-object allowed

```crystal
case {value1, value2}
when {.even?, .odd?}
  # Matches if value1.even? && value2.odd?
end
```

### Comparing against a type will perform an is_a? check

```crystal
case {value1, value2}
when {String, Int32}
  # Matches if value1.is_a?(String) && value2.is_a?(Int32)
  # The type of value1 is known to be a String by the compiler,
  # and the type of value2 is known to be an Int32
end
```

## Exhaustive case

Using `in` instead of `when` produces an exhaustive case expression; in an exhaustive case, it is a compile-time error to omit any of the required `in` conditions. An exhaustive `case` cannot contain any `when` or `else` clauses.

The compiler supports the following `in` conditions:

### Union type checks

If `case`'s expression is a union value, each of the union types may be used as a condition:

```crystal
# var : (Bool | Char | String)?
case var
in String
  # var : String
in Char
  # var : Char
in Bool
  # var : Bool
in nil # or Nil, but .nil? is not allowed
  # var : Nil
end
```

### Bool values

If `case`'s expression is a `Bool` value, the `true` and `false` literals may be used as conditions:

```crystal
# var : Bool
case var
in true
  do_something
in false
  do_something_else
end
```

### Enum values

If `case`'s expression is a non-flags enum value, its members may be used as conditions, either as constant or predicate method.

```crystal
enum Foo
  X
  Y
  Z
end

# var : Foo
case var
in Foo::X
  # var == Foo::X
in .y?
  # var == Foo::Y
in .z? # :z is not allowed
  # var == Foo::Z
end
```

### Tuple literals

The conditions must exhaust all possible combinations of the `case` expression's elements:

```crystal
# value1, value2 : Bool
case {value1, value2}
in {true, _}
  # value1 is true, value2 can be true or false
  do_something
in {_, false}
  # here value1 is false, and value2 is also false
  do_something_else
end

# Error: case is not exhaustive.
#
# Missing cases:
#  - {false, true}
```
# Class methods

Class methods are methods associated to a class or module instead of a specific instance.

```crystal
module CaesarCipher
  def self.encrypt(string : String)
    string.chars.map { |char| ((char.upcase.ord - 52) % 26 + 65).chr }.join
  end
end

CaesarCipher.encrypt("HELLO") # => "URYYB"
```

Class methods are defined by prefixing the method name with the type name and a period.

```crystal
def CaesarCipher.decrypt(string : String)
  encrypt(string)
end
```

When they're defined inside a class or module scope it is easier to use `self` instead of the class name.

Class methods can also be defined by [extending a `Module`](modules.md#extend-self).

A class method can be called under the same name as it was defined (`CaesarCipher.decrypt("HELLO")`).
When called from within the same class or module scope the receiver can be `self` or implicit (like `encrypt(string)`).

A class method is not in scope within an instance of the class; instead, access it through the class scope.

```crystal
class Foo
  def self.shout(str : String)
    puts str.upcase
  end

  def baz
    self.class.shout("baz")
  end
end

Foo.new.baz # => BAZ
```

## Constructors

Constructors are normal class methods which [create a new instance of the class](new,_initialize_and_allocate.md).
By default all classes in Crystal have at least one constructor called `new`, but they may also define other constructors with different names.
# Class variables

Class variables are associated to classes instead of instances. They are prefixed with two "at" signs (`@@`). For example:

```crystal
class Counter
  @@instances = 0

  def initialize
    @@instances += 1
  end

  def self.instances
    @@instances
  end
end

Counter.instances # => 0
Counter.new
Counter.new
Counter.new
Counter.instances # => 3
```

Class variables can be read and written from class methods or instance methods.

Their type is inferred using the [global type inference algorithm](type_inference.md).

Class variables are inherited by subclasses with this meaning: their type is the same, but each class has a different runtime value. For example:

```crystal
class Parent
  @@numbers = [] of Int32

  def self.numbers
    @@numbers
  end
end

class Child < Parent
end

Parent.numbers # => []
Child.numbers  # => []

Parent.numbers << 1
Parent.numbers # => [1]
Child.numbers  # => []
```

Class variables can also be associated to modules and structs. Like above, they are inherited by including/subclassing types.
# Classes and methods

A class is a blueprint from which individual objects are created. As an example, consider a `Person` class. You declare a class like this:

```crystal
class Person
end
```

Class names, and indeed all type names, begin with a capital letter in Crystal.
# Closures

Captured blocks and proc literals closure local variables and `self`. This is better understood with an example:

```crystal
x = 0
proc = -> { x += 1; x }
proc.call # => 1
proc.call # => 2
x         # => 2
```

Or with a proc returned from a method:

```crystal
def counter
  x = 0
  -> { x += 1; x }
end

proc = counter
proc.call # => 1
proc.call # => 2
```

In the above example, even though `x` is a local variable, it was captured by the proc literal. In this case the compiler allocates `x` on the heap and uses it as the context data of the proc to make it work, because normally local variables live in the stack and are gone after a method returns.

## Type of closured variables

The compiler is usually moderately smart about the type of local variables. For example:

```crystal
def foo(&)
  yield
end

x = 1
foo do
  x = "hello"
end
x # : Int32 | String
```

The compiler knows that after the block, `x` can be Int32 or String (it could know that it will always be String because the method always yields; this may improve in the future).

If `x` is assigned something else after the block, the compiler knows the type changed:

```crystal
x = 1
foo do
  x = "hello"
end
x # : Int32 | String

x = 'a'
x # : Char
```

However, if `x` is closured by a proc, the type is always the mixed type of all assignments to it:

```crystal
def capture(&block)
  block
end

x = 1
capture { x = "hello" }

x = 'a'
x # : Int32 | String | Char
```

This is because the captured block could have been potentially stored in a class or instance variable and invoked in a separate thread in between the instructions. The compiler doesn't do an exhaustive analysis of this: it just assumes that if a variable is captured by a proc, the time of that proc invocation is unknown.

This also happens with regular proc literals, even if it's evident that the proc wasn't invoked or stored:

```crystal
x = 1
-> { x = "hello" }

x = 'a'
x # : Int32 | String | Char
```
# Comments

Comments start with the `#` character. All following content up to the end of
the line is part of the comment. Comments may be on their own line or follow
after a Crystal expression (trailing comment).

```crystal
# This is a comment
puts "hello" # This is a trailing comment
```

The purpose of comments is documenting the code. Public documentation, including
autogenerated API docs, is a special feature based on comments and is described
in [*Documenting Code*](../syntax_and_semantics/documenting_code.md).
# Compile-time flags

Compile-time flags are boolean values provided through the compiler via a macro method.
They allow to conditionally include or exclude code based on compile time conditions.

There are several default flags provided by the compiler with information about compiler options and the target platform.
User-provided flags are passed to the compiler, which allow them to be used as feature flags.

## Querying flags

A flag is a named identifier which is either set or not.
The status can be queried from code via the macro method [`flag?`](https://crystal-lang.org/api/Crystal/Macros.html#flag%3F%28name%29%3ABoolLiteral-instance-method). It receives the name of a flag as a string or symbol
literal and returns a bool literal indicating the flag's state. A flag can have an optional value, in which case the macro method `flag?` returns a string literal instead of a bool literal.

The following program shows the use of compile-time flags by printing the target OS family.

```cr
{% if flag?(:unix) %}
  puts "This program is compiled for a UNIX-like operating system"
{% elsif flag?(:windows) %}
  puts "This program is compiled for Windows"
{% else %}
  # Currently, all supported targets are either UNIX or Windows platforms, so
  # this branch is practically unreachable.
  puts "Compiling for some other operating system"
{% end %}
```

There's also the macro method [`host_flag?`](https://crystal-lang.org/api/Crystal/Macros.html#host_flag%3F%28name%29%3ABoolLiteral-instance-method)
which returns whether a flag is set for the *host* platform, which can differ
from the target platform (queried by `flag?`) during cross-compilation.

## Compiler-provided flags

The compiler defines a couple of implicit flags. They describe either the target platform or compiler options.

### Target platform flags

Platform-specific flags derive from the [target triple](http://llvm.org/docs/LangRef.html#target-triple).
See [Platform Support](platform_support.md) for a list of supported target platforms.

`crystal --version` shows the default target triple of the compiler. It can be changed with the `--target` option.

The flags in each of the following tables are mutually exclusive, except for those marked as *(derived)*.

#### Architecture

The target architecture is the first component of the target triple.

| Flag name | Description |
|-----------|-------------|
| `aarch64` | AArch64 architecture |
| `avr`     | AVR architecture |
| `arm`     | ARM architecture |
| `i386`    | x86 architecture (32-bit) |
| `wasm32`  | WebAssembly |
| `x86_64`  | x86-64 architecture |
| `bits32` *(derived)*  | 32-bit architecture |
| `bits64` *(derived)*  | 64-bit architecture |

#### Vendor

The vendor is the second component of the target triple. This is typically unused,
so the most common vendor is `unknown`.

| Flag name | Description |
|-----------|-------------|
| `macosx`  | Apple |
| `portbld` | FreeBSD variant |
| `unknown` | Unknown vendor |

#### Operating System

The operating system is derived from the third component of a the target triple.

| Flag name | Description |
|-----------|-------------|
| `bsd` *(derived)* | BSD family (DragonFlyBSD, FreeBSD, NetBSD, OpenBSD) |
| `darwin`  | Darwin (MacOS) |
| `dragonfly` | DragonFlyBSD |
| `freebsd` | FreeBSD |
| `linux`   | Linux |
| `netbsd`  | NetBSD |
| `openbsd` | OpenBSD |
| `solaris` | Solaris/illumos |
| `unix` *(derived)* | UNIX-like (BSD, Darwin, Linux, Solaris) |
| `windows` | Windows |

#### ABI

The ABI is derived from the last component of the target triple.

| Flag name | Description |
|-----------|-------------|
| `android` | Android (Bionic C runtime) |
| `armhf` *(derived)* | ARM EABI with hard float |
| `gnu`     | GNU |
| `gnueabihf` | GNU EABI with hard float |
| `msvc`    | Microsoft Visual C++ |
| `musl`    | musl |
| `wasi`    | Web Assembly System Interface |
| `win32` *(derived)* | Windows API |

### Compiler options

The compiler sets these flags based on compiler configuration.

| Flag name | Description |
|-----------|-------------|
| `release` | Compiler operates in release mode (`--release` or `-O3 --single-module` CLI option) |
| `debug`   | Compiler generates debug symbols (without `--no-debug` CLI option) |
| `static`  | Compiler creates a statically linked executable (`--static` CLI option) |
| `docs`    | Code is processed to generate API docs (`crystal docs` command) |
| `interpreted` | Running in the interpreter (`crystal i`) |

## User-provided flags

User-provided flags are not defined automatically. They can be passed to the compiler via the `--define` or `-D` command line options. A flag can have an explicit string value when defined in the form `foo=bar`.

These flags usually enable certain features which activate breaking new or legacy functionality,
a preview for a new feature, or entirely alternative behaviour (e.g. for debugging purposes).

```console
$ crystal eval -Dfoo 'p {{ flag?(:foo) }}'
true
$ crystal eval -Dfoo=bar 'p {{ flag?(:foo) }}'
"bar"
```

### Stdlib features

These flags enable or disable features in the standard library when building a
Crystal program.

| Flag name | Description |
|-----------|-------------|
| `gc_none` | Disables garbage collection ([#5314](https://github.com/crystal-lang/crystal/pull/5314)) |
| `debug_raise` | Debugging flag for `raise` logic. Prints the backtrace before raising. |
| `evloop=epoll`, `evloop=kqueue`, `evloop=libevent` | Select event loop driver ([RFC 0009](https://github.com/crystal-lang/rfcs/blob/main/text/0009-lifetime-event_loop.md#availability)). Introduced in 1.15 |
| `execution_context` | Enable execution contexts preview ([RFC 0002](https://github.com/crystal-lang/rfcs/blob/main/text/0002-execution-contexts.md)). [Introduced in 1.16](https://github.com/crystal-lang/crystal/issues/15350) |
| `preview_mt` | Enables multithreading preview. Introduced in 0.28.0 ([#7546](https://github.com/crystal-lang/crystal/pull/7546)) |
| `skip_crystal_compiler_rt` | Exclude Crystal's native `compiler-rt` implementation. |
| `tracing` | Build with support for [runtime tracing](../guides/runtime_tracing.md). |
| `use_libiconv` | Use `libiconv` instead of the `iconv` system library |
| `use_pcre2` | Use PCRE2 as regex engine (instead of legacy PCRE). Introduced in 1.7.0. |
| `use_pcre` | Use PCRE as regex engine (instead of PCRE2). Introduced in 1.8.0. |
| `win7`     | Use Win32 WinNT API for Windows 7 |
| `without_iconv` | Do not link `iconv`/`libiconv` |
| `without_openssl` | Build without OpenSSL support |
| `without_zlib` | Build without Zlib support |

### Language features

These flags enable or disable language features when building a Crystal program.

| Flag name | Description |
|-----------|-------------|
| `no_number_autocast` | Will not [autocast](autocasting.md#number-autocasting) numeric expressions, only literals |
| `no_restrictions_augmenter` | Disable enhanced restrictions augmenter. Introduced in 1.5 ([#12103](https://github.com/crystal-lang/crystal/pull/12103)). |
| `preview_overload_order` | Enable more robust ordering between def overloads. Introduced in 1.6 ([#10711](https://github.com/crystal-lang/crystal/issues/10711)). |
| `strict_multi_assign` | Enable strict semantics for [one-to-many assignment](assignment.md#one-to-many-assignment). Introduced in 1.3.0 ([#11145](https://github.com/crystal-lang/crystal/pull/11145), [#11545](https://github.com/crystal-lang/crystal/pull/11545)) |

### Codegen features

These flags enable or disable codegen features when building a Crystal program.

| Flag name | Description |
|-----------|-------------|
| `cf-protection=branch`, `cf-protection=return`, `cf-protection=full` | Indirect branch tracking for x86 and x86_64. Implicitly set on OpenBSD. Introduced in 1.15.0 ([#15122](https://github.com/crystal-lang/crystal/pull/15122)) |
| `branch-protection=bti` | Indirect branch tracking for aarch64. Implicitly set on OpenBSD. Introduced in 1.15.0 ([#15122](https://github.com/crystal-lang/crystal/pull/15122)) |

### Compiler build features

These flags enable or disable features when building the Crystal compiler.

| Flag name | Description |
|-----------|-------------|
| `without_ffi`     | Build the compiler without `libffi` |
| `without_interpreter`  | Build the compiler without interpreter support |
| `without_libxml2`       | Build the compiler without sanitization for the doc generator. [Introduced in 1.19](https://github.com/crystal-lang/crystal/pull/14646).<br> Note: The default `Makefile` passes this flag unless `docs_sanitizer=1` |
| `without_playground` | Build the compiler without playground (`crystal play`) |
| `i_know_what_im_doing` | Safety guard against involuntarily building the compiler |

### User code features

Custom flags can be freely used in user code as long as they don't collide with compiler-provided flags
or other user-defined flags.
When using a flag specific to a shard, it's recommended to use the shard name as a prefix.
# Constants

Constants can be declared at the top level or inside other types. They must start with a capital letter:

```crystal
PI = 3.14

module Earth
  RADIUS = 6_371_000
end

PI            # => 3.14
Earth::RADIUS # => 6_371_000
```

Although not enforced by the compiler, constants are usually named with all capital letters and underscores to separate words.

A constant definition can invoke methods and have complex logic:

```crystal
TEN = begin
  a = 0
  while a < 10
    a += 1
  end
  a
end

TEN # => 10
```

## Pseudo Constants

Crystal provides a few pseudo-constants which provide reflective data about the source code being executed.

`__LINE__` is the current line number in the currently executing Crystal file. When `__LINE__` is used as a default parameter value, it represents the line number at the location of the method call.

`__END_LINE__` is the line number of the `end` of the calling block. Can only be used as a default parameter value.

`__FILE__` references the full path to the currently executing Crystal file.

`__DIR__` references the full path to the directory where the currently executing Crystal file is located.

```crystal
# Assuming this example code is saved at: /crystal_code/pseudo_constants.cr
#
def pseudo_constants(caller_line = __LINE__, end_of_caller = __END_LINE__)
  puts "Called from line number: #{caller_line}"
  puts "Currently at line number: #{__LINE__}"
  puts "End of caller block is at: #{end_of_caller}"
  puts "File path is: #{__FILE__}"
  puts "Directory file is in: #{__DIR__}"
end

begin
  pseudo_constants
end

# Program prints:
# Called from line number: 13
# Currently at line number: 5
# End of caller block is at: 14
# File path is: /crystal_code/pseudo_constants.cr
# Directory file is in: /crystal_code
```

## Dynamic assignment

Dynamically assigning values to constants using the [chained assignment](assignment.md#chained-assignment) or the [multiple assignment](assignment.md#multiple-assignment) is not supported and results in a syntax error.

```{.crystal nocheck}
ONE, TWO, THREE = 1, 2, 3 # Syntax error: Multiple assignment is not allowed for constants
```
# Control expressions

Before talking about control expressions we need to know what *truthy* and *falsey* values are.
# Cross-compilation

Crystal supports a basic form of [cross compilation](http://en.wikipedia.org/wiki/Cross_compiler).

In order to achieve this, the compiler executable provides two flags:

* `--cross-compile`: When given enables cross compilation mode
* `--target`: the [LLVM Target Triple](http://llvm.org/docs/LangRef.html#target-triple) to use and set the default [compile-time flags](compile_time_flags.md) from

To get the `--target` flags you can execute `llvm-config --host-target` using an installed LLVM on the target system. For example on a Linux it could say "x86_64-unknown-linux-gnu".

If you need to set any compile-time flags not set implicitly through `--target`, you can use the `-D` command line flag.

Using these two, we can compile a program in a Mac that will run on that Linux like this:

```bash
crystal build your_program.cr --cross-compile --target "x86_64-unknown-linux-gnu"
```

This will generate a `.o` ([Object file](http://en.wikipedia.org/wiki/Object_file)) and will print a line with a command to execute on the system we are trying to cross-compile to. For example:

```bash
cc your_program.o -o your_program -lpcre -lrt -lm -lgc -lunwind
```

You must copy this `.o` file to that system and execute those commands. Once you do this the executable will be available in that target system.

This procedure is usually done with the compiler itself to port it to new platforms where a compiler is not yet available. Because in order to compile a Crystal compiler we need an older Crystal compiler, the only two ways to generate a compiler for a system where there isn't a compiler yet are:

* We checkout the latest version of the compiler written in Ruby, and from that compiler we compile the next versions until the current one.
* We create a `.o` file in the target system and from that file we create a compiler.

The first alternative is long and cumbersome, while the second one is much easier.

Cross-compiling can be done for other executables, but its main target is the compiler. If Crystal isn't available in some system you can try cross-compiling it there.
# Uninitialized variable declaration

Crystal allows declaring uninitialized variables:

```crystal
x = uninitialized Int32
x # => some random value, garbage, unreliable
```

This is [unsafe](unsafe.md) code and is almost always used in low-level code for declaring uninitialized [StaticArray](https://crystal-lang.org/api/StaticArray.html) buffers without a performance penalty:

```crystal
buffer = uninitialized UInt8[256]
```

The buffer is allocated on the stack, avoiding a heap allocation.

The type after the `uninitialized` keyword follows the [type grammar](type_grammar.md).
# Default parameter values and named arguments

## Default parameter values

A method can specify default values for the last parameters:

```crystal
class Person
  def become_older(by = 1)
    @age += by
  end
end

john = Person.new "John"
john.age # => 0

john.become_older
john.age # => 1

john.become_older 2
john.age # => 3
```

## Named arguments

All arguments can also be specified, in addition to their position, by their name. For example:

```crystal
john.become_older by: 5
```

When there are many arguments, the order of the names in the invocation doesn't matter, as long as all required parameters are covered:

```crystal
def some_method(x, y = 1, z = 2, w = 3)
  # do something...
end

some_method 10                   # x: 10, y: 1, z: 2, w: 3
some_method 10, z: 10            # x: 10, y: 1, z: 10, w: 3
some_method 10, w: 1, y: 2, z: 3 # x: 10, y: 2, z: 3, w: 1
some_method y: 10, x: 20         # x: 20, y: 10, z: 2, w: 3

some_method y: 10 # Error, missing argument: x
```

When a method specifies a splat parameter (explained in the next section), named arguments can't be used for positional parameters. The reason is that understanding how arguments are matched becomes very difficult; positional arguments are easier to reason about in this case.
# Method arguments

This is the formal specification of method parameters and call arguments.

## Components of a method definition

A method definition consists of:

* required and optional positional parameters
* an optional splat parameter, whose name can be empty
* required and optional named parameters
* an optional double splat parameter

For example:

```crystal
def foo(
  # These are positional parameters:
  x, y, z = 1,
  # This is the splat parameter:
  *args,
  # These are the named parameters:
  a, b, c = 2,
  # This is the double splat parameter:
  **options,
)
end
```

Each one of them is optional, so a method can do without the double splat, without the splat, without named parameters and without positional parameters.

## Components of a method call

A method call also has some parts:

```crystal
foo(
  # These are positional arguments
  1, 2,
  # These are named arguments
  a: 1, b: 2
)
```

Additionally, a call argument can have a splat (`*`) or double splat (`**`). A splat expands a [Tuple](literals/tuple.md) into positional arguments, while a double splat expands a [NamedTuple](literals/named_tuple.md) into named arguments. Multiple argument splats and double splats are allowed.

## How call arguments are matched to method parameters

When invoking a method, the algorithm to match call arguments to method parameters is:

* First positional call arguments are matched with positional method parameters. The number of these must be at least the number of positional parameters without a default value. If there's a splat parameter with a name (the case without a name is explained below), more positional arguments are allowed and they are captured as a tuple. Positional arguments never match past the splat parameter.
* Then named arguments are matched, by name, with any parameter in the method (it can be before or after the splat parameter). If a parameter was already filled by a positional argument then it's an error.
* Extra named arguments are placed in the double splat method parameter, as a [NamedTuple](literals/named_tuple.md), if it exists, otherwise it's an error.

When a splat parameter has no name, it means no more positional arguments can be passed, and any following parameters must be passed as named arguments. For example:

```crystal
# Only one positional argument allowed, y must be passed as a named argument
def foo(x, *, y)
end

foo 1        # Error, missing argument: y
foo 1, 2     # Error: wrong number of arguments (given 2, expected 1)
foo 1, y: 10 # OK
```

But even if a splat parameter has a name, parameters that follow it must be passed as named arguments:

```crystal
# One or more positional argument allowed, y must be passed as a named argument
def foo(x, *args, y)
end

foo 1             # Error, missing argument: y
foo 1, 2          # Error: missing argument; y
foo 1, 2, 3       # Error: missing argument: y
foo 1, y: 10      # OK
foo 1, 2, 3, y: 4 # OK
```

There's also the possibility of making a method only receive named arguments (and list them), by placing the star at the beginning:

```crystal
# A method with two required named parameters: x and y
def foo(*, x, y)
end

foo            # Error: missing arguments: x, y
foo x: 1       # Error: missing argument: y
foo x: 1, y: 2 # OK
```

Parameters past the star can also have default values. It means: they must be passed as named arguments, but they aren't required (so: optional named parameters):

```crystal
# x is a required named parameter, y is an optional named parameter
def foo(*, x, y = 2)
end

foo            # Error: missing argument: x
foo x: 1       # OK, y is 2
foo x: 1, y: 3 # OK, y is 3
```

Because parameters (without a default value) after the splat parameter must be passed by name, two methods with different required named parameters overload:

```crystal
def foo(*, x)
  puts "Passed with x: #{x}"
end

def foo(*, y)
  puts "Passed with y: #{y}"
end

foo x: 1 # => Passed with x: 1
foo y: 2 # => Passed with y: 2
```

Positional parameters can always be matched by name:

```crystal
def foo(x, *, y)
end

foo 1, y: 2    # OK
foo y: 2, x: 3 # OK
```

## External names

An external name can be specified for a method parameter. The external name is the one used when passing an argument as a named argument, and the internal name is the one used to refer to the parameter inside the method definition:

```crystal
def foo(external_name internal_name)
  # here we use internal_name
end

foo external_name: 1
```

This covers two uses cases.

The first use case is using keywords as named parameters:

```crystal
def plan(begin begin_time, end end_time)
  puts "Planning between #{begin_time} and #{end_time}"
end

plan begin: Time.local, end: 2.days.from_now
```

The second use case is making a method parameter more readable inside a method body:

```crystal
def increment(value, by)
  # OK, but reads odd
  value + by
end

def increment(value, by amount)
  # Better
  value + amount
end
```
# Documenting code

Documentation for API features can be written in code comments directly
preceding the definition of the respective feature.

By default, all public methods, macros, types and constants are
considered part of the API documentation. Lib types and non-public features
are excluded by default. Inclusion is configurable with the [`:nodoc:`](#nodoc)
and [`:showdoc:`](#showdoc) directives.

TIP:
The compiler command [`crystal docs`](../man/crystal/README.md#crystal-docs)
automatically extracts the API documentation and generates a website to
present it.

## Association

Doc comments must be positioned directly above the definition of the
documented feature. Consecutive comment lines are combined into a single comment
block. Any empty line breaks the association to the documented feature.

```crystal
# This comment is not associated with the class.

# First line of documentation for class Unicorn.
# Second line of documentation for class Unicorn.
class Unicorn
end
```

## Format

Doc comments support [Markdown](https://daringfireball.net/projects/markdown/) formatting.

The first paragraph of a doc comment is considered its summary. It should concisely
define the purpose and functionality.

Supplementary details and usages instructions should follow in subsequent paragraphs.

For instance:

```crystal
# Returns the number of horns this unicorn has.
#
# Always returns `1`.
def horns
  1
end
```

TIP:
It is generally advised to use descriptive, third person present tense:
`Returns the number of horns this unicorn has` (instead of an imperative `Return the number of horns this unicorn has`).

## Markup

### Linking

References to other API features can be enclosed in single backticks. They are
automatically resolved and converted into links to the respective feature.

```crystal
class Unicorn
  # Creates a new `Unicorn` instance.
  def initialize
  end
end
```

The same lookup rules apply as in Crystal code. Features in the currently
documented namespace can be accessed with relative names:

* Instance methods are referenced with a hash prefix: `#horns`.
* Class methods are referenced with a dot prefix: `.new`.
* Constants and types are referenced by their name: `Unicorn`.

Features in other namespaces are referenced with the fully-qualified type path: `Unicorn#horns`, `Unicorn.new`, `Unicorn::CONST`.

Different overloads of a method can be identified by the full signature `.new(name)`, `.new(name, age)`.

### Parameters

When referring to parameters, it is recommended to write their name *italicized* (`*italicized*`):

```crystal
# Creates a unicorn with the specified number of *horns*.
def initialize(@horns = 1)
  raise "Not a unicorn" if @horns != 1
end
```

### Code Examples

Code examples can be placed in Markdown code blocks.
If no language tag is given, the code block is considered to be Crystal code.

```crystal
# Example:
# ```
# unicorn = Unicorn.new
# unicorn.horns # => 1
# ```
class Unicorn
end
```

To designate a code block as plain text, it must be explicitly tagged.

```crystal
# Output:
# ```plain
# "I'm a unicorn"
# ```
def say
  puts "I'm a unicorn"
end
```

Other language tags can also be used.

To show the value of an expression inside code blocks, use `# =>`.

```crystal
1 + 2             # => 3
Unicorn.new.speak # => "I'm a unicorn"
```

### Admonitions

Several admonition keywords are supported to visually highlight problems, notes and/or possible issues.

* `BUG`
* `DEPRECATED`
* `EXPERIMENTAL`
* `FIXME`
* `NOTE`
* `OPTIMIZE`
* `TODO`
* `WARNING`

Admonition keywords must be the first word in their respective line and must be in all caps. An optional trailing colon is preferred for readability.

```crystal
# Makes the unicorn speak to STDOUT
#
# NOTE: Although unicorns don't normally talk, this one is special
# TODO: Check if unicorn is asleep and raise exception if not able to speak
# TODO: Create another `speak` method that takes and prints a string
def speak
  puts "I'm a unicorn"
end

# Makes the unicorn talk to STDOUT
#
# DEPRECATED: Use `speak`
def talk
  puts "I'm a unicorn"
end
```

The compiler implicitly adds some admonitions to doc comments:

* The [`@[Deprecated]`](https://crystal-lang.org/api/Deprecated.html) annotation
  adds a `DEPRECATED` admonition.
* The [`@[Experimental]`](https://crystal-lang.org/api/Experimental.html) annotation
  adds an `EXPERIMENTAL` admonition.

## Directives

Directives tell the documentation generator how to treat documentation for a
specific feature.

### `ditto`

If two consecutively defined features have the same documentation, `:ditto:`
can be used to copy the same doc comment from the previous definition.

```crystal
# Returns the number of horns.
def horns
  horns
end

# :ditto:
def number_of_horns
  horns
end
```

The directive needs to be on a separate line but further documentation can be
added in other lines. The `:ditto:` directive is simply replaced by the content
of the previous doc comment.

### `nodoc`

Public features can be hidden from the API docs with the `:nodoc:` directive.
Private and protected features are always hidden.

```crystal
# :nodoc:
class InternalHelper
end
```

This directive needs to be the first line in a doc comment. Leading whitespace is
optional.
Following comment lines can be used for internal documentation.

### `showdoc`

The `:showdoc:` directive includes normally undocumented types and methods in
the API documentation.
It can be applied to private and protected features, as well as lib types to have
them show up in API documentation.

In the following example, the API docs for `Foo` include `Foo.foo` even though it is a private method.

```crystal
module Foo
  # :showdoc:
  #
  # This private method is part of the API docs.
  private def self.foo
  end
end
```

This directive needs to be the first line in a doc comment. Leading whitespace is
optional.
Following comment lines are used as the documentation content.

When applied to a lib type, all features inside the lib namespace (funs, types,
variables, etc.) are also included in the API docs.
Individual features can be explicitly excluded with `:nodoc:`, though.

```crystal
# :showdoc:
#
# This lib type and all features inside are part of the API docs.
lib LibFoo
  # Documentation for bar
  fun bar : Void

  # :nodoc:
  # baz is not part of the API docs
  fun baz : Void

  # Documentation for FooEnum
  enum FooEnum
    Member1
    Member2
    Member3
  end

  # Documentation for FooStruct
  struct FooStruct
    var_1 : Int32
    var_2 : Int32
  end
end
```

If a parent namespace is undocumented, any nested `:showdoc:` directive
has no effect.

```crystal
# :nodoc:
struct MyStruct
  # :showdoc:
  #
  # This showdoc directive has no effect because the MyStruct namespace is nodoc.
  struct MyStructChild
  end
end

# Implicitly nodoc
lib LibFoo
  # :showdoc:
  #
  # This showdoc directive has no effect because the LibFoo namespace is implicitly undocumented.
  # If LibFoo had a showdoc directive, the showdoc directive here would be redundant.
  fun bar : Void
end
```

### `inherit`

See [*Inheriting Documentation*](#inheriting-documentation).

## Inheriting Documentation

When an instance method has no doc comment, but a method with the same signature exists in a parent type, the documentation is inherited from the parent method.

For example:

```crystal
abstract class Animal
  # Returns the name of `self`.
  abstract def name : String
end

class Unicorn < Animal
  def name : String
    "unicorn"
  end
end
```

The documentation for `Unicorn#name` would be:

```
Description copied from class `Animal`

Returns the name of `self`.
```

The child method can use `:inherit:` to explicitly copy the parent's documentation, without the `Description copied from ...` text.  `:inherit:` can also be used to inject the parent's documentation into additional documentation on the child.

For example:

```crystal
abstract class Parent
  # Some documentation common to every *id*.
  abstract def id : Int32
end

class Child < Parent
  # Some documentation specific to *id*'s usage within `Child`.
  #
  # :inherit:
  def id : Int32
    -1
  end
end
```

The documentation for `Child#id` would be:

```
Some documentation specific to *id*'s usage within `Child`.

Some documentation common to every *id*.
```

NOTE: Inheriting documentation only works on *instance*, non-constructor methods.

## A Complete Example

```crystal
# A unicorn is a **legendary animal** (see the `Legendary` module) that has been
# described since antiquity as a beast with a large, spiraling horn projecting
# from its forehead.
#
# To create a unicorn:
#
# ```
# unicorn = Unicorn.new
# unicorn.speak
# ```
#
# The above produces:
#
# ```text
# "I'm a unicorn"
# ```
#
# Check the number of horns with `#horns`.
class Unicorn
  include Legendary

  # Creates a unicorn with the specified number of *horns*.
  def initialize(@horns = 1)
    raise "Not a unicorn" if @horns != 1
  end

  # Returns the number of horns this unicorn has
  #
  # ```
  # Unicorn.new.horns # => 1
  # ```
  def horns
    @horns
  end

  # :ditto:
  def number_of_horns
    horns
  end

  # Makes the unicorn speak to STDOUT
  def speak
    puts "I'm a unicorn"
  end

  # :nodoc:
  class Helper
  end
end
```
# Enums

!!! note
    This page is for [Crystal enums](https://crystal-lang.org/api/Enum.html). For C enums, see [C bindings enum](c_bindings/enum.md).

An enum is a set of integer values, where each value has an associated name. For example:

```crystal
enum Color
  Red
  Green
  Blue
end
```

An enum is defined with the `enum` keyword, followed by its name. The enum's body contains the values. Values start with the value `0` and are incremented by one. The default value can be overwritten:

```crystal
enum Color
  Red        # 0
  Green      # 1
  Blue   = 5 # overwritten to 5
  Yellow     # 6 (5 + 1)
end
```

Each constant in the enum has the type of the enum:

```crystal
Color::Red # :: Color
```

To get the underlying value, you invoke `value` on it:

```crystal
Color::Green.value # => 1
```

The type of the value is `Int32` by default, but can be changed:

```crystal
enum Color : UInt8
  Red
  Green
  Blue
end

Color::Red.value # :: UInt8
```

Only integer types are allowed as the underlying type.

All enums inherit from [Enum](https://crystal-lang.org/api/Enum.html).

## Flags enums

An enum can be marked with the `@[Flags]` annotation. This changes the default values:

```crystal
@[Flags]
enum IOMode
  Read  # 1
  Write # 2
  Async # 4
end
```

The `@[Flags]` annotation makes the first constant's value be `1`, and successive constants are multiplied by `2`.

Implicit constants, `None` and `All`, are automatically added to these enums, where `None` has the value `0` and `All` has the "or"ed value of all constants.

```crystal
IOMode::None.value # => 0
IOMode::All.value  # => 7
```

Additionally, some `Enum` methods check the `@[Flags]` annotation. For example:

```crystal
puts(Color::Red)                    # prints "Red"
puts(IOMode::Write | IOMode::Async) # prints "Write, Async"
```

## Enums from integers

An enum can be created from an integer:

```crystal
puts Color.new(1) # => prints "Green"
```

Values that don't correspond to an enum's constants are allowed: the value will still be of type `Color`, but when printed you will get the underlying value:

```crystal
puts Color.new(10) # => prints "10"
```

This method is mainly intended to convert integers from C to enums in Crystal.

## Predicate methods

An enum automatically defines predicate methods for each member, using
`String#underscore` for the method name.

!!! note
    In the case of regular enums, this compares by equality (`==`). In the case of flags enums, this invokes `includes?`.

For example:

```crystal
enum Color
  Red
  Green
  Blue
end

color = Color::Blue
color.red?  # => false
color.blue? # => true

@[Flags]
enum IOMode
  Read
  Write
  Async
end

mode = IOMode::Read | IOMode::Async
mode.read?  # => true
mode.write? # => false
mode.async? # => true
```

## Methods

Just like a class or a struct, you can define methods for enums:

```crystal
enum ButtonSize
  Sm
  Md
  Lg

  def label
    case self
    in .sm? then "small"
    in .md? then "medium"
    in .lg? then "large"
    end
  end
end

ButtonSize::Sm.label # => "small"
ButtonSize::Lg.label # => "large"
```

Class variables are allowed, but instance variables are not.

## Usage

When a method parameter has an enum [type restriction](type_restrictions.md), it accepts either an enum constant or a [symbol](literals/symbol.md). The symbol will be automatically cast to an enum constant, raising a compile-time error if casting fails.

```crystal
def paint(color : Color)
  puts "Painting using the color #{color}"
end

paint Color::Red

paint :red # automatically casts to `Color::Red`

paint :yellow # Error: expected argument #1 to 'paint' to match a member of enum Color
```

The same automatic casting does not apply to case statements. To use enums with case statements, see [case enum values](case.md#enum-values).
# Everything is an object

In Crystal everything is an object. The definition of an object boils down to these points:

* It has a type
* It can respond to some methods

This is everything you can know about an object: its type and whether it responds to some method.

An object's internal state, if any, can only be queried by invoking methods.
# Exception handling

Crystal's way to do error handling is by raising and rescuing exceptions.

## Raising exception

You raise exceptions by invoking a top-level `raise` method. Unlike other keywords, `raise` is a regular method with two overloads: [one accepting a String](https://crystal-lang.org/api/toplevel.html#raise%28exception%3AException%29%3ANoReturn-class-method) and another [accepting an Exception instance](https://crystal-lang.org/api/toplevel.html#raise%28message%3AString%29%3ANoReturn-class-method):

```crystal
raise "OH NO!"
raise Exception.new("Some error")
```

The String version just creates a new [Exception](https://crystal-lang.org/api/Exception.html) instance with that message.

Only `Exception` instances or subclasses can be raised.

## Defining custom exceptions

To define a custom exception type, just subclass from [Exception](https://crystal-lang.org/api/Exception.html):

```crystal
class MyException < Exception
end

class MyOtherException < Exception
end
```

You can, as always, define a constructor for your exception or just use the default one.

## Rescuing exceptions

To rescue any exception use a `begin ... rescue ... end` expression:

```crystal
begin
  raise "OH NO!"
rescue
  puts "Rescued!"
end

# Output: Rescued!
```

To access the rescued exception you can specify a variable in the `rescue` clause:

```crystal
begin
  raise "OH NO!"
rescue ex
  puts ex.message
end

# Output: OH NO!
```

To rescue just one type of exception (or any of its subclasses):

```crystal
begin
  raise MyException.new("OH NO!")
rescue MyException
  puts "Rescued MyException"
end

# Output: Rescued MyException
```

Valid type restrictions are subclasses of `::Exception`, module types and unions of these.

And to access it, use a syntax similar to type restrictions:

```crystal
begin
  raise MyException.new("OH NO!")
rescue ex : MyException
  puts "Rescued MyException: #{ex.message}"
end

# Output: Rescued MyException: OH NO!
```

Multiple `rescue` clauses can be specified:

```crystal
begin
  # ...
rescue ex1 : MyException
  # only MyException...
rescue ex2 : MyOtherException
  # only MyOtherException...
rescue
  # any other kind of exception
end
```

You can also rescue multiple exception types at once by specifying a union type:

```crystal
begin
  # ...
rescue ex : MyException | MyOtherException
  # only MyException or MyOtherException
rescue
  # any other kind of exception
end
```

## else

An `else` clause is executed only if no exceptions were rescued:

```crystal
begin
  something_dangerous
rescue
  # execute this if an exception is raised
else
  # execute this if an exception isn't raised
end
```

An `else` clause can only be specified if at least one `rescue` clause is specified.

## ensure

An `ensure` clause is executed at the end of a `begin ... end` or `begin ... rescue ... end` expression regardless of whether an exception was raised or not:

```crystal
begin
  something_dangerous
ensure
  puts "Cleanup..."
end

# Will print "Cleanup..." after invoking something_dangerous,
# regardless of whether it raised or not
```

Or:

```crystal
begin
  something_dangerous
rescue
  # ...
else
  # ...
ensure
  # this will always be executed
end
```

`ensure` clauses are usually used for clean up, freeing resources, etc.

## Short syntax form

Exception handling has a short syntax form: assume a method or block definition is an implicit `begin ... end` expression, then specify `rescue`, `else`, and `ensure` clauses:

```crystal
def some_method
  something_dangerous
rescue
  # execute if an exception is raised
end

# The above is the same as:
def some_method
  begin
    something_dangerous
  rescue
    # execute if an exception is raised
  end
end
```

With `ensure`:

```crystal
def some_method
  something_dangerous
ensure
  # always execute this
end

# The above is the same as:
def some_method
  begin
    something_dangerous
  ensure
    # always execute this
  end
end

# Similarly, the shorthand also works with blocks:
(1..10).each do |n|
  # potentially dangerous operation


rescue
  # ..
else
  # ..
ensure
  # ..
end
```

## Suffix forms of `rescue` and `ensure`

You can use the suffix form of `rescue` to create one-liner catch-all exception handling. You cannot specify an Exception type to `rescue` when using its suffix form.

```crystal
text = File.read("this_file_may_not_exist") rescue nil
```

This is equal to:

```crystal
text = begin
  File.read("this_file_may_not_exist")
rescue
  nil
end
```

You may also use the suffix form of `ensure` to create one-liner guarantees similar to `rescue`.

```crystal
x ensure y
```

This is equal to:

```crystal
begin
  x
ensure
  y
end
```

## Type inference

Variables declared inside the `begin` part of an exception handler also get the `Nil` type when considered inside a `rescue` or `ensure` body. For example:

```crystal
begin
  a = something_dangerous_that_returns_Int32
ensure
  puts a + 1 # error, undefined method '+' for Nil
end
```

The above happens even if `something_dangerous_that_returns_Int32` never raises, or if `a` was assigned a value and then a method that potentially raises is executed:

```crystal
begin
  a = 1
  something_dangerous
ensure
  puts a + 1 # error, undefined method '+' for Nil
end
```

Although it is obvious that `a` will always be assigned a value, the compiler will still think `a` might never had a chance to be initialized. Even though this logic might improve in the future, right now it forces you to keep your exception handlers to their necessary minimum, making the code's intention more clear:

```crystal
# Clearer than the above: `a` doesn't need
# to be in the exception handling code.
a = 1
begin
  something_dangerous
ensure
  puts a + 1 # works
end
```

## Alternative ways to do error handling

Although exceptions are available as one of the mechanisms for handling errors, they are not your only choice. Raising an exception involves allocating memory, and executing an exception handler is generally slow.

The standard library usually provides a couple of methods to accomplish something: one raises, one returns `nil`. For example:

```crystal
array = [1, 2, 3]
array[4]  # raises because of IndexError
array[4]? # returns nil because of index out of bounds
```

The usual convention is to provide an alternative "question" method to signal that this variant of the method returns `nil` instead of raising. This lets the user choose whether they want to deal with exceptions or with `nil`. Note, however, that this is not available for every method out there, as exceptions are still the preferred way because they don't pollute the code with error handling logic.
# finalize

If a class defines a `finalize` method, when an instance of that class is
garbage-collected that method will be invoked:

```crystal
class Foo
  def finalize
    # Invoked when Foo is garbage-collected
    # Use to release non-managed resources (ie. C libraries, structs)
  end
end
```

Use this method to release resources allocated by external libraries that are
not directly managed by Crystal garbage collector.

Examples of this can be found in [`IO::FileDescriptor#finalize`](https://crystal-lang.org/api/IO/FileDescriptor.html#finalize-instance-method)
or [`OpenSSL::Digest#finalize`](https://crystal-lang.org/api/OpenSSL/Digest.html#finalize-instance-method).

**Notes**:

* The `finalize` method will only be invoked once the object has been
fully initialized via the `initialize` method. If an exception is raised
inside the `initialize` method, `finalize` won't be invoked. If your class
defines a `finalize` method, be sure to catch any exceptions that might be
raised in the `initialize` methods and free resources.

* Allocating any new object instances during garbage-collection might result
in undefined behavior and most likely crashing your program.
# Generics

Generics allow you to parameterize a type based on another type. Generics provide type-polymorphism. Consider a Box type:

```crystal
class MyBox(T)
  def initialize(@value : T)
  end

  def value
    @value
  end
end

int_box = MyBox(Int32).new(1)
int_box.value # => 1 (Int32)

string_box = MyBox(String).new("hello")
string_box.value # => "hello" (String)

another_box = MyBox(String).new(1) # Error, Int32 doesn't match String
```

Generics are especially useful for implementing collection types. `Array`, `Hash`, `Set` are generic types, as is `Pointer`.

More than one type parameter is allowed:

```crystal
class MyDictionary(K, V)
end
```

Any name can be used for type parameters:

```crystal
class MyDictionary(KeyType, ValueType)
end
```

## Generic class methods

Type restrictions in a generic type's class method become free variables when the receiver's type arguments were not specified. Those free variables are then inferred from a call's arguments. For example, one can also write:

```crystal
int_box = MyBox.new(1)          # : MyBox(Int32)
string_box = MyBox.new("hello") # : MyBox(String)
```

In the above code we didn't have to specify the type arguments of `MyBox`, the compiler inferred them following this process:

* The compiler generates a `MyBox.new(value : T)` method, which has no explicitly defined free variables, from `MyBox#initialize(@value : T)`
* The `T` in `MyBox.new(value : T)` isn't bound to a type yet, and `T` is a type parameter of `MyBox`, so the compiler binds it to the type of the given argument
* The compiler-generated `MyBox.new(value : T)` calls `MyBox(T)#initialize(@value : T)`, where `T` is now bound

In this way generic types are less tedious to work with. Note that the `#initialize` method itself does not need to specify any free variables for this to work.

The same type inference also works for class methods other than `.new`:

```crystal
class MyBox(T)
  def self.nilable(x : T)
    MyBox(T?).new(x)
  end
end

MyBox.nilable(1)     # : MyBox(Int32 | Nil)
MyBox.nilable("foo") # : MyBox(String | Nil)
```

In these examples, `T` is only inferred as a free variable, so the `T` of the receiver itself remains unbound. Thus it is an error to call other class methods where `T` cannot be inferred:

```crystal
module Foo(T)
  def self.foo
    T
  end

  def self.foo(x : T)
    foo
  end
end

Foo.foo(1)        # Error: can't infer the type parameter T for the generic module Foo(T). Please provide it explicitly
Foo(Int32).foo(1) # OK
```

## Generic structs and modules

Structs and modules can be generic too. When a module is generic you include it like this:

```crystal
module Moo(T)
  def t
    T
  end
end

class Foo(U)
  include Moo(U)

  def initialize(@value : U)
  end
end

foo = Foo.new(1)
foo.t # Int32
```

Note that in the above example `T` becomes `Int32` because `Foo.new(1)` makes `U` become `Int32`, which in turn makes `T` become `Int32` via the inclusion of the generic module.

## Generic types inheritance

Generic classes and structs can be inherited. When inheriting you can specify an instance of the generic type, or delegate type variables:

```crystal
class Parent(T)
end

class Int32Child < Parent(Int32)
end

class GenericChild(T) < Parent(T)
end
```

## Generics with variable number of arguments

We may define a Generic class with a variable number of arguments using the [splat operator](./operators.md#splats).

Let's see an example where we define a Generic class called `Foo` and then we will use it with different number of type variables:

```crystal-play
class Foo(*T)
  getter content

  def initialize(*@content : *T)
  end
end

# 2 type variables:
# (explicitly specifying type variables)
foo = Foo(Int32, String).new(42, "Life, the Universe, and Everything")

p typeof(foo) # => Foo(Int32, String)
p foo.content # => {42, "Life, the Universe, and Everything"}

# 3 type variables:
# (type variables inferred by the compiler)
bar = Foo.new("Hello", ["Crystal", "!"], 140)
p typeof(bar) # => Foo(String, Array(String), Int32)
```

In the following example we define classes by inheritance, specifying instances for the generic types:

```crystal
class Parent(*T)
end

# We define `StringChild` inheriting from `Parent` class
# using `String` for generic type argument:
class StringChild < Parent(String)
end

# We define `Int32StringChild` inheriting from `Parent` class
# using `Int32` and `String` for generic type arguments:
class Int32StringChild < Parent(Int32, String)
end
```

And if we need to instantiate a `class` with 0 arguments? In that case we may do:

```crystal-play
class Parent(*T)
end

foo = Parent().new
p typeof(foo) # => Parent()
```

But we should not mistake 0 arguments with not specifying the generic type variables. The following examples will raise an error:

```crystal
class Parent(*T)
end

foo = Parent.new # Error: can't infer the type parameter T for the generic class Parent(*T). Please provide it explicitly

class Foo < Parent # Error: generic type arguments must be specified when inheriting Parent(*T)
end
```
# if

An `if` evaluates the given branch if its condition is *truthy*. Otherwise, it
evaluates the `else` branch if present.

```crystal
a = 1
if a > 0
  a = 10
end
a # => 10

b = 1
if b > 2
  b = 10
else
  b = 20
end
b # => 20
```

To write a chain of if-else-if you use `elsif`:

```crystal
if some_condition
  do_something
elsif some_other_condition
  do_something_else
else
  do_that
end
```

After an `if`, a variable’s type depends on the type of the expressions used in both branches.

```crystal
a = 1
if some_condition
  a = "hello"
else
  a = true
end
# a : String | Bool

b = 1
if some_condition
  b = "hello"
end
# b : Int32 | String

if some_condition
  c = 1
else
  c = "hello"
end
# c : Int32 | String

if some_condition
  d = 1
end
# d : Int32 | Nil
```

Note that if a variable is declared inside one of the branches but not in the other one, at the end of the `if` it will also contain the `Nil` type.

Inside an `if`'s branch the type of a variable is the one it got assigned in that branch, or the one that it had before the branch if it was not reassigned:

```crystal
a = 1
if some_condition
  a = "hello"
  # a : String
  a.size
end
# a : String | Int32
```

That is, a variable’s type is the type of the last expression(s) assigned to it.

If one of the branches never reaches past the end of an `if`, like in the case of a `return`, `next`, `break` or `raise`, that type is not considered at the end of the `if`:

```crystal
if some_condition
  e = 1
else
  e = "hello"
  # e : String
  return
end
# e : Int32
```
# if var

If a variable is the condition of an `if`, inside the `then` branch the variable will be considered as not having the `Nil` type:

```crystal
a = some_condition ? nil : 3
# a is Int32 or Nil

if a
  # Since the only way to get here is if a is truthy,
  # a can't be nil. So here a is Int32.
  a.abs
end
```

This also applies when a variable is assigned in an `if`'s condition:

```crystal
if a = some_expression
  # here a is not nil
end
```

This logic also applies if there are ands (`&&`) in the condition:

```crystal
if a && b
  # here both a and b are guaranteed not to be Nil
end
```

Here, the right-hand side of the `&&` expression is also guaranteed to have `a` as not `Nil`.

Of course, reassigning a variable inside the `then` branch makes that variable have a new type based on the expression assigned.

## Limitations

The above logic works **only for local variables**. It doesn’t work with instance variables, class variables, or variables bound in a closure. The value of these kinds of variables could potentially be affected by another fiber after the condition was checked, rendering it `nil`. It also does not work with constants.

```crystal
if @a
  # here `@a` can be nil
end

if @@a
  # here `@@a` can be nil
end

a = nil
closure = -> { a = "foo" }

if a
  # here `a` can be nil
end
```

This can be circumvented by assigning the value to a new local variable:

```crystal
if a = @a
  # here `a` can't be nil
end
```

Another option is to use [`Object#try`](https://crystal-lang.org/api/Object.html#try%28%26block%29-instance-method) found in the standard library which only executes the block if the value is not `nil`:

```crystal
@a.try do |a|
  # here `a` can't be nil
end
```

## Method calls

That logic also doesn't work with proc and method calls, including getters and properties, because nilable (or, more generally, union-typed) procs and methods aren't guaranteed to return the same more-specific type on two successive calls.

```crystal
if method # first call to a method that can return Int32 or Nil
  # here we know that the first call did not return Nil
  method # second call can still return Int32 or Nil
end
```

The techniques described above for instance variables will also work for proc and method calls.
# if var.nil?

If an `if`'s condition is `var.nil?` then the type of `var` in the `then` branch is known by the compiler to be `Nil`, and to be known as non-`Nil` in the `else` branch:

```crystal
a = some_condition ? nil : 3
if a.nil?
  # here a is Nil
else
  # here a is Int32
end
```

## Instance Variables

Type restriction through `if var.nil?` only occurs with local variables. The type of an instance variable in a similar code example to the one above will still be nilable and will throw a compile error since `greet` expects a `String` in the `unless` branch.

```crystal
class Person
  property name : String?

  def greet
    unless @name.nil?
      puts "Hello, #{@name.upcase}" # Error: undefined method 'upcase' for Nil (compile-time type is (String | Nil))
    else
      puts "Hello"
    end
  end
end

Person.new.greet
```

You can solve this by storing the value in a local variable first:

```crystal
def greet
  name = @name
  unless name.nil?
    puts "Hello, #{name.upcase}" # name will be String - no compile error
  else
    puts "Hello"
  end
end
```

This is a byproduct of multi-threading in Crystal. Due to the existence of Fibers, Crystal does not know at compile-time whether the instance variable will still be non-`Nil` when the usage in the `if` branch is reached.
# if var.is_a?(...)

If an `if`'s condition is an `is_a?` test, the type of a variable is guaranteed to be restricted by that type in the `then` branch.

```crystal
if a.is_a?(String)
  # here a is a String
end

if b.is_a?(Number)
  # here b is a Number
end
```

Additionally, in the `else` branch the type of the variable is guaranteed to not be restricted by that type:

```crystal
a = some_condition ? 1 : "hello"
# a : Int32 | String

if a.is_a?(Number)
  # a : Int32
else
  # a : String
end
```

Note that you can use any type as an `is_a?` test, like abstract classes and modules.

The above also works if there are ands (`&&`) in the condition:

```crystal
if a.is_a?(String) && b.is_a?(Number)
  # here a is a String and b is a Number
end
```

The above **doesn’t** work with instance variables or class variables. To work with these, first assign them to a variable:

```crystal
if @a.is_a?(String)
  # here @a is not guaranteed to be a String
end

a = @a
if a.is_a?(String)
  # here a is guaranteed to be a String
end

# A bit shorter:
if (a = @a).is_a?(String)
  # here a is guaranteed to be a String
end
```
# if var.responds_to?(...)

If an `if`'s condition is a `responds_to?` test, in the `then` branch the type of a variable is guaranteed to be restricted to the types that respond to that method:

```crystal
if a.responds_to?(:abs)
  # here a's type will be reduced to those responding to the 'abs' method
end
```

Additionally, in the `else` branch the type of the variable is guaranteed to be restricted to the types that don’t respond to that method:

```crystal
a = some_condition ? 1 : "hello"
# a : Int32 | String

if a.responds_to?(:abs)
  # here a will be Int32, since Int32#abs exists but String#abs doesn't
else
  # here a will be String
end
```

The above **doesn’t** work with instance variables or class variables. To work with these, first assign them to a variable:

```crystal
if @a.responds_to?(:abs)
  # here @a is not guaranteed to respond to `abs`
end

a = @a
if a.responds_to?(:abs)
  # here a is guaranteed to respond to `abs`
end

# A bit shorter:
if (a = @a).responds_to?(:abs)
  # here a is guaranteed to respond to `abs`
end
```
# Inheritance

Every class except `Object`, the hierarchy root, inherits from another class (its superclass). If you don't specify one it defaults to `Reference` for classes and `Struct` for structs.

A class inherits all instance variables and all instance and class methods of a superclass, including its constructors (`new` and `initialize`).

```crystal
class Person
  def initialize(@name : String)
  end

  def greet
    puts "Hi, I'm #{@name}"
  end
end

class Employee < Person
end

employee = Employee.new "John"
employee.greet # "Hi, I'm John"
```

If a class defines a `new` or `initialize` then its superclass constructors are not inherited:

```crystal
class Person
  def initialize(@name : String)
  end
end

class Employee < Person
  def initialize(@name : String, @company_name : String)
  end
end

Employee.new "John", "Acme" # OK
Employee.new "Peter"        # Error: wrong number of arguments for 'Employee:Class#new' (1 for 2)
```

You can override methods in a derived class:

```crystal
class Person
  def greet(msg)
    puts "Hi, #{msg}"
  end
end

class Employee < Person
  def greet(msg)
    puts "Hello, #{msg}"
  end
end

p = Person.new
p.greet "everyone" # "Hi, everyone"

e = Employee.new
e.greet "everyone" # "Hello, everyone"
```

Instead of overriding you can define specialized methods by using type restrictions:

```crystal
class Person
  def greet(msg)
    puts "Hi, #{msg}"
  end
end

class Employee < Person
  def greet(msg : Int32)
    puts "Hi, this is a number: #{msg}"
  end
end

e = Employee.new
e.greet "everyone" # "Hi, everyone"

e.greet 1 # "Hi, this is a number: 1"
```

## super

You can invoke a superclass' method using `super`:

```crystal
class Person
  def greet(msg)
    puts "Hello, #{msg}"
  end
end

class Employee < Person
  def greet(msg)
    super # Same as: super(msg)
    super("another message")
  end
end
```

Without arguments or parentheses, `super` receives all of the method's parameters as arguments. Otherwise, it receives the arguments you pass to it.

## Covariance and Contravariance

One place inheritance can get a little tricky is with arrays. We have to be careful when declaring an array of objects where inheritance is used. For example, consider the following

```crystal
class Foo
end

class Bar < Foo
end

foo_arr = [Bar.new] of Foo  # => [#<Bar:0x10215bfe0>] : Array(Foo)
bar_arr = [Bar.new]         # => [#<Bar:0x10215bfd0>] : Array(Bar)
bar_arr2 = [Foo.new] of Bar # compiler error
```

A Foo array can hold both Foo's and Bar's, but an array of Bar can only hold Bar and its subclasses.

One place this might trip you up is when automatic casting comes into play. For example, the following won't work:

```crystal
class Foo
end

class Bar < Foo
end

class Test
  @arr : Array(Foo)

  def initialize
    @arr = [Bar.new]
  end
end
```

we've declared `@arr` as type `Array(Foo)` so we may be tempted to think that we can start putting `Bar`s in there. Not quite. In the `initialize`, the type of the `[Bar.new]` expression is `Array(Bar)`, period. And `Array(Bar)` is *not* assignable to an `Array(Foo)` instance var.

What's the right way to do this? Change the expression so that it *is* of the right type: `Array(Foo)` (see example above).

```crystal
class Foo
end

class Bar < Foo
end

class Test
  @arr : Array(Foo)

  def initialize
    @arr = [Bar.new] of Foo
  end
end
```

This is just one type (Array) and one operation (assignment), the logic of the above will be applied differently for other types and assignments, in general [Covariance and Contravariance][1] is not fully supported.

[1]: https://en.wikipedia.org/wiki/Covariance_and_contravariance_%28computer_science%29
# instance_alignof

The `instance_alignof` expression returns an `Int32` with the instance alignment of a given class.

Unlike [`alignof`](alignof.md) which would return the alignment of the reference
(pointer) to the allocated object, `instance_alignof` returns the alignment of
the allocated object itself.

For example:

```crystal
class Foo
end

class Bar
  def initialize(@x : Int64)
  end
end

instance_alignof(Foo) # => 4
instance_alignof(Bar) # => 8
```

Even though `Foo` has no instance variables, the compiler always includes an extra `Int32` field for the type id of the object. That's why the instance alignment ends up being 4 and not 1.
# instance_sizeof

The `instance_sizeof` expression returns an `Int32` with the instance size of a given class.

Unlike [`sizeof`](sizeof.md) which would return the size of the reference
(pointer) to the allocated object, `instance_sizeof` returns the size of
the allocated object itself.

For example:

```crystal
class Point
  def initialize(@x : Int32, @y : Int32)
  end
end

Point.new 1, 2

# 2 x Int32 = 2 x 4 = 8
instance_sizeof(Point) # => 12
```

Even though the instance has two `Int32` fields, the compiler always includes an extra `Int32` field for the type id of the object. That's why the instance size ends up being 12 and not 8.
# is_a?

The pseudo-method `is_a?` determines whether an expression's runtime type inherits or includes another type. For example:

```crystal
a = 1
a.is_a?(Int32)          # => true
a.is_a?(String)         # => false
a.is_a?(Number)         # => true
a.is_a?(Int32 | String) # => true
```

It is a pseudo-method because the compiler knows about it and it can affect type information, as explained in [if var.is_a?(...)](if_varis_a.md). Also, it accepts a [type](type_grammar.md) that must be known at compile-time as its argument.
# Literals

Crystal provides several literals for creating values of some basic types.

| Literal                                        | Sample values                                           |
|---                                             |---                                                      |
| [Nil](nil.md)                                  | `nil`                                                   |
| [Bool](bool.md)                                | `true`, `false`                                         |
| [Integers](integers.md)                        | `18`, `-12`, `19_i64`, `14_u32`,`64_u8`                 |
| [Floats](floats.md)                            | `1.0`, `1.0_f32`, `1e10`, `-0.5`                        |
| [Char](char.md)                                | `'a'`, `'\n'`, `'あ'`                                   |
| [String](string.md)                            | `"foo\tbar"`, `%("あ")`, `%q(foo #{foo})`               |
| [Symbol](symbol.md)                            | `:symbol`, `:"foo bar"`                                 |
| [Array](array.md)                              | `[1, 2, 3]`, `[1, 2, 3] of Int32`, `%w(one two three)`  |
| [Array-like](array.md#array-like-type-literal) | `Set{1, 2, 3}`                                          |
| [Hash](hash.md)                                | `{"foo" => 2}`, `{} of String => Int32`                 |
| [Hash-like](hash.md#hash-like-type-literal)    | `MyType{"foo" => "bar"}`                                |
| [Range](range.md)                              | `1..9`, `1...10`, `0..var`                              |
| [Regex](regex.md)                              | `/(foo)?bar/`, `/foo #{foo}/imx`, `%r(foo/)`            |
| [Tuple](tuple.md)                              | `{1, "hello", 'x'}`                                     |
| [NamedTuple](named_tuple.md)                   | `{name: "Crystal", year: 2011}`, `{"this is a key": 1}` |
| [Proc](proc.md)                                | `->(x : Int32, y : Int32) { x + y }`                    |
| [Command](command.md)                          | `` `echo foo` ``, `%x(echo foo)`                        |
# Array

An [Array](https://crystal-lang.org/api/Array.html) is an ordered and integer-indexed generic collection of elements of a specific type `T`.

Arrays are typically created with an array literal denoted by square brackets (`[]`) and individual elements separated by a comma (`,`).

```crystal
[1, 2, 3]
```

## Generic Type Argument

The array's generic type argument `T` is inferred from the types of the elements inside the literal. When all elements of the array have the same type, `T` equals to that. Otherwise it will be a union of all element types.

```crystal
[1, 2, 3]         # => Array(Int32)
[1, "hello", 'x'] # => Array(Int32 | String | Char)
```

An explicit type can be specified by immediately following the closing bracket with `of` and a type. This overwrites the inferred type and can be used for example to create an array that holds only some types initially but can accept other types later.

```crystal
array_of_numbers = [1, 2, 3] of Float64 | Int32 # => Array(Float64 | Int32)
array_of_numbers << 0.5                         # => [1, 2, 3, 0.5]

array_of_int_or_string = [1, 2, 3] of Int32 | String # => Array(Int32 | String)
array_of_int_or_string << "foo"                      # => [1, 2, 3, "foo"]
```

Empty array literals always need a type specification:

```crystal
[] of Int32 # => Array(Int32).new
```

## Percent Array Literals

[Arrays of strings](./string.md#percent-string-array-literal) and [arrays of symbols](./symbol.md#percent-symbol-array-literal) can be created with percent array literals:

```crystal
%w(one two three) # => ["one", "two", "three"]
%i(one two three) # => [:one, :two, :three]
```

## Array-like Type Literal

Crystal supports an additional literal for arrays and array-like types. It consists of the name of the type followed by a list of elements enclosed in curly braces (`{}`) and individual elements separated by a comma (`,`).

```crystal
Array{1, 2, 3}
```

This literal can be used with any type as long as it has an argless constructor and responds to `<<`.

```crystal
IO::Memory{1, 2, 3}
Set{1, 2, 3}
```

For a non-generic type like `IO::Memory`, this is equivalent to:

```crystal
array_like = IO::Memory.new
array_like << 1
array_like << 2
array_like << 3
```

For a generic type like `Set`, the generic type `T` is inferred from the types of the elements in the same way as with the array literal. The above is equivalent to:

```crystal
array_like = Set(typeof(1, 2, 3)).new
array_like << 1
array_like << 2
array_like << 3
```

The type arguments can be explicitly specified as part of the type name:

```crystal
Set(Int32){1, 2, 3}
```

## Splat Expansion

The splat operator can be used inside array and array-like literals to insert multiple values at once.

```crystal
[1, *coll, 2, 3]
Set{1, *coll, 2, 3}
```

The only requirement is that `coll`'s type must include [`Enumerable`](https://crystal-lang.org/api/Enumerable.html). The above is equivalent to:

```crystal
array = Array(typeof(...)).new
array << 1
array.concat(coll)
array << 2
array << 3

array_like = Set(typeof(...)).new
array_like << 1
coll.each do |elem|
  array_like << elem
end
array_like << 2
array_like << 3
```

In these cases, the generic type argument is additionally inferred using `coll`'s elements.
# Bool

[Bool](https://crystal-lang.org/api/Bool.html) has only two possible values: `true` and `false`. They are constructed using the following literals:

```crystal
true  # A Bool that is true
false # A Bool that is false
```
# Char

A [Char](https://crystal-lang.org/api/Char.html) represents a 32-bit [Unicode](http://en.wikipedia.org/wiki/Unicode) [code point](http://en.wikipedia.org/wiki/Code_point).

It is typically created with a char literal by enclosing an UTF-8 character in single quotes.

```crystal
'a'
'z'
'0'
'_'
'あ'
```

A backslash denotes a special character, which can either be a named escape sequence or a numerical representation of a unicode codepoint.

Available escape sequences:

```crystal
'\''         # single quote
'\\'         # backslash
'\a'         # alert
'\b'         # backspace
'\e'         # escape
'\f'         # form feed
'\n'         # newline
'\r'         # carriage return
'\t'         # tab
'\v'         # vertical tab
'\0'         # null character
'\uFFFF'     # hexadecimal unicode character
'\u{10FFFF}' # hexadecimal unicode character
```

A backslash followed by a `u` denotes a unicode codepoint. It can either be followed by exactly four hexadecimal characters representing the unicode bytes (`\u0000` to `\uFFFF`) or a number of one to six hexadecimal characters wrapped in curly braces (`\u{0}` to `\u{10FFFF}`.

```crystal
'\u0041'    # => 'A'
'\u{41}'    # => 'A'
'\u{1F52E}' # => '&#x1F52E;'
```
# Command literal

A command literal is a string delimited by backticks `` ` `` or a `%x` percent literal.
It will be substituted at runtime by the captured output from executing the string in a subshell.

The same [escaping](./string.md#escaping) and [interpolation rules](./string.md#interpolation) apply as for regular strings.

Similar to percent string literals, valid delimiters for `%x` are parentheses `()`, square brackets `[]`, curly braces `{}`, angles `<>` and pipes `||`. Except for the pipes, all delimiters can be nested; meaning a start delimiter inside the string escapes the next end delimiter.

The special variable `$?` holds the exit status of the command as a [`Process::Status`](https://crystal-lang.org/api/Process/Status.html). It is only available in the same scope as the command literal.

```crystal
`echo foo`  # => "foo"
$?.success? # => true
```

Internally, the compiler rewrites command literals to calls to the top-level method [`` `()``](https://crystal-lang.org/api/toplevel.html#%60(command):String-class-method) with a string literal containing the command as argument: `` `echo #{argument}` `` and `%x(echo #{argument})` are rewritten to `` `("echo #{argument}")``.

## Security concerns

While command literals may prove useful for simple script-like tools, special caution is advised when interpolating user input because it may easily lead to command injection.

```crystal
user_input = "hello; rm -rf *"
`echo #{user_input}`
```

This command will write `hello` and subsequently delete all files and folders in the current working directory.

To avoid this, command literals should generally not be used with interpolated user input. [`Process`](https://crystal-lang.org/api/Process.html) from the standard library offers a safe way to provide user input as command arguments:

```crystal
user_input = "hello; rm -rf *"
process = Process.new("echo", [user_input], output: Process::Redirect::Pipe)
process.output.gets_to_end # => "hello; rm -rf *"
process.wait.success?      # => true
```
# Floats

There are two floating point types, [Float32](https://crystal-lang.org/api/Float32.html) and [Float64](https://crystal-lang.org/api/Float64.html),
which correspond to the [binary32](http://en.wikipedia.org/wiki/Single_precision_floating-point_format)
and [binary64](http://en.wikipedia.org/wiki/Double_precision_floating-point_format)
types defined by IEEE.

A floating point literal is an optional `+` or `-` sign, followed by
a sequence of numbers or underscores, followed by a dot,
followed by numbers or underscores, followed by an optional exponent suffix,
followed by an optional type suffix. If no suffix is present, the literal's type is `Float64`.

```crystal
1.0     # Float64
1.0_f32 # Float32
1_f32   # Float32

1e10   # Float64
1.5e10 # Float64
1.5e-7 # Float64

+1.3 # Float64
-0.5 # Float64
```

The underscore `_` before the suffix is optional.

Underscores can be used to make some numbers more readable:

```crystal
1_000_000.111_111 # a lot more readable than 1000000.111111, yet functionally the same
```
# Hash

A [Hash](https://crystal-lang.org/api/Hash.html) is a generic collection of key-value pairs mapping keys of type `K` to values of type `V`.

Hashes are typically created with a hash literal denoted by curly braces (`{ }`) enclosing a list of pairs using `=>` as delimiter between key and value and separated by commas `,`.

```crystal
{"one" => 1, "two" => 2}
```

## Generic Type Argument

The generic type arguments for keys `K` and values `V` are inferred from the types of the keys or values inside the literal, respectively. When all have the same type, `K`/`V` equals to that. Otherwise it will be a union of all key types or value types respectively.

```crystal
{1 => 2, 3 => 4}   # Hash(Int32, Int32)
{1 => 2, 'a' => 3} # Hash(Int32 | Char, Int32)
```

Explicit types can be specified by immediately following the closing bracket with `of` (separated by whitespace), a key type (`K`) followed by `=>` as delimiter and a value type (`V`). This overwrites the inferred types and can be used for example to create a hash that holds only some types initially but can accept other types as well.

Empty hash literals always need type specifications:

```crystal
{} of Int32 => Int32 # => Hash(Int32, Int32).new
```

## Hash-like Type Literal

Crystal supports an additional literal for hashes and hash-like types. It consists of the name of the type followed by a list of  comma separated key-value pairs enclosed in curly braces (`{}`).

```crystal
Hash{"one" => 1, "two" => 2}
```

This literal can be used with any type as long as it has an argless constructor and responds to `[]=`.

```crystal
HTTP::Headers{"foo" => "bar"}
```

For a non-generic type like `HTTP::Headers`, this is equivalent to:

```crystal
headers = HTTP::Headers.new
headers["foo"] = "bar"
```

For a generic type, the generic types are inferred from the types of the keys and values in the same way as with the hash literal.

```crystal
MyHash{"foo" => 1, "bar" => "baz"}
```

If `MyHash` is generic, the above is equivalent to this:

```crystal
my_hash = MyHash(typeof("foo", "bar"), typeof(1, "baz")).new
my_hash["foo"] = 1
my_hash["bar"] = "baz"
```

The type arguments can be explicitly specified as part of the type name:

```crystal
MyHash(String, String | Int32){"foo" => "bar"}
```
# Integers

There are five signed integer types, and five unsigned integer types:

| Type | Length  | Minimum Value | Maximum Value |
| ---------- | -----------: | -----------: |-----------: |
| [Int8](http://crystal-lang.org/api/Int8.html)  | 8       | -128 | 127 |
| [Int16](http://crystal-lang.org/api/Int16.html)  | 16 | −32,768 | 32,767 |
| [Int32](http://crystal-lang.org/api/Int32.html) | 32  | −2,147,483,648 | 2,147,483,647 |
| [Int64](http://crystal-lang.org/api/Int64.html)   |  64 | −2<sup>63</sup> | 2<sup>63</sup> - 1 |
| [Int128](https://crystal-lang.org/api/Int128.html) | 128 | −2<sup>127</sup> | 2<sup>127</sup> - 1 |
| [UInt8](http://crystal-lang.org/api/UInt8.html) | 8 |  0 | 255 |
| [UInt16](http://crystal-lang.org/api/UInt16.html) | 16 | 0 | 65,535 |
| [UInt32](http://crystal-lang.org/api/UInt32.html) | 32 |  0 | 4,294,967,295 |
| [UInt64](http://crystal-lang.org/api/UInt64.html) | 64 | 0 | 2<sup>64</sup> - 1 |
| [UInt128](https://crystal-lang.org/api/UInt128.html) | 128 | 0 | 2<sup>128</sup> - 1 |

An integer literal is an optional `+` or `-` sign, followed by
a sequence of digits and underscores, optionally followed by a suffix.
If no suffix is present, the literal's type is `Int32` if the value fits into `Int32`'s range,
and `Int64` otherwise. Integers outside `Int64`'s range must always be suffixed:

```crystal
1 # Int32

1_i8   # Int8
1_i16  # Int16
1_i32  # Int32
1_i64  # Int64
1_i128 # Int128

1_u8   # UInt8
1_u16  # UInt16
1_u32  # UInt32
1_u64  # UInt64
1_u128 # UInt128

+10 # Int32
-20 # Int32

2147483647  # Int32
2147483648  # Int64
-2147483648 # Int32
-2147483649 # Int64

9223372036854775807     # Int64
9223372036854775808_u64 # UInt64
```

Suffix-less integer literals larger than `Int64`'s maximum value but representable within
`UInt64`'s range are deprecated, e.g. `9223372036854775808`.

The underscore `_` before the suffix is optional.

Underscores can be used to make some numbers more readable:

```crystal
1_000_000 # better than 1000000
```

Binary numbers start with `0b`:

```crystal
0b1101 # == 13
```

Octal numbers start with a `0o`:

```crystal
0o123 # == 83
```

Hexadecimal numbers start with `0x`:

```crystal
0xFE012D # == 16646445
0xfe012d # == 16646445
```
# NamedTuple

A [NamedTuple](https://crystal-lang.org/api/NamedTuple.html) is typically created with a named tuple literal:

```crystal
tuple = {name: "Crystal", year: 2011} # NamedTuple(name: String, year: Int32)
tuple[:name]                          # => "Crystal" (String)
tuple[:year]                          # => 2011      (Int32)
```

To denote a named tuple type you can write:

```crystal
# The type denoting a named tuple of x: Int32, y: String
NamedTuple(x: Int32, y: String)
```

In type restrictions, generic type arguments and other places where a type is expected, you can use a shorter syntax, as explained in the [type grammar](../type_grammar.md):

```crystal
# An array of named tuples of x: Int32, y: String
Array({x: Int32, y: String})
```

A named tuple key can also be a string literal:

```crystal
{"this is a key": 1}
```
# Nil

The [Nil](https://crystal-lang.org/api/Nil.html) type is used to represent the absence of a value, similar to `null` in other languages. It only has a single value:

```crystal
nil
```
# Proc

A [Proc](https://crystal-lang.org/api/Proc.html) represents a function pointer with an optional context (the closure data). It is typically created with a proc literal:

```crystal
# A proc without parameters
-> { 1 } # Proc(Int32)

# A proc with one parameter
->(x : Int32) { x.to_s } # Proc(Int32, String)

# A proc with two parameters
->(x : Int32, y : Int32) { x + y } # Proc(Int32, Int32, Int32)
```

The types of the parameters are mandatory, except when directly sending a proc literal to a lib `fun` in C bindings.

The return type is inferred from the proc's body, but can also be provided explicitly:

```
# A proc returning an Int32 or String
-> : Int32 | String { 1 } # Proc(Int32 | String)

# A proc with one parameter and returning Nil
->(x : Array(String)) : Nil { x.delete("foo") } # Proc(Array(String), Nil)

# The return type must match the proc's body
->(x : Int32) : Bool { x.to_s } # Error: expected Proc to return Bool, not String
```

A `new` method is provided too, which creates a `Proc` from a [captured block](../capturing_blocks.md). This form is mainly useful with [aliases](../alias.md):

```crystal
Proc(Int32, String).new { |x| x.to_s } # Proc(Int32, String)

alias Foo = Int32 -> String
Foo.new { |x| x.to_s } # same proc as above
```

## The Proc type

To denote a Proc type you can write:

```crystal
# A Proc accepting a single Int32 argument and returning a String
Proc(Int32, String)

# A proc accepting no arguments and returning Nil
Proc(Nil)

# A proc accepting two arguments (one Int32 and one String) and returning a Char
Proc(Int32, String, Char)
```

In type restrictions, generic type arguments and other places where a type is expected, you can use a shorter syntax, as explained in the [type](../type_grammar.md):

```crystal
# An array of Proc(Int32, String, Char)
Array(Int32, String -> Char)
```

## Invoking

To invoke a Proc, you invoke the `call` method on it. The number of arguments must match the proc's type:

```crystal
proc = ->(x : Int32, y : Int32) { x + y }
proc.call(1, 2) # => 3
```

## From methods

A Proc can be created from an existing method:

```crystal
def one
  1
end

proc = ->one
proc.call # => 1
```

If the method has parameters, you must specify their types:

```crystal
def plus_one(x)
  x + 1
end

proc = ->plus_one(Int32)
proc.call(41) # => 42
```

A proc can optionally specify a receiver:

```crystal
str = "hello"
proc = ->str.count(Char)
proc.call('e') # => 1
proc.call('l') # => 2
```
# Range

A [Range](https://crystal-lang.org/api/Range.html) represents an interval between two values. It is typically constructed with a range literal, consisting of two or three dots:

* `x..y`: Two dots denote an inclusive range, including `x` and `y` and all values in between (in mathematics: `[x, y]`) .
* `x...y`: Three dots denote an exclusive range, including `x` and all values up to but not including `y` (in mathematics: `[x, y)`).

```crystal
(0..5).to_a  # => [0, 1, 2, 3, 4, 5]
(0...5).to_a # => [0, 1, 2, 3, 4]
```

NOTE:
Range literals are often wrapped in parentheses, for example if it is meant to be used as the receiver of a call. `0..5.to_a` without parentheses would be semantically equivalent to `0..(5.to_a)` because method calls and other operators have higher precedence than the range literal.

An easy way to remember which one is inclusive and which one is exclusive it to think of the extra dot as if it pushes *y* further away, thus leaving it outside of the range.

The literal `x..y` is semantically equivalent to the explicit constructor `Range.new(x, y)` and `x...y` to `Range.new(x, y, true)`.

The begin and end values do not necessarily need to be of the same type: `true..1` is a valid range, although pretty useless since `Enumerable` methods won't work with incompatible types. They need at least to be comparable.

Ranges that begin with `nil` are called begin-less ranges, while ranges that end with `nil` are called end-less ranges. In the literal notation, `nil` can be omitted: `x..` is an end-less range starting from `x`, and `..x` is an begin-less range ending at `x`.

```crystal
numbers = [1, 10, 3, 4, 5, 8]
numbers.select(6..) # => [10, 8]
numbers.select(..6) # => [1, 3, 4, 5]

numbers[2..] = [3, 4, 5, 8]
numbers[..2] = [1, 10, 3]
```

A range that is both begin-less and end-less is valid and can be expressed as `..` or `...` but it's typically not very useful.
# Regular Expressions

Regular expressions are represented by the [Regex](https://crystal-lang.org/api/Regex.html) class.

A Regex is typically created with a regex literal using [PCRE2](http://pcre.org/pcre2.txt) syntax. It consists of a string of UTF-8 characters enclosed in forward slashes (`/`):

```crystal
/foo|bar/
/h(e+)llo/
/\d+/
/あ/
```

> NOTE: Prior to Crystal 1.8 the compiler expected regex literals to follow the original [PCRE pattern syntax](https://www.pcre.org/original/doc/html/pcrepattern.html).
> The newer [PCRE2 pattern syntax](https://www.pcre.org/current/doc/html/pcre2syntax.html) was [introduced in 1.8](https://crystal-lang.org/2023/03/02/crystal-is-upgrading-its-regex-engine/).

## Escaping

Regular expressions support the same [escape sequences as String literals](./string.md).

```crystal
/\//         # slash
/\\/         # backslash
/\b/         # backspace
/\e/         # escape
/\f/         # form feed
/\n/         # newline
/\r/         # carriage return
/\t/         # tab
/\v/         # vertical tab
/\N88/       # octal ASCII character
/\xFF/       # hexadecimal ASCII character
/\x{FFFF}/   # hexadecimal unicode character
/\x{10FFFF}/ # hexadecimal unicode character
```

The delimiter character `/` must be escaped inside slash-delimited regular expression literals.
Note that special characters of the PCRE syntax need to be escaped if they are intended as literal characters.

## Interpolation

Interpolation works in regular expression literals just as it does in [string literals](./string.md). Be aware that using this feature will cause an exception to be raised at runtime, if the resulting string results in an invalid regular expression.

## Modifiers

The closing delimiter may be followed by a number of optional modifiers to adjust the matching behaviour of the regular expression.

* `i`: case-insensitive matching (`PCRE_CASELESS`):  Unicode letters in the pattern match both upper and lower case letters in the subject string.
* `m`: multiline matching (`PCRE_MULTILINE`): The *start of line* (`^`) and *end of line* (`$`) metacharacters match immediately following or immediately before internal newlines in the subject string, respectively, as well as at the very start and end.
* `x`: extended whitespace matching (`PCRE_EXTENDED`): Most white space characters in the pattern are totally ignored except when ignore or inside a character class. Unescaped hash characters `#` denote the start of a comment ranging to the end of the line.

```crystal
/foo/i.match("FOO")         # => #<Regex::MatchData "FOO">
/foo/m.match("bar\nfoo")    # => #<Regex::MatchData "foo">
/foo /x.match("foo")        # => #<Regex::MatchData "foo">
/foo /imx.match("bar\nFOO") # => #<Regex::MatchData "FOO">
```

## Percent regex literals

Besides slash-delimited literals, regular expressions may also be expressed as a percent literal indicated by `%r` and a pair of delimiters. Valid delimiters are parentheses `()`, square brackets `[]`, curly braces `{}`, angles `<>` and pipes `||`. Except for the pipes, all delimiters can be nested; meaning a start delimiter inside the literal escapes the next end delimiter.

These are handy to write regular expressions that include slashes which would have to be escaped in slash-delimited literals.

```crystal
%r((/)) # => /(\/)/
%r[[/]] # => /[\/]/
%r{{/}} # => /{\/}/
%r<</>> # => /<\/>/
%r|/|   # => /\//
```
# String

A [String](https://crystal-lang.org/api/String.html) represents an immutable sequence of UTF-8 characters.

A String is typically created with a string literal enclosing UTF-8 characters in double quotes (`"`):

```crystal
"hello world"
```

## Escaping

A backslash denotes a special character inside a string, which can either be a named escape sequence or a numerical representation of a unicode codepoint.

Available escape sequences:

```crystal
"\""                  # double quote
"\\"                  # backslash
"\#"                  # hash character (to escape interpolation)
"\a"                  # alert
"\b"                  # backspace
"\e"                  # escape
"\f"                  # form feed
"\n"                  # newline
"\r"                  # carriage return
"\t"                  # tab
"\v"                  # vertical tab
"\377"                # octal ASCII character
"\xFF"                # hexadecimal ASCII character
"\uFFFF"              # hexadecimal unicode character
"\u{0}".."\u{10FFFF}" # hexadecimal unicode character
```

Any other character following a backslash is interpreted as the character itself.

A backslash followed by at most three digits ranging from 0 to 7 denotes a code point written in octal:

```crystal
"\101" # => "A"
"\123" # => "S"
"\12"  # => "\n"
"\1"   # string with one character with code point 1
```

A backslash followed by a `u` denotes a unicode codepoint. It can either be followed by exactly four hexadecimal characters representing the unicode bytes (`\u0000` to `\uFFFF`) or a number of one to six hexadecimal characters wrapped in curly braces (`\u{0}` to `\u{10FFFF}`.

```crystal
"\u0041"    # => "A"
"\u{41}"    # => "A"
"\u{1F52E}" # => "&#x1F52E;"
```

One curly brace can contain multiple unicode characters each separated by a whitespace.

```crystal
"\u{48 45 4C 4C 4F}" # => "HELLO"
```

## Interpolation

A string literal with interpolation allows to embed expressions into the string which will be expanded at runtime.

```crystal
a = 1
b = 2
"sum: #{a} + #{b} = #{a + b}" # => "sum: 1 + 2 = 3"
```

String interpolation is also possible with [String#%](https://crystal-lang.org/api/String.html#%25%28other%29-instance-method).

Any expression may be placed inside the interpolated section, but it’s best to keep the expression small for readability.

Interpolation can be disabled by escaping the hash character (`#`) with a backslash or by using a non-interpolating string literal like `%q()`.

```crystal
"\#{a + b}"  # => "#{a + b}"
%q(#{a + b}) # => "#{a + b}"
```

Interpolation is implemented using a [String::Builder](https://crystal-lang.org/api/String/Builder.html) and invoking `Object#to_s(IO)` on each expression enclosed by `#{...}`. The expression `"sum: #{a} + #{b} = #{a + b}"` is equivalent to:

```crystal
String.build do |io|
  io << "sum: "
  io << a
  io << " + "
  io << b
  io << " = "
  io << a + b
end
```

## Percent string literals

Besides double-quotes strings, Crystal also supports string literals indicated by a percent sign (`%`) and a pair of delimiters. Valid delimiters are parentheses `()`, square brackets `[]`, curly braces `{}`, angles `<>` and pipes `||`. Except for the pipes, all delimiters can be nested meaning a start delimiter inside the string escapes the next end delimiter.

These are handy to write strings that include double quotes which would have to be escaped in double-quoted strings.

```crystal
%(hello ("world")) # => "hello (\"world\")"
%[hello ["world"]] # => "hello [\"world\"]"
%{hello {"world"}} # => "hello {\"world\"}"
%<hello <"world">> # => "hello <\"world\">"
%|hello "world"|   # => "hello \"world\""
```

A literal denoted by `%q` does not apply interpolation nor escapes while `%Q` has the same meaning as `%`.

```crystal
name = "world"
%q(hello \n #{name}) # => "hello \\n \#{name}"
%Q(hello \n #{name}) # => "hello \n world"
```

### Percent string array literal

Besides the single string literal, there is also a percent literal to create an [Array](https://crystal-lang.org/api/Array.html) of strings. It is indicated by `%w` and a pair of delimiters. Valid delimiters are as same as [percent string literals](#percent-string-literals).

```crystal
%w(foo bar baz)  # => ["foo", "bar", "baz"]
%w(foo\nbar baz) # => ["foo\\nbar", "baz"]
%w(foo(bar) baz) # => ["foo(bar)", "baz"]
```

<!-- markdownlint-disable-next-line no-space-in-code -->
Note that literal denoted by `%w` does not apply interpolation nor escapes except spaces. Since strings are separated by a single space character (` `) which must be escaped to use it as a part of a string.

```crystal
%w(foo\ bar baz) # => ["foo bar", "baz"]
```

## Multiline strings

Any string literal can span multiple lines:

```crystal
"hello
      world" # => "hello\n      world"
```

Note that in the above example trailing and leading spaces, as well as newlines,
end up in the resulting string. To avoid this a string can be split into multiple lines
by joining multiple literals with a backslash:

```crystal
"hello " \
"world, " \
"no newlines" # same as "hello world, no newlines"
```

Alternatively, a backslash followed by a newline can be inserted inside the string literal:

```crystal
"hello \
     world, \
     no newlines" # same as "hello world, no newlines"
```

In this case, leading whitespace is not included in the resulting string.

## Heredoc

A *here document* or *heredoc* can be useful for writing strings spanning over multiple lines.
A heredoc is denoted by `<<-` followed by an heredoc identifier which is an alphanumeric sequence starting with a letter (and may include underscores). The heredoc starts in the following line and ends with the next line that contains *only* the heredoc identifier, optionally preceded by whitespace.

```crystal
<<-XML
<parent>
  <child />
</parent>
XML
```

Leading whitespace is removed from the heredoc contents according to the number of whitespace in the last line before the heredoc identifier.

```crystal
<<-STRING # => "Hello\n  world"
  Hello
    world
  STRING

<<-STRING # => "  Hello\n    world"
    Hello
      world
  STRING
```

After the heredoc identifier, and in that same line, anything that follows continues the original expression that came before the heredoc. It's as if the end of the starting heredoc identifier is the end of the string. However, the string contents come in subsequent lines until the ending heredoc idenfitier which must be on its own line.

```crystal
<<-STRING.upcase # => "HELLO"
hello
STRING

def upcase(string)
  string.upcase
end

upcase(<<-STRING) # => "HELLO WORLD"
  Hello World
  STRING
```

If multiple heredocs start in the same line, their bodies are read sequentially:

```crystal
print(<<-FIRST, <<-SECOND) # prints "HelloWorld"
  Hello
  FIRST
  World
  SECOND
```

A heredoc generally allows interpolation and escapes.

To denote a heredoc without interpolation or escapes, the opening heredoc identifier is enclosed in single quotes:

```crystal
<<-'HERE' # => "hello \\n \#{world}"
  hello \n #{world}
  HERE
```
# Symbol

A [Symbol](https://crystal-lang.org/api/Symbol.html) represents a unique name inside the entire source code.

Symbols are interpreted at compile time and cannot be created dynamically. The only way to create a Symbol is by using a symbol literal, denoted by a colon (`:`) followed by an identifier. The identifier may optionally be enclosed in double quotes (`"`).

```crystal
:unquoted_symbol
:"quoted symbol"
:"a" # identical to :a
:あ
```

A double-quoted identifier can contain any unicode character including white spaces and accepts the same escape sequences as a [string literal](./string.md), yet no interpolation.

For an unquoted identifier the same naming rules apply as for methods. It can contain alphanumeric characters, underscore (`_`) or characters with a code point greater than `159`(`0x9F`). It must not start with a number and may end with an exclamation mark (`!`) or question mark (`?`).

```crystal
:question?
:exclamation!
```

All [Crystal operators](../operators.md) can be used as symbol names unquoted:

```crystal
:+
:-
:*
:/
:%
:&
:|
:^
:**
:>>
:<<
:==
:!=
:<
:<=
:>
:>=
:<=>
:===
:[]
:[]?
:[]=
:!
:~
:!~
:=~
```

Internally, symbols are implemented as constants with a numeric value of type `Int32`.

## Percent symbol array literal

Besides the single symbol literal, there is also a percent literal to create an [Array](https://crystal-lang.org/api/Array.html) of symbols. It is indicated by `%i` and a pair of delimiters. Valid delimiters are parentheses `()`, square brackets `[]`, curly braces `{}`, angles `<>` and pipes `||`. Except for the pipes, all delimiters can be nested; meaning a start delimiter inside the string escapes the next end delimiter.

```crystal
%i(foo bar baz)  # => [:foo, :bar, :baz]
%i(foo\nbar baz) # => [:"foo\nbar", :baz]
%i(foo(bar) baz) # => [:"foo(bar)", :baz]
```

Identifiers may contain any unicode characters. Individual symbols are separated by a single space character, which must be escaped to use it as a part of an identifier.

```crystal
%i(foo\ bar baz) # => [:"foo bar", :baz]
```
# Tuple

A [Tuple](https://crystal-lang.org/api/Tuple.html) is typically created with a tuple literal:

```crystal
tuple = {1, "hello", 'x'} # Tuple(Int32, String, Char)
tuple[0]                  # => 1       (Int32)
tuple[1]                  # => "hello" (String)
tuple[2]                  # => 'x'     (Char)
```

To create an empty tuple use [Tuple.new](https://crystal-lang.org/api/Tuple.html#new%28%2Aargs%3A%2AT%29-class-method).

To denote a tuple type you can write:

```crystal
# The type denoting a tuple of Int32, String and Char
Tuple(Int32, String, Char)
```

In type restrictions, generic type arguments and other places where a type is expected, you can use a shorter syntax, as explained in the [type grammar](../type_grammar.md):

```crystal
# An array of tuples of Int32, String and Char
Array({Int32, String, Char})
```

## Splat Expansion

The splat operator can be used inside tuple literals to unpack multiple values at once. The splatted value must be another tuple.

```crystal
tuple = {1, *{"hello", 'x'}, 2} # => {1, "hello", 'x', 2}
typeof(tuple)                   # => Tuple(Int32, String, Char, Int32)

tuple = {3.5, true}
tuple = {*tuple, *tuple} # => {3.5, true, 3.5, true}
typeof(tuple)            # => Tuple(Float64, Bool, Float64, Bool)
```
# Local variables

Local variables start with lowercase letters. They are declared when you first assign them a value.

```crystal
name = "Crystal"
age = 1
```

Their type is inferred from their usage, not only from their initializer. In general, they are just value holders associated with the type that the programmer expects them to have according to their location and usage on the program.

For example, reassigning a variable with a different expression makes it have that expression’s type:

```crystal
flower = "Tulip"
# At this point 'flower' is a String

flower = 1
# At this point 'flower' is an Int32
```

Underscores are allowed at the beginning of a variable name, but these names are reserved for the compiler, so their use is not recommended (and it also makes the code uglier to read).
# Low-level primitives

Some low-level primitives are provided. They are mostly useful for interfacing with C libraries and for low-level code.
# Macros

Macros are methods that receive AST nodes at compile-time and produce
code that is pasted into a program. For example:

```crystal
macro define_method(name, content)
  def {{name}}
    {{content}}
  end
end

# This generates:
#
#     def foo
#       1
#     end
define_method foo, 1

foo # => 1
```

A macro's definition body looks like regular Crystal code with extra syntax to manipulate the AST nodes. The generated code must be valid Crystal code, meaning that you can't for example generate a `def` without a matching `end`, or a single `when` expression of a `case`, since both of them are not complete valid expressions. Refer to [Pitfalls](#pitfalls) for more information.

## Scope

Macros declared at the top-level are visible anywhere. If a top-level macro is marked as `private` it is only accessible in that file.

They can also be defined in classes and modules, and are visible in those scopes. Macros are also looked-up in the ancestors chain (superclasses and included modules).

For example, a block which is given an object to use as the default receiver by being invoked with `with ... yield` can access macros defined within that object's ancestors chain:

```crystal
class Foo
  macro emphasize(value)
    "***#{ {{value}} }***"
  end

  def yield_with_self(&)
    with self yield
  end
end

Foo.new.yield_with_self { emphasize(10) } # => "***10***"
```

Macros defined in classes and modules can be invoked from outside of them too:

```crystal
class Foo
  macro emphasize(value)
    "***#{ {{value}} }***"
  end
end

Foo.emphasize(10) # => "***10***"
```

## Interpolation

You use `{{...}}` to paste, or interpolate, an AST node, as in the above example.

Note that the node is pasted as-is. If in the previous example we pass a symbol, the generated code becomes invalid:

```crystal
# This generates:
#
#     def :foo
#       1
#     end
define_method :foo, 1
```

Note that `:foo` was the result of the interpolation, because that's what was passed to the macro. You can use the method [`ASTNode#id`](https://crystal-lang.org/api/Crystal/Macros/ASTNode.html#id%3AMacroId-instance-method) in these cases, where you just need an identifier.

## Macro calls

You can invoke a **fixed subset** of methods on AST nodes at compile-time. These methods are documented in a fictitious [Crystal::Macros](https://crystal-lang.org/api/Crystal/Macros.html) module.

For example, invoking [`ASTNode#id`](https://crystal-lang.org/api/Crystal/Macros/ASTNode.html#id%3AMacroId-instance-method) in the above example solves the problem:

```crystal
macro define_method(name, content)
  def {{name.id}}
    {{content}}
  end
end

# This correctly generates:
#
#     def foo
#       1
#     end
define_method :foo, 1
```

### parse_type

Most AST nodes are obtained via either manually passed arguments, hard coded values, or retrieved from either the [type](#type-information) or [method](#method-information) information helper variables. Yet there might be cases in which a node is not directly accessible, such as if you use information from different contexts to construct the path to the desired type/constant.

In such cases the [`parse_type`](https://crystal-lang.org/api/Crystal/Macros.html#parse_type%28type_name%3AStringLiteral%29%3APath%7CGeneric%7CProcNotation%7CMetaclass-instance-method) macro method can help by parsing the provided [`StringLiteral`](https://crystal-lang.org/api/Crystal/Macros/StringLiteral.html) into something that can be resolved into the desired AST node.

```crystal
MY_CONST = 1234

struct Some::Namespace::Foo; end

{{ parse_type("Some::Namespace::Foo").resolve.struct? }} # => true
{{ parse_type("MY_CONST").resolve }}                     # => 1234

{{ parse_type("MissingType").resolve }} # Error: undefined constant MissingType
```

See the API docs for more examples.

## Modules and classes

Modules, classes and structs can also be generated:

```crystal
macro define_class(module_name, class_name, method, content)
  module {{module_name}}
    class {{class_name}}
      def initialize(@name : String)
      end

      def {{method}}
        {{content}} + @name
      end
    end
  end
end

# This generates:
#     module Foo
#       class Bar
#         def initialize(@name : String)
#         end
#
#         def say
#           "hi " + @name
#         end
#       end
#     end
define_class Foo, Bar, say, "hi "

p Foo::Bar.new("John").say # => "hi John"
```

## Conditionals

You use `{% if condition %}` ... `{% end %}` to conditionally generate code:

```crystal
macro define_method(name, content)
  def {{name}}
    {% if content == 1 %}
      "one"
    {% elsif content == 2 %}
      "two"
    {% else %}
      {{content}}
    {% end %}
  end
end

define_method foo, 1
define_method bar, 2
define_method baz, 3

foo # => one
bar # => two
baz # => 3
```

Similar to regular code, [`Nop`](https://crystal-lang.org/api/Crystal/Macros/Nop.html), [`NilLiteral`](https://crystal-lang.org/api/Crystal/Macros/NilLiteral.html) and a false [`BoolLiteral`](https://crystal-lang.org/api/Crystal/Macros/BoolLiteral.html) are considered *falsey*, while everything else is considered *truthy*.

Macro conditionals can be used outside a macro definition:

```crystal
{% if env("TEST") %}
  puts "We are in test mode"
{% end %}
```

## Iteration

You can iterate a finite amount of times:

```crystal
macro define_constants(count)
  {% for i in (1..count) %}
    PI_{{i.id}} = Math::PI * {{i}}
  {% end %}
end

define_constants(3)

PI_1 # => 3.14159...
PI_2 # => 6.28318...
PI_3 # => 9.42477...
```

To iterate an [`ArrayLiteral`](https://crystal-lang.org/api/Crystal/Macros/ArrayLiteral.html):

```crystal
macro define_dummy_methods(names)
  {% for name, index in names %}
    def {{name.id}}
      {{index}}
    end
  {% end %}
end

define_dummy_methods [foo, bar, baz]

foo # => 0
bar # => 1
baz # => 2
```

The `index` variable in the above example is optional.

To iterate a [`HashLiteral`](https://crystal-lang.org/api/Crystal/Macros/HashLiteral.html):

```crystal
macro define_dummy_methods(hash)
  {% for key, value in hash %}
    def {{key.id}}
      {{value}}
    end
  {% end %}
end

define_dummy_methods({foo: 10, bar: 20})
foo # => 10
bar # => 20
```

Macro iterations can be used outside a macro definition:

```crystal
{% for name, index in ["foo", "bar", "baz"] %}
  def {{name.id}}
    {{index}}
  end
{% end %}

foo # => 0
bar # => 1
baz # => 2
```

## Variadic arguments and splatting

A macro can accept variadic arguments:

```crystal
macro define_dummy_methods(*names)
  {% for name, index in names %}
    def {{name.id}}
      {{index}}
    end
  {% end %}
end

define_dummy_methods foo, bar, baz

foo # => 0
bar # => 1
baz # => 2
```

The arguments are packed into a [`TupleLiteral`](https://crystal-lang.org/api/Crystal/Macros/TupleLiteral.html) and passed to the macro.

Additionally, using `*` when interpolating a [`TupleLiteral`](https://crystal-lang.org/api/Crystal/Macros/TupleLiteral.html) interpolates the elements separated by commas:

```crystal
macro println(*values)
  print {{*values}}, '\n'
end

println 1, 2, 3 # outputs 123\n
```

## Type information

When a macro is invoked you can access the current scope, or type, with a special instance variable: `@type`. The type of this variable is [`TypeNode`](https://crystal-lang.org/api/Crystal/Macros/TypeNode.html), which gives you access to type information at compile time.

Note that `@type` is always the *instance* type, even when the macro is invoked in a class method.

For example:

```crystal
macro add_describe_methods
  def describe
    "Class is: " + {{ @type.stringify }}
  end

  def self.describe
    "Class is: " + {{ @type.stringify }}
  end
end

class Foo
  add_describe_methods
end

Foo.new.describe # => "Class is Foo"
Foo.describe     # => "Class is Foo"
```

## The top level module

It is possible to access the top-level namespace, as a [`TypeNode`](https://crystal-lang.org/api/Crystal/Macros/TypeNode.html), with a special variable: `@top_level`. The following example shows its utility:

```crystal
A_CONSTANT = 0

{% if @top_level.has_constant?("A_CONSTANT") %}
  puts "this is printed"
{% else %}
  puts "this is not printed"
{% end %}
```

## Method information

When a macro is invoked you can access the method, the macro is in with a special instance variable: `@def`. The type of this variable is [`Def`](https://crystal-lang.org/api/Crystal/Macros/Def.html) unless the macro is outside of a method, in this case it's [`NilLiteral`](https://crystal-lang.org/api/Crystal/Macros/NilLiteral.html).

Example:

```crystal
module Foo
  def Foo.boo(arg1, arg2)
    {% @def.receiver %} # => Foo
    {% @def.name %}     # => boo
    {% @def.args %}     # => [arg1, arg2]
  end
end

Foo.boo(0, 1)
```

## Call Information

When a macro is called, you can access the macro call stack with a special instance variable: `@caller`.
This variable returns an `ArrayLiteral` of [`Call`](https://crystal-lang.org/api/Crystal/Macros/Call.html) nodes with the first element in the array being the most recent.
Outside of a macro or if the macro has no caller (e.g. a [hook](./hooks.md)) the value is a [`NilLiteral`](https://crystal-lang.org/api/Crystal/Macros/NilLiteral.html).

NOTE: As of now, the returned array will always only have a single element.

Example:

```crystal
macro foo
  {{ @caller.first.line_number }}
end

def bar
  {{ @caller }}
end

foo # => 9
bar # => nil
```

## Constants

Macros can access constants. For example:

```crystal
VALUES = [1, 2, 3]

{% for value in VALUES %}
  puts {{value}}
{% end %}
```

If the constant denotes a type, you get back a [`TypeNode`](https://crystal-lang.org/api/Crystal/Macros/TypeNode.html).

## Nested macros

It is possible to define a macro which generates one or more macro definitions. You must escape macro expressions of the inner macro by preceding them with a backslash character "\\" to prevent them from being evaluated by the outer macro.

```crystal
macro define_macros(*names)
  {% for name in names %}
    macro greeting_for_{{name.id}}(greeting)
      \{% if greeting == "hola" %}
        "¡hola {{name.id}}!"
      \{% else %}
        "\{{greeting.id}} {{name.id}}"
      \{% end %}
    end
  {% end %}
end

# This generates:
#
#     macro greeting_for_alice(greeting)
#       {% if greeting == "hola" %}
#         "¡hola alice!"
#       {% else %}
#         "{{greeting.id}} alice"
#       {% end %}
#     end
#     macro greeting_for_bob(greeting)
#       {% if greeting == "hola" %}
#         "¡hola bob!"
#       {% else %}
#         "{{greeting.id}} bob"
#       {% end %}
#     end
define_macros alice, bob

greeting_for_alice "hello" # => "hello alice"
greeting_for_bob "hallo"   # => "hallo bob"
greeting_for_alice "hej"   # => "hej alice"
greeting_for_bob "hola"    # => "¡hola bob!"
```

### verbatim

Another way to define a nested macro is by using the special `verbatim` call. Using this you will not be able to use any variable interpolation but will not need to escape the inner macro characters.

```crystal
macro define_macros(*names)
  {% for name in names %}
    macro greeting_for_{{name.id}}(greeting)

      # name will not be available within the verbatim block
      \{% name = {{name.stringify}} %}

      {% verbatim do %}
        {% if greeting == "hola" %}
          "¡hola {{name.id}}!"
        {% else %}
          "{{greeting.id}} {{name.id}}"
        {% end %}
      {% end %}
    end
  {% end %}
end

# This generates:
#
#     macro greeting_for_alice(greeting)
#       {% name = "alice" %}
#       {% if greeting == "hola" %}
#         "¡hola {{name.id}}!"
#       {% else %}
#         "{{greeting.id}} {{name.id}}"
#       {% end %}
#     end
#     macro greeting_for_bob(greeting)
#       {% name = "bob" %}
#       {% if greeting == "hola" %}
#         "¡hola {{name.id}}!"
#       {% else %}
#         "{{greeting.id}} {{name.id}}"
#       {% end %}
#     end
define_macros alice, bob

greeting_for_alice "hello" # => "hello alice"
greeting_for_bob "hallo"   # => "hallo bob"
greeting_for_alice "hej"   # => "hej alice"
greeting_for_bob "hola"    # => "¡hola bob!"
```

Notice the variables in the inner macro are not available within the `verbatim` block. The contents of the block are transferred "as is", essentially as a string, until re-examined by the compiler.

## Comments

Macro expressions are evaluated both within comments as well as compilable sections of code. This may be used to provide relevant documentation for expansions:

```crystal
{% for name, index in ["foo", "bar", "baz"] %}
  # Provides a placeholder {{name.id}} method. Always returns {{index}}.
  def {{name.id}}
    {{index}}
  end
{% end %}
```

This evaluation applies to both interpolation and directives. As a result of this, macros cannot be commented out.

```crystal
macro a
  # {% if false %}
  puts 42
  # {% end %}
end

a
```

The expression above will result in no output.

### Merging Expansion and Call Comments

The [`@caller`](#call-information) can be combined with the [`#doc_comment`](https://crystal-lang.org/api/Crystal/Macros/ASTNode.html#doc_comment%3AMacroId-instance-method) method in order to allow merging documentation comments on a node generated by a macro, and the comments on the macro call itself. For example:

```crystal
macro gen_method(name)
 # {{ @caller.first.doc_comment }}
 #
 # Comment added via macro expansion.
 def {{name.id}}
 end
end

# Comment on macro call.
gen_method foo
```

When generated, the docs for the `#foo` method would be like:

```text
Comment on macro call.

Comment added via macro expansion.
```

## Pitfalls

When writing macros (especially outside of a macro definition) it is important to remember that the generated code from the macro must be valid Crystal code by itself even before it is merged into the main program's code. This means, for example, a macro cannot generate a one or more `when` expressions of a `case` statement unless `case` was a part of the generated code.

Here is an example of such an invalid macro:

```{.crystal nocheck}
case 42
{% for klass in [Int32, String] %} # Syntax Error: unexpected token: {% (expecting when, else or end)
  when {{klass.id}}
    p "is {{klass}}"
{% end %}
end
```

Notice that `case` is not within the macro. The code generated by the macro consists solely of two `when` expressions which, by themselves, is not valid Crystal code. We must include `case` within the macro in order to make it valid by using `begin` and `end`:

```crystal
{% begin %}
  case 42
  {% for klass in [Int32, String] %}
    when {{klass.id}}
      p "is {{klass}}"
  {% end %}
  end
{% end %}
```
# Fresh variables

Once macros generate code, they are parsed with a regular Crystal parser where local variables in the context of the macro invocations are assumed to be defined.

This is better understood with an example:

```crystal
macro update_x
  x = 1
end

x = 0
update_x
x # => 1
```

This can sometimes be useful to avoid repetitive code by deliberately reading/writing local variables, but can also overwrite local variables by mistake. To avoid this, fresh variables can be declared with `%name`:

```crystal
macro dont_update_x
  %x = 1
  puts %x
end

x = 0
dont_update_x # outputs 1
x             # => 0
```

Using `%x` in the above example, we declare a variable whose name is guaranteed not to conflict with local variables in the current scope.

Additionally, fresh variables with respect to some other AST node can be declared with `%var{key1, key2, ..., keyN}`. For example:

```crystal
macro fresh_vars_sample(*names)
  # First declare vars
  {% for name, index in names %}
    print "Declaring: ", stringify(%name{index}), '\n'
    %name{index} = {{index}}
  {% end %}

  # Then print them
  {% for name, index in names %}
    print stringify(%name{index}), ": ", %name{index}, '\n'
  {% end %}
end

macro stringify(var)
  {{ var.stringify }}
end

fresh_vars_sample a, b, c

# Sample output:
# Declaring: __temp_255
# Declaring: __temp_256
# Declaring: __temp_257
# __temp_255: 0
# __temp_256: 1
# __temp_257: 2
```

In the above example, three indexed variables are declared, assigned values, and then printed, displaying their corresponding indices.
# Hooks

Special macros exist that are invoked in some situations as hooks, at compile time:

* `inherited` is invoked when a subclass is defined. `@type` is the inheriting type.
* `included` is invoked when a module is included. `@type` is the including type.
* `extended` is invoked when a module is extended. `@type` is the extending type.
* `method_missing` is invoked when a method is not found.
* `method_added` is invoked when a new method is defined in the current scope.
* `finished` is invoked after parsing finished, so all types and their methods are known.

Example of `inherited`:

```crystal
class Parent
  macro inherited
    def lineage
      "{{@type.name.id}} < Parent"
    end
  end
end

class Child < Parent
end

Child.new.lineage # => "Child < Parent"
```

Example of `method_missing`:

```crystal
macro method_missing(call)
  print "Got ", {{call.name.id.stringify}}, " with ", {{call.args.size}}, " arguments", '\n'
end

foo          # Prints: Got foo with 0 arguments
bar 'a', 'b' # Prints: Got bar with 2 arguments
```

Example of `method_added`:

```crystal
macro method_added(method)
  {% puts "Method added:", method.name.stringify %}
end

def generate_random_number
  4
end
# => Method added: generate_random_number
```

Both `method_missing` and `method_added` only apply to calls or methods in the same class that the macro is defined in or its descendants, or only in the top level if the macro is defined outside of a class. For example:

```crystal
macro method_missing(call)
  puts "In outer scope, got call: ", {{ call.name.stringify }}
end

class SomeClass
  macro method_missing(call)
    puts "Inside SomeClass, got call: ", {{ call.name.stringify }}
  end
end

class OtherClass
end

# This call is handled by the top-level `method_missing`
foo # => In outer scope, got call: foo

obj = SomeClass.new
# This is handled by the one inside SomeClass
obj.bar # => Inside SomeClass, got call: bar

other = OtherClass.new
# Neither OtherClass or its parents define a `method_missing` macro
other.baz # => Error: Undefined method 'baz' for OtherClass
```

`finished` is called once a type has been completely defined - this includes extensions on that class. Consider the following program:

```crystal
macro print_methods
  {% puts @type.methods.map &.name %}
end

class Foo
  macro finished
    {% puts @type.methods.map &.name %}
  end

  print_methods
end

class Foo
  def bar
    puts "I'm a method!"
  end
end

Foo.new.bar
```

The `print_methods` macro will be run as soon as it is encountered - and will print an empty list as there are no methods defined at that point. Once the second declaration of `Foo` is compiled the `finished` macro will be run, which will print `[bar]`.

Depending on the macro hook used, a hook can either be stacked or overridden.

## Stacking

When stacked, a hook is executed multiple times in its defined context for as many times as the hook is defined. Hooks executed in this way will execute in order of definition. Consider the following example:

```crystal
# Stack the top-level finished macro
macro finished
  {% puts "I will execute!" %}
end

macro finished
  {% puts "I will also execute!" %}
end
```

In the above example, both `finished` macros will execute. Stacking works for the following hooks: `inherited`, `included`, `extended`, `method_added`, `finished`

## Overriding

A definition of the `method_missing` macro hook overrides any previous definition of this hook in the same context. Only the last defined macro executes. For example:

```crystal
macro method_missing(name)
  {% puts "I didnt run! :(" %}
end

class Example
  macro method_missing(name)
    {% puts "I didnt run! :(" %}
  end

  macro method_missing(name)
    {% puts "I am the only one that will run!" %}
  end
end

macro method_missing(name)
  {% puts "I am the only one that will run!" %}
end

Example.new.call_a_missing_method # => I am the only one that will run!

call_a_missing_method # => I am the only one that will run!
```
# Macro methods

Macro defs allow you to define a method for a class hierarchy which is then instantiated for each concrete subtype.

A `def` is implicitly considered a `macro def` if it contains a macro expression which refers to `@type`. For example:

```crystal
class Object
  def instance_vars_names
    {{ @type.instance_vars.map &.name.stringify }}
  end
end

class Person
  def initialize(@name : String, @age : Int32)
  end
end

person = Person.new "John", 30
person.instance_vars_names # => ["name", "age"]
```

In macro definitions, arguments are passed as their AST nodes, giving you access to them in macro expansions (`{{some_macro_argument}}`). However that is not true for macro defs. Here the parameter list is that of the method generated by the macro def. You cannot access the call arguments during compile-time.

```crystal
class Object
  def has_instance_var?(name) : Bool
    # We cannot access name inside the macro expansion here,
    # instead we need to use the macro language to construct an array
    # and do the inclusion check at runtime.
    {{ @type.instance_vars.map &.name.stringify }}.includes? name
  end
end

person = Person.new "John", 30
person.has_instance_var?("name")     # => true
person.has_instance_var?("birthday") # => false
```
# Methods and instance variables

We can simplify our constructor by using a shorter syntax for assigning a method parameter to an instance variable:

```crystal
class Person
  def initialize(@name : String)
    @age = 0
  end

  def age
    @age
  end
end
```

Right now, we can't do much with a person aside from create it with a name. Its age will always be zero. So lets add a method that makes a person become older:

```crystal
class Person
  def initialize(@name : String)
    @age = 0
  end

  def age
    @age
  end

  def become_older
    @age += 1
  end
end

john = Person.new "John"
peter = Person.new "Peter"

john.age # => 0

john.become_older
john.age # => 1

peter.age # => 0
```

Method names begin with a lowercase letter and, as a convention, only use lowercase letters, underscores and numbers.

## Getters and setters

The Crystal [Standard Library](https://crystal-lang.org/api) provides macros which simplify the definition of getter and setter methods:

```crystal
class Person
  property age
  getter name : String

  def initialize(@name)
    @age = 0
  end
end

john = Person.new "John"
john.age = 32
john.age # => 32
```

For more information on getter and setter macros, see the standard library documentation for [Object#getter](https://crystal-lang.org/api/Object.html#getter%28%2Anames%2C%26block%29-macro), [Object#setter](https://crystal-lang.org/api/Object.html#setter%28%2Anames%29-macro), and [Object#property](https://crystal-lang.org/api/Object.html#property%28%2Anames%2C%26block%29-macro).

As a side note, we can define `become_older` inside the original `Person` definition, or in a separate definition: Crystal combines all definitions into a single class. The following works just fine:

```crystal
class Person
  def initialize(@name : String)
    @age = 0
  end
end

class Person
  def become_older
    @age += 1
  end
end
```

## Redefining methods, and previous_def

If you redefine a method, the last definition will take precedence.

```crystal
class Person
  def become_older
    @age += 1
  end
end

class Person
  def become_older
    @age += 2
  end
end

person = Person.new "John"
person.become_older
person.age # => 2
```

You can invoke the previously redefined method with `previous_def`:

```crystal
class Person
  def become_older
    @age += 1
  end
end

class Person
  def become_older
    previous_def
    @age += 2
  end
end

person = Person.new "John"
person.become_older
person.age # => 3
```

Without arguments or parentheses, `previous_def` receives all of the method's parameters as arguments. Otherwise, it receives the arguments you pass to it.

## Catch-all initialization

Instance variables can also be initialized outside `initialize` methods:

```crystal
class Person
  @age = 0

  def initialize(@name : String)
  end
end
```

This will initialize `@age` to zero in every constructor. This is useful to avoid duplication, but also to avoid the `Nil` type when reopening a class and adding instance variables to it.
# Modules

Modules serve two purposes:

* as namespaces for defining other types, methods and constants
* as partial types that can be mixed in other types

An example of a module as a namespace:

```crystal
module Curses
  class Window
  end
end

Curses::Window.new
```

Library authors are advised to put their definitions inside a module to avoid name clashes. The standard library usually doesn't have a namespace as its types and methods are very common, to avoid writing long names.

To use a module as a partial type you use `include` or `extend`.

An `include` makes a type include methods defined in that module as instance methods:

```crystal
module ItemsSize
  def size
    items.size
  end
end

class Items
  include ItemsSize

  def items
    [1, 2, 3]
  end
end

items = Items.new
items.size # => 3
```

In the above example, it is as if we pasted the `size` method from the module into the `Items` class. The way this really works is by making each type have a list of ancestors, or parents. By default this list starts with the superclass. As modules are included they are **prepended** to this list. When a method is not found in a type it is looked up in this list. When you invoke `super`, the first type in this ancestors list is used.

A `module` can include other modules, so when a method is not found in it it will be looked up in the included modules.

An `extend` makes a type include methods defined in that module as class methods:

```crystal
module SomeSize
  def size
    3
  end
end

class Items
  extend SomeSize
end

Items.size # => 3
```

Both `include` and `extend` make constants defined in the module available to the including/extending type.

Both of them can be used at the top level to avoid writing a namespace over and over (although the chances of name clashes increase):

```crystal
module SomeModule
  class SomeType
  end

  def some_method
    1
  end
end

include SomeModule

SomeType.new # OK, same as SomeModule::SomeType
some_method  # OK, 1
```

## extend self

A common pattern for modules is `extend self`:

```crystal
module Base64
  extend self

  def encode64(string)
    # ...
  end

  def decode64(string)
    # ...
  end
end
```

In this way a module can be used as a namespace:

```crystal
Base64.encode64 "hello" # => "aGVsbG8="
```

But also it can be included in the program and its methods can be invoked without a namespace:

```crystal
include Base64

encode64 "hello" # => "aGVsbG8="
```

For this to be useful the method name should have some reference to the module, otherwise chances of name clashes are high.

A module cannot be instantiated:

```crystal
module Moo
end

Moo.new # undefined method 'new' for Moo:Module
```

## Module Type Checking

Modules can also be used for type checking.

If we define two modules with names `A` and `B`:

```crystal
module A; end

module B; end
```

These can be included into classes:

```crystal
class One
  include A
end

class Two
  include B
end

class Three < One
  include B
end
```

We can then type check against instances of these classes with not only their class, but the
included modules as well:

```crystal
one = One.new
typeof(one)  # => One
one.is_a?(A) # => true
one.is_a?(B) # => false

three = Three.new
typeof(three)  # => Three
three.is_a?(A) # => true
three.is_a?(B) # => true
```

This allows you to define arrays and methods based on module type instead of class:

```crystal
one = One.new
two = Two.new
three = Three.new

new_array = Array(A).new
new_array << one   # Ok, One includes module A
new_array << three # Ok, Three inherits module A

new_array << two # Error, because Two neither inherits nor includes module A
```
# new, initialize and allocate

You create an instance of a class by invoking `new` on that class:

```crystal
person = Person.new
```

Here, `person` is an instance of `Person`.

We can't do much with `person`, so let's add some concepts to it. A `Person` has a name and an age. In the "Everything is an object" section we said that an object has a type and responds to some methods, which is the only way to interact with objects, so we'll need both `name` and `age` methods. We will store this information in instance variables, which are always prefixed with an *at* (`@`) character. We also want a Person to come into existence with a name of our choice and an age of zero. We code the "come into existence" part with a special `initialize` method, which is normally called a *constructor*:

```crystal
class Person
  def initialize(name : String)
    @name = name
    @age = 0
  end

  def name
    @name
  end

  def age
    @age
  end
end
```

Now we can create people like this:

```crystal
john = Person.new "John"
peter = Person.new "Peter"

john.name # => "John"
john.age  # => 0

peter.name # => "Peter"
```

(If you wonder why we needed to specify that `name` is a `String` but we didn't need to do it for `age`, check the [global type inference algorithm](type_inference.md))

Note that we create a `Person` with `new` but we defined the initialization in an `initialize` method, not in a `new` method. Why is this so?

The answer is that when we defined an `initialize` method Crystal defined a `new` method for us, like this:

```crystal
class Person
  def self.new(name : String)
    instance = Person.allocate
    instance.initialize(name)
    instance
  end
end
```

First, note the `self.new` notation. This is a [class method](class_methods.md) that belongs to the **class** `Person`, not to particular instances of that class. This is why we can do `Person.new`.

Second, `allocate` is a low-level class method that creates an uninitialized object of the given type. It basically allocates the necessary memory for the object, then `initialize` is invoked on it and finally the instance is returned. You generally never invoke `allocate`, as it is [unsafe](unsafe.md), but that's the reason why `new` and `initialize` are related.
# next

You can use `next` to try to execute the next iteration of a `while` loop. After executing `next`, the `while`'s condition is checked and, if *truthy*, the body will be executed.

```crystal
a = 1
while a < 5
  a += 1
  if a == 3
    next
  end
  puts a
end

# The above prints the numbers 2, 4 and 5
```

`next` can also be used to exit from a block, for example:

```crystal
def block(&)
  yield
end

block do
  puts "hello"
  next
  puts "world"
end

# The above prints "hello"
```

Similar to [`break`](break.md), `next` can also take an argument which will then be returned by `yield`.

```crystal
def block(&)
  puts yield
end

block do
  next "hello"
end

# The above prints "hello"
```
# nil?

The pseudo-method `nil?` determines whether an expression's runtime type is `Nil`. For example:

```crystal
a = 1
a.nil? # => false

b = nil
b.nil? # => true
```

It is a pseudo-method because the compiler knows about it and it can affect type information, as explained in [if var.nil?(...)](if_var_nil.md).

It has the same effect as writing `is_a?(Nil)` but it's shorter and easier to read and write.
# `if !`

The `!` operator returns a `Bool` that results from negating the [truthiness](truthy_and_falsey_values.md) of a value.

When used in an `if` in conjunction with a variable, `is_a?`, `responds_to?` or `nil?` the compiler will restrict the types accordingly:

```crystal
a = some_condition ? nil : 3
if !a
  # here a is Nil because a is falsey in this branch
else
  # here a is Int32, because a is truthy in this branch
end
```

```crystal
b = some_condition ? 1 : "x"
if !b.is_a?(Int32)
  # here b is String because it's not an Int32
end
```
# offsetof

An `offsetof` expression returns the byte offset of a field in an instance of a class or struct.

There are two forms of `offsetof` expressions. The first form accepts any type as first argument and an instance variable name prefixed by an `@` as second argument, and returns the byte offset of that instance variable relative to an instance of the given type:

```crystal
struct Foo
  @x = 0_i64
  @y = 34_i8
  @z = 42_u16
end

offsetof(Foo, @x) # => 0
offsetof(Foo, @y) # => 8
offsetof(Foo, @z) # => 10
```

The second form accepts any [`Tuple`](https://crystal-lang.org/api/Tuple.html) instance type as first argument and an integer literal index as second argument, and returns the byte offset of the corresponding tuple element relative to an instance of the given type:

```crystal
offsetof(Tuple(Int64, Int8, UInt16), 0) # => 0
offsetof(Tuple(Int64, Int8, UInt16), 1) # => 8
offsetof(Tuple(Int64, Int8, UInt16), 2) # => 10
```

This is a low-level primitive and only useful if a C API needs to directly interface with the data layout of a Crystal type.
# Operators

Crystal supports a number of operators, with one, two or three operands.

Operator expressions are actually parsed as method calls. For example `a + b`
is semantically equivalent to `a.+(b)`, a call to method `+` on `a` with
argument `b`.

There are however some special rules regarding operator syntax:

* The dot (`.`) usually put between receiver and method name
  (i.e. the *operator*) can be omitted.
* Chained sequences of operator calls are restructured by the compiler in order
  to implement [operator precedence](#operator-precedence).
  Enforcing operator precedence makes sure that an expression such as
  `1 * 2 + 3 * 4` is parsed as `(1 * 2) + (2 * 3)` to honour regular math rules.
* Regular method names must start with a letter or underscore, but operators
  only consist of special characters. Any method not starting with a letter or
  underscore is an operator  method.
* Available operators are whitelisted in the compiler (see
  [List of Operators](#list-of-operators) below) which allows symbol-only method
  names and treats them as operators, including their precedence rules.

Operators are implemented like any regular method, and the standard library
offers many implementations, for example for math expressions.

## Defining operator methods

Most operators can be implemented as regular methods.

One can assign any meaning to the operators, but it is advisable to stay within
similar semantics to the generic operator meaning to avoid cryptic code that is
confusing and behaves unexpectedly.

A few operators are defined directly by the compiler and cannot be redefined
in user code. Examples for this are the inversion operator `!`, the assignment
operator `=`, [combined assignment operators](#combined-assignments) such as
`||=` and [range operators](#range). Whether a method can be redefined is
indicated by the column *Overloadable* in the below operator tables.

### Unary operators

Unary operators are written in prefix notation and have only a single operand.
Thus, a method implementation receives no arguments and only operates on `self`.

The following example demonstrates the `Vector2` type as a two-dimensional
vector with a unary operator method `-` for vector inversion.

```crystal
struct Vector2
  getter x, y

  def initialize(@x : Int32, @y : Int32)
  end

  # Unary operator. Returns the inverted vector to `self`.
  def - : self
    Vector2.new(-x, -y)
  end
end

v1 = Vector2.new(1, 2)
-v1 # => Vector2(@x=-1, @y=-2)
```

### Binary operators

Binary operators have two operands. Thus, a method implementation receives
exactly one argument representing the second operand. The first operand is the
receiver `self`.

The following example demonstrates the `Vector2` type as a two-dimensional
vector with a binary operator method `+` for vector addition.

```crystal
struct Vector2
  getter x, y

  def initialize(@x : Int32, @y : Int32)
  end

  # Binary operator. Returns *other* added to `self`.
  def +(other : self) : self
    Vector2.new(x + other.x, y + other.y)
  end
end

v1 = Vector2.new(1, 2)
v2 = Vector2.new(3, 4)
v1 + v2 # => Vector2(@x=4, @y=6)
```

Per convention, the return type of a binary operator should be the type of the
first operand (the receiver), so that `typeof(a <op> b) == typeof(a)`.
Otherwise the assignment operator (`a <op>= b`) would unintentionally change the
type of `a`.
There can be reasonable exceptions though. For example in the standard library
the float division operator `/` on integer types always returns `Float64`,
because the quotient must not be limited to the value range of integers.

### Ternary operators

The [conditional operator (`? :`)](./ternary_if.md) is the only ternary
operator. It not parsed as a method, and its meaning cannot be changed.
The compiler transforms it to an `if` expression.

## Operator Precedence

This list is sorted by precedence, so upper entries bind stronger than lower
ones.

<!-- markdownlint-disable no-space-in-code -->

| Category | Operators |
|---|---|
| Index accessors | `[]`, `[]?` |
| Unary | `+`, `&+`, `-`, `&-`, `!`, `~` |
| Exponential | `**`, `&**` |
| Multiplicative | `*`, `&*`, `/`, `//`, `%` |
| Additive | `+`, `&+`, `-`, `&-` |
| Shift | `<<`, `>>` |
| Binary AND | `&` |
| Binary OR/XOR | <code>\|</code>,`^` |
| Equality and Subsumption | `==`, `!=`, `=~`, `!~`, `===` |
| Comparison | `<`, `<=`, `>`, `>=`, `<=>` |
| Logical AND | `&&` |
| Logical OR | <code>\|\|</code> |
| Range | `..`, `...` |
| Conditional | `?:` |
| Assignment | `=`, `[]=`, `+=`, `&+=`, `-=`, `&-=`, `*=`, `&*=`, `/=`, `//=`, `%=`, <code>\|=</code>, `&=`,`^=`,`**=`,`<<=`,`>>=`, <code>\|\|=</code>, `&&=` |
| Splat | `*`, `**` |

<!-- markdownlint-enable no-space-in-code -->

## List of operators

### Arithmetic operators

#### Unary

| Operator | Description | Example | Overloadable | Associativity |
|---|---|---|---|---|
| `+`  | positive | `+1` | yes | right |
| `&+` | wrapping positive | `&+1` | yes | right |
| `-`  | negative | `-1` | yes | right |
| `&-` | wrapping negative | `&-1` | yes | right |

#### Multiplicative

| Operator | Description | Example | Overloadable | Associativity |
|---|---|---|---|---|
| `**` | exponentiation | `1 ** 2` | yes | right |
| `&**` | wrapping exponentiation | `1 &** 2` | yes | right |
| `*` | multiplication | `1 * 2` | yes | left |
| `&*` | wrapping multiplication | `1 &* 2` | yes | left |
| `/` | division | `1 / 2` | yes | left |
| `//` | floor division | `1 // 2` | yes | left |
| `%` | modulus | `1 % 2` | yes | left |

#### Additive

| Operator | Description | Example | Overloadable | Associativity |
|---|---|---|---|---|
| `+` | addition | `1 + 2` | yes | left |
| `&+` | wrapping addition | `1 &+ 2` | yes | left |
| `-` | subtraction | `1 - 2` | yes | left |
| `&-` | wrapping subtraction | `1 &- 2` | yes | left |

### Other unary operators

| Operator | Description | Example | Overloadable | Associativity |
|---|---|---|---|---|
| `!` | inversion | `!true` | no | right |
| `~` | binary complement | `~1` | yes | right |

### Shifts

| Operator | Description | Example | Overloadable | Associativity |
|---|---|---|---|---|
| `<<` | shift left, append | `1 << 2`, `STDOUT << "foo"` | yes | left |
| `>>` | shift right | `1 >> 2` | yes | left |

### Binary

| Operator | Description | Example | Overloadable | Associativity |
|---|---|---|---|---|
| `&` | binary AND | `1 & 2` | yes | left |
| <code>\|</code> | binary OR | <code>1 \| 2</code> | yes | left |
| `^` | binary XOR | `1 ^ 2` | yes | left |

### Relational operators

<span id="equality-and-comparison" />

Relational operators test a relation between two values.
They include *equality*, *inequalities*, and *subsumption*.

#### Equality

The **equal operator** `==` checks whether the values of the operands are
considered equal.

The **not-equal operator** `!=` is a shortcut to express the inversion: `a != b`
is supposed to be equivalent to `!(a == b)`.

Types that implement the not-equal operator must make sure to adhere to this.
Special implementations can be useful for performance reasons because
inequality can often be proven faster than equality.

Both operators are expected to be commutative, i.e. `a == b` if and only if
`b == a`. This is not enforced by the compiler and implementing types must
take care themselves.

| Operator | Description | Example | Overloadable | Associativity |
|---|---|---|---|---|
| `==` | equal | `1 == 2` | yes | left |
| `!=` | not equal | `1 != 2` | yes | left |

> INFO: The standard library defines [`Reference#same?`](https://crystal-lang.org/api/Reference.html#same?(other:Reference):Bool-instance-method) as another equality
> test that is not an operator.
> It checks for referential identity which determines whether two values reference
> the same location in memory.

#### Inequalities

<span id="comparison" />

Inequality operators describe the order between values.

The **three-way comparison operator** `<=>` (also known as *spaceship operator*)
expresses the order between two elements expressed by the sign of its
return value.

| Operator | Description | Example | Overloadable | Associativity |
|---|---|---|---|---|
| `<` | less | `1 < 2` | yes | left |
| `<=` | less or equal | `1 <= 2` | yes | left |
| `>` | greater | `1 > 2` | yes | left |
| `>=` | greater or equal | `1 >= 2` | yes | left |
| `<=>` | three-way comparison | `1 <=> 2` | yes | left |

> INFO: The standard library defines the [`Comparable`](https://crystal-lang.org/api/Comparable.html) module which derives all other inequality operators as well as
> the equal operator from the three-way comparison operator.

#### Subsumption

The **pattern match operator** `=~` checks whether the value of the first operand
matches the value of the second operand with pattern matching.

The **no pattern match operator** `!~` expresses the inverse.

The **case subsumption operator** `===` (also, imprecisely called
*case equality operator* or *triple equals*) checks whether the right hand
operand is a member of the set described by the left hand operator.
The exact interpretation varies depending on the involved data types.

The compiler inserts this operator in [`case ... when` conditions](case.md).

There is no inverse operator.

| Operator | Description | Example | Overloadable | Associativity |
|---|---|---|---|---|
| `=~` | pattern match | `"foo" =~ /fo/` | yes | left |
| `!~` | no pattern match | `"foo" !~ /fo/` | yes | left |
| `===` | case subsumption | `/foo/ === "foo"` | yes | left |

#### Chaining relational operators

<span id="chaining-equality-and-comparison" />

Relational operators `==`, `!=`, `===`, `<`, `>`, `<=`, and `>=`
can be chained together and are interpreted as a compound expression.
For example `a <= b <= c` is treated as `a <= b && b <= c`.
It is possible to mix different operators: `a >= b <= c > d` is
equivalent to `a >= b && b <= c && c > d`.

It is advised to only combine operators of the same
[precedence class](#operator-precedence) to avoid surprising bind behaviour.
For instance, `a == b <= c` is equivalent to `a == b && b <= c`, while `a <= b == c` is equivalent to `a <= (b == c)`.

### Logical

| Operator | Description | Example | Overloadable | Associativity |
|---|---|---|---|---|
| `&&` | [logical AND](and.md) | `true && false` | no | left |
| <code>\|\|</code> | [logical OR](or.md) | <code>true \|\| false</code> | no | left |

### Range

The range operators are used in [Range](literals/range.md)
literals.

| Operator | Description | Example | Overloadable |
|---|---|---|---|
| `..` | inclusive range | `1..10` | no |
| `...` | exclusive range | `1...10` | no |

### Splats

Splat operators can only be used for destructing tuples in method arguments.
See [Splats and Tuples](splats_and_tuples.md) for details.

| Operator | Description | Example | Overloadable |
|---|---|---|---|
| `*` | splat | `*foo` | no |
| `**` | double splat | `**foo` | no |

### Conditional

The [conditional operator (`? :`)](./ternary_if.md) is internally rewritten to
an `if` expression by the compiler.

| Operator | Description | Example | Overloadable | Associativity |
|---|---|---|---|---|
| `? :` | conditional | `a == b ? c : d` | no | right |

### Assignments

The assignment operator `=` assigns the value of the second operand to the first
operand. The first operand is either a variable (in this case the operator can't
be redefined) or a call (in this case the operator can be redefined).
See [assignment](assignment.md) for details.

| Operator | Description | Example | Overloadable | Associativity |
|---|---|---|---|---|
| `=` | variable assignment | `a = 1` | no | right |
| `=` | call assignment | `a.b = 1` | yes | right |
| `[]=` | index assignment | `a[0] = 1` | yes | right |

### Combined assignments

The assignment operator `=` is the basis for all operators that combine an
operator with assignment. The general form is `a <op>= b` and the compiler
transform that into `a = a <op> b`.

Exceptions to the general expansion formula are the logical operators:

* `a ||= b` transforms to `a || (a = b)`
* `a &&= b` transforms to `a && (a = b)`

There is another special case when `a` is an index accessor (`[]`), it is
changed to the nilable variant (`[]?` on the right hand side:

* `a[i] ||= b` transforms to `a[i] = (a[i]? || b)`
* `a[i] &&= b` transforms to `a[i] = (a[i]? && b)`

All transformations assume the receiver (`a`) is a variable. If it is a call,
the replacements are semantically equivalent but the implementation is a bit
more complex (introducing an anonymous temporary variable) and expects `a=` to
be callable.

The receiver can't be anything else than a variable or call.

| Operator | Description | Example | Overloadable | Associativity |
|---|---|---|---|---|
| `+=` | addition *and* assignment | `i += 1` | no | right |
| `&+=` | wrapping addition *and* assignment | `i &+= 1` | no | right |
| `-=` | subtraction *and* assignment | `i -= 1` | no | right |
| `&-=` | wrapping subtraction *and* assignment | `i &-= 1` | no | right |
| `*=` | multiplication *and* assignment | `i *= 1` | no | right |
| `&*=` | wrapping multiplication *and* assignment | `i &*= 1` | no | right |
| `/=` | division *and* assignment | `i /= 1` | no | right |
| `//=` | floor division *and* assignment | `i //= 1` | no | right |
| `%=` | modulo *and* assignment | `i %= 1` | yes | right |
| <code>\|=</code> | binary or *and* assignment | <code>i \|= 1</code> | no | right |
| `&=` | binary and *and* assignment | `i &= 1` | no | right |
| `^=` | binary xor *and* assignment | `i ^= 1` | no | right |
| `**=` | exponential *and* assignment | `i **= 1` | no | right |
| `<<=` | left shift *and* assignment | `i <<= 1` | no | right |
| `>>=` | right shift *and* assignment | `i >>= 1` | no | right |
| <code>\|\|=</code> | logical or *and* assignment | <code>i \|\|= true</code> | no | right |
| `&&=` | logical and *and* assignment | `i &&= true` | no | right |

### Index Accessors

Index accessors are used to query a value by index or key, for example an array
item or map entry. The nilable variant `[]?` is supposed to return `nil` when
the index is not found, while the non-nilable variant raises in that case.
Implementations in the standard-library usually raise [`KeyError`](https://crystal-lang.org/api/KeyError.html)
or [`IndexError`](https://crystal-lang.org/api/IndexError.html).

| Operator | Description | Example | Overloadable |
|---|---|---|---|
| `[]` | index accessor | `ary[i]` | yes |
| `[]?` | nilable index accessor | `ary[i]?` | yes |
# || - Logical OR Operator

An `||` (or) evaluates its left hand side. If it's *falsey*, it evaluates its right hand side and has that value. Otherwise it has the value of the left hand side. Its type is the union of the types of both sides.

You can think an `||` as syntax sugar of an `if`:

```crystal
some_exp1 || some_exp2
```

The above is equivalent to:

```crystal
tmp = some_exp1
if tmp
  tmp
else
  some_exp2
end
```
# Overloading

We can define a `become_older` method that accepts a number indicating the years to grow:

```crystal
class Person
  getter :age

  def initialize(@name : String, @age : Int = 0)
  end

  def become_older
    @age += 1
  end

  def become_older(years)
    @age += years
  end
end

john = Person.new "John"
john.age # => 0

john.become_older
john.age # => 1

john.become_older 5
john.age # => 6
```

That is, you can have different methods with the same name and different number of parameters and they will be considered as separate methods. This is called *method overloading*.

Methods overload by several criteria:

* The number of parameters
* The type restrictions applied to parameters
* The names of required named parameters
* Whether the method accepts a [block](blocks_and_procs.md) or not

For example, we can define four different `become_older` methods:

```crystal
class Person
  @age = 0

  # Increases age by one
  def become_older
    @age += 1
  end

  # Increases age by the given number of years
  def become_older(years : Int32)
    @age += years
  end

  # Increases age by the given number of years, as a String
  def become_older(years : String)
    @age += years.to_i
  end

  # Yields the current age of this person and increases
  # its age by the value returned by the block
  def become_older(&)
    @age += yield @age
  end
end

person = Person.new "John"

person.become_older
person.age # => 1

person.become_older 5
person.age # => 6

person.become_older "12"
person.age # => 18

person.become_older do |current_age|
  current_age < 20 ? 10 : 30
end
person.age # => 28
```

Note that in the case of the method that yields, the compiler figured this out because there's a `yield` expression. To make this more explicit, you can add a dummy `&block` parameter at the end:

```crystal
class Person
  @age = 0

  def become_older(&block)
    @age += yield @age
  end
end
```

In generated documentation the dummy `&block` method will always appear, regardless of you writing it or not.

Given the same number of parameters, the compiler will try to sort them by leaving the less restrictive ones to the end:

```crystal
class Person
  @age = 0

  # First, this method is defined
  def become_older(age)
    @age += age
  end

  # Since "String" is more restrictive than no restriction
  # at all, the compiler puts this method before the previous
  # one when considering which overload matches.
  def become_older(age : String)
    @age += age.to_i
  end
end

person = Person.new "John"

# Invokes the first definition
person.become_older 20

# Invokes the second definition
person.become_older "12"
```

However, the compiler cannot always figure out the order because there isn't always a total ordering, so it's always better to put less restrictive methods at the end.

## Caveats

There are some known compiler bugs where overloading order is not as it's supposed to be.
Unfortunately, fixing these bugs would break existing code that relies on this specific, but unintended overload order.
We try to avoid breaking existing code, so it's not easy to roll out the fixes.

### Preview flag

Some bug fixes are already available with the compiler flag `-Dpreview_overload_order` (introduced in Crystal 1.6.0).

Consider using this flag when writing new Crystal code.

It's expected that this flag will be enabled by default in some future version.
At that point, all Crystal code is expected to use the correct overload ordering
and code which still depends on the incorrect ordering can use an opt-out feature flag for a transition period.

### Known bugs

* Overloads without a parameter override ones with a default value ([#10231](https://github.com/
crystal-lang/crystal/issues/10231))

  ```cr
  def bar(x = true)
  end

  def bar
  end

  bar 1 # Error: wrong number of arguments for 'bar' (given 1, expected 0)
  ```

  This issue is fixed with `-Dpreview_overload_order`.

* Overload ordering depends on the definition order of types used in type restrictions ([#7579](https://github.com/crystal-lang/crystal/issues/7579), [#4897](https://github.com/crystal-lang/crystal/issues/4897))

  ```cr
  class Foo
  end

  def foo(a : Bar)
    1
  end

  def foo(a : Foo)
    true
  end

  class Bar < Foo
  end

  foo(Bar.new) # => true # This should be 1
  ```

  As a workaround, we can move the declaration of `Bar` before of `def foo`.
# Crystal Platform Support

The Crystal compiler runs on, and compiles to, a great number of platforms, though not all platforms are equally supported. Crystal’s support levels are organized into three tiers, each with a different set of guarantees.

Platforms are identified by their “target triple” which is the string to inform the compiler what kind of output should be produced. The columns below indicate whether the corresponding component works on the specified platform.

***

## Tier 1

Tier 1 platforms can be thought of as “guaranteed to work”. Specifically they will each satisfy the following requirements:

* Official binary releases are provided for the platform.
* Automated testing is set up to run tests for the platform.
* Documentation for how to use and how to build the platform is available.

Only maintained operating system versions are fully supported. Obsolete versions are not guaranteed to work
and drop into *Tier 2*.

| Target | Description | Supported versions | Comment |
| ------ | ----------- | ------------------ | ------- |
| `aarch64-darwin` | Aarch64 macOS<br> (Apple Silicon) | 11+ *(testing only on 14)* | :material-checkbox-marked-circle: tests<br> :material-checkbox-marked-circle: builds |
| `x86_64-darwin` | x64 macOS<br> (Intel) | 11+<br> *(testing only on 13; expected to work on 10.7+)* | :material-checkbox-marked-circle: tests<br> :material-checkbox-marked-circle: builds |
| `x86_64-linux-gnu` | x64 Linux | kernel 4.14+, GNU libc 2.26+<br> *(expected to work on kernel 2.6.22+)* | :material-checkbox-marked-circle: tests<br> :material-checkbox-marked-circle: builds |
| `x86_64-linux-musl` | x64 Linux | kernel 4.14+, MUSL libc 1.2+<br> *(expected to work on kernel 2.6.22+)* | :material-checkbox-marked-circle: tests<br> :material-checkbox-marked-circle: builds |

***

## Tier 2

Tier 2 platforms can be thought of as “expected to work”.

The requirements for *Tier 1* may be partially fulfilled, but are lacking in some way that prevents a solid guarantee.
Details are described in the *Comment* column.

| Target | Description | Supported versions | Comment |
| ------ | ----------- | ------------------ | ------- |
| `aarch64-linux-gnu` | Aarch64 Linux | GNU libc 2.26+ | :material-checkbox-marked-circle: tests<br> :material-selection-ellipse: builds |
| `aarch64-linux-musl` | Aarch64 Linux | MUSL libc 1.2+ | :material-checkbox-marked-circle: tests<br> :material-selection-ellipse: builds |
| `arm-linux-gnueabihf` | Aarch32 Linux<br> (hardfloat) | GNU libc 2.26+ | :material-selection-ellipse: tests<br> :material-selection-ellipse: builds |
| `i386-linux-gnu` | x86 Linux | kernel 4.14+, GNU libc 2.26+<br> *(expected to work on kernel 2.6.22+)* | :material-selection-ellipse: tests<br> :material-selection-ellipse: builds |
| `i386-linux-musl` | x86 Linux | kernel 4.14+, MUSL libc 1.2+<br> *(expected to work on kernel 2.6.22+)* | :material-selection-ellipse: tests<br> :material-selection-ellipse: builds |
| `x86_64-openbsd` | x64 OpenBSD | 6+ | :material-selection-ellipse: tests<br> :material-selection-ellipse: builds |
| `x86_64-freebsd` | x64 FreeBSD | 12+ | :material-selection-ellipse: tests<br> :material-selection-ellipse: builds |

***

## Tier 3

Tier 3 platforms can be thought of as “partially works”.

The Crystal codebase has support for these platforms, but there are some major limitations.
Most typically, some parts of the standard library are not supported completely.

| Target | Description | Supported versions | Comment |
| ------ | ----------- | ------------------ | ------- |
| `x86_64-windows-msvc` | x64 Windows (MSVC) | 7+ | :material-circle-slice-7: tests<br> :material-checkbox-marked-circle: builds |
| `x86_64-windows-gnu` | x64 Windows (MinGW-w64) | 7+, MSYS2 `UCRT64` / `MINGW64` / `CLANG64` environment | :material-circle-slice-7: tests<br> :material-checkbox-marked-circle: builds |
| `aarch64-windows-msvc` | ARM64 Windows (MSVC) | 11+ | :material-selection-ellipse: tests<br> :material-selection-ellipse: builds |
| `aarch64-windows-gnu` | ARM64 Windows (MinGW-w64) | 11+, MSYS2 `CLANGARM64` environment | :material-circle-slice-7: tests<br> :material-checkbox-marked-circle: builds |
| `aarch64-linux-android` | aarch64 Android  | Bionic C runtime, API level 24+ | :material-selection-ellipse: tests<br> :material-selection-ellipse: builds |
| `x86_64-unknown-dragonfly` | x64 DragonFlyBSD | | :material-selection-ellipse: tests<br> :material-selection-ellipse: builds |
| `x86_64-unknown-netbsd` | x64 NetBSD | | :material-selection-ellipse: tests<br> :material-selection-ellipse: builds |
| `wasm32-unknown-wasi` | WebAssembly (WASI libc) | Wasmtime 2+ | :material-circle-slice-5: tests |
| `x86_64-solaris` | Solaris/illumos | | :material-selection-ellipse: tests<br> :material-selection-ellipse: builds |

## Compiler support

The compiler can target these platforms but there is no support for the standard library (i.e. must compile with `--prelude=empty`).

| Target | Description | Supported versions | Comment |
| ------ | ----------- | ------------------ | ------- |
| `avr-unknown-unknown` | AVR (Atmel) CPU architecture (Arduino)<br>This target requires declaration of a CPU model (e.g. `--mcpu=atmega328`) | | |

!!! info "Legend"
    <ul>
    <li>:material-selection-ellipse: means automated tests or builds are not available</li>
    <li>:material-checkbox-marked-circle: means automated tests or builds are available</li>
    <li>:material-circle-slice-5: means automated test are available, but the implementation is incomplete</li>
    </li>

!!! note
    Big thanks go to the Rust team for putting together such a clear [document on Rust's platform support](https://forge.rust-lang.org/platform-support.html)
    that we used as inspiration for ours.
# pointerof

The `pointerof` expression returns a [Pointer](https://crystal-lang.org/api/Pointer.html) that points to the contents of a variable or instance variable.

An example with a variable:

```crystal
a = 1

ptr = pointerof(a)
ptr.value = 2

a # => 2
```

An example with an instance variable:

```crystal
class Point
  def initialize(@x : Int32, @y : Int32)
  end

  def x
    @x
  end

  def x_ptr
    pointerof(@x)
  end
end

point = Point.new 1, 2

ptr = point.x_ptr
ptr.value = 10

point.x # => 10
```

Because `pointerof` involves pointers, it is considered [unsafe](unsafe.md).
# Proc literal

A captured block is the same as declaring a [Proc literal](literals/proc.md) and [passing](block_forwarding.md) it to the method.

```crystal
def some_proc(&block : Int32 -> Int32)
  block
end

x = 0
proc = ->(i : Int32) { x += i }
proc = some_proc(&proc)
proc.call(1)  # => 1
proc.call(10) # => 11
x             # => 11
```

As explained in the [proc literals](literals/proc.md) section, a Proc can also be created from existing methods:

```crystal
def add(x, y)
  x + y
end

adder = ->add(Int32, Int32)
adder.call(1, 2) # => 3
```
# Requiring files

Writing a program in a single file is OK for little snippets and small benchmark code. Big programs are better maintained and understood when split across different files.

To make the compiler process other files you use `require "..."`. It accepts a single argument, a string literal, and it can come in many flavors.

Once a file is required, the compiler remembers its absolute path and later `require`s of that same file will be ignored.

## require "filename"

This looks up "filename" in the require path.

By default, the require path includes two locations:

* the `lib` directory relative to the current working directory (this is where dependencies are looked up)
* the location of the standard library that comes with the compiler

These are the only places that are looked up.

The exact paths used by the compiler can be queried as `crystal env CRYSTAL_PATH`:

```console
$ crystal env CRYSTAL_PATH
lib:/usr/bin/../share/crystal/src
```

These lookup paths can be overridden by defining the [`CRYSTAL_PATH` environment variable](../man/crystal/README.md#environment-variables).

The lookup goes like this:

* If a file named "filename.cr" is found in the require path, it is required.
* If a directory named "filename" is found and it contains a file named "filename.cr" directly underneath it, it is required.
* If a directory named "filename" is found with a directory "src" in it and it contains a file named "filename.cr" directly underneath it, it is required.
* Otherwise a compile-time error is issued.

The second rule means that in addition to having this:

```
- project
  - src
    - file
      - sub1.cr
      - sub2.cr
    - file.cr (requires "./file/*")
```

you can have it like this:

```
- project
  - src
    - file
      - file.cr (requires "./*")
      - sub1.cr
      - sub2.cr
```

which might be a bit cleaner depending on your taste.

The third rule is very convenient because of the typical directory structure of a project:

```
- project
  - lib
    - foo
      - src
        - foo.cr
    - bar
      - src
        - bar.cr
  - src
    - project.cr
  - spec
    - project_spec.cr
```

That is, inside "lib/{project}" each project's directory exists (`src`, `spec`, `README.md` and so on)

For example, if you put `require "foo"` in `project.cr` and run `crystal src/project.cr` in the project's root directory, it will find `foo` in `lib/foo/foo.cr`.

The fourth rule is the second rule applied to the third rule.

If you run the compiler from somewhere else, say the `src` folder, `lib` will not be in the path and `require "foo"` can't be resolved.

## require "./filename"

This looks up "filename" relative to the file containing the require expression.

The lookup goes like this:

* If a file named "filename.cr" is found relative to the current file, it is required.
* If a directory named "filename" is found and it contains a file named "filename.cr" directly underneath it, it is required.
* Otherwise a compile-time error is issued.

This relative is mostly used inside a project to refer to other files inside it. It is also used to refer to code from [specs](../guides/testing.md):

```crystal title="spec/spec_helper.cr"
require "../src/project"
```

## Other forms

In both cases you can use nested names and they will be looked up in nested directories:

* `require "foo/bar/baz"` will lookup "foo/bar/baz.cr", "foo/bar/baz/baz.cr", "foo/src/bar/baz.cr" or "foo/src/bar/baz/baz.cr" in the require path.
* `require "./foo/bar/baz"` will lookup "foo/bar/baz.cr" or "foo/bar/baz/baz.cr" relative to the current file.

You can also use "../" to access parent directories relative to the current file, so `require "../../foo/bar"` works as well.

In all of these cases you can use the special `*` and `**` suffixes:

* `require "foo/*"` will require all ".cr" files below the "foo" directory, but not below directories inside "foo".
* `require "foo/**"` will require all ".cr" files below the "foo" directory, and below directories inside "foo", recursively.
# responds_to?

The pseudo-method `responds_to?` determines whether a type has a method with the given name. For example:

```crystal
a = 1
a.responds_to?(:abs)  # => true
a.responds_to?(:size) # => false
```

It is a pseudo-method because it only accepts a symbol literal as its argument, and is also treated specially by the compiler, as explained in [if var.responds_to?(...)](if_varresponds_to.md).
# Return types

A method's return type is always inferred by the compiler. However, you might want to specify it for two reasons:

1. To make sure that the method returns the type that you want
2. To make it appear in documentation comments

For example:

```crystal
def some_method : String
  "hello"
end
```

The return type follows the [type grammar](type_grammar.md).

## Nil return type

Marking a method as returning `Nil` will make it return `nil` regardless of what it actually returns:

```crystal
def some_method : Nil
  1 + 2
end

some_method # => nil
```

This is useful for two reasons:

1. Making sure a method returns `nil` without needing to add an extra `nil` at the end, or at every return point
2. Documenting that the method's return value is of no interest

These methods usually imply a side effect.

Using `Void` is the same, but `Nil` is more idiomatic: `Void` is preferred in C bindings.

## NoReturn return type

Some expressions won't return to the current scope and therefore have no return type. This is expressed as the special return type `NoReturn`.

Typical examples for non-returning methods and keywords are `return`, `exit`, `raise`, `next`, and `break`.

This is for example useful for deconstructing union types:

```crystal
string = STDIN.gets
typeof(string)                        # => String?
typeof(raise "Empty input")           # => NoReturn
typeof(string || raise "Empty input") # => String
```

The compiler recognizes that in case `string` is `Nil`, the right hand side of the expression `string || raise` will be evaluated. Since `typeof(raise "Empty input")` is `NoReturn` the execution would not return to the current scope in that case. That leaves only `String` as resulting type of the expression.

Every expression whose code paths all result in `NoReturn` will be `NoReturn` as well. `NoReturn` does not show up in a union type because it would essentially be included in every expression's type. It is only used when an expression will never return to the current scope.

`NoReturn` can be explicitly set as return type of a method or function definition but will usually be inferred by the compiler.
# select

The `select` expression chooses from a set of blocking operations and proceeds with the branch that becomes available first.

## Syntax

The expression starts with the keyword `select`, followed by a list of one or more `when` branches.
Each branch has a condition and a body, separated by either
a statement separator or the keyword `then`.
Optionally, the last branch may be `else` (without condition).  This denotes the `select` action as non-blocking.
The expression closes with an `end` keyword.

> NOTE:
> `select` is similar to a [`case` expression](./case.md) with all branches referring to potentially blocking operations.

Each condition is either a call to a select action or an assignment whose right-hand side is a call to a select action.

```crystal
select
when foo = foo_channel.receive
  puts foo
when bar = bar_channel.receive?
  puts bar
when baz_channel.send
  exit
when timeout(5.seconds)
  puts "Timeout"
end
```

## Select actions

A select action call calls a method with the implicit suffix `_select_action`,
or `_select_action?` for a call with `?` suffix.
This method returns an instance of the select action.

The `select` expression initiates the select action associated with each branch. If either of them immediately returns, it proceeds with that.
Otherwise it waits for completion. As soon as one branch completes, all
others are canceled.
An `else` branch completes immediately so there will not be any waiting.

Execution continues in the completed branch.
If the branch condition is an assignment, the result of the select call is assigned to the target variable.

<!-- markdownlint-disable MD046 -->

!!! info "Select actions in the standard library"
    The standard library provides the following select actions:

    * `Channel#send_select_action`
    * `Channel#receive_select_action`
    * `Channel#receive_select_action?`
    * [`::timeout_select_action`](https://crystal-lang.org/api/toplevel.html#timeout_select_action(timeout:Time::Span):Channel::TimeoutAction-class-method)
# sizeof

The `sizeof` expression returns an `Int32` with the size in bytes of a given type. For example:

```crystal
sizeof(Int32) # => 4
sizeof(Int64) # => 8
```

For [Reference](https://crystal-lang.org/api/Reference.html) types, the size is the same as the size of a pointer:

```crystal
# On a 64-bit machine
sizeof(Pointer(Int32)) # => 8
sizeof(String)         # => 8
```

This is because `Reference`'s memory is allocated on the heap and a pointer to it is passed around. To get the effective size of a class, use [instance_sizeof](instance_sizeof.md).

The argument to sizeof is a [type](type_grammar.md) and is often combined with [typeof](typeof.md):

```crystal
a = 1
sizeof(typeof(a)) # => 4
```

`sizeof` can be used in the macro language, but only on types with stable size and alignment. See the API docs of [`sizeof`](https://crystal-lang.org/api/Crystal/Macros.html#sizeof(type):NumberLiteral-instance-method) for details.
# Splats and tuples

A method can receive a variable number of arguments by using a *splat parameter* (`*`), which can appear only once and in any position:

```crystal
def sum(*elements)
  total = 0
  elements.each do |value|
    total += value
  end
  total
end

sum 1, 2, 3      # => 6
sum 1, 2, 3, 4.5 # => 10.5
```

The passed arguments become a [Tuple](https://crystal-lang.org/api/Tuple.html) in the method's body:

```crystal
# elements is Tuple(Int32, Int32, Int32)
sum 1, 2, 3

# elements is Tuple(Int32, Int32, Int32, Float64)
sum 1, 2, 3, 4.5
```

Arguments past the splat parameter can only be passed as named arguments:

```crystal
def sum(*elements, initial = 0)
  total = initial
  elements.each do |value|
    total += value
  end
  total
end

sum 1, 2, 3              # => 6
sum 1, 2, 3, initial: 10 # => 16
```

Parameters past the splat parameter without a default value are required named parameters:

```crystal
def sum(*elements, initial)
  total = initial
  elements.each do |value|
    total += value
  end
  total
end

sum 1, 2, 3              # Error, missing argument: initial
sum 1, 2, 3, initial: 10 # => 16
```

Two methods with different required named parameters overload between each other:

```crystal
def foo(*elements, x)
  1
end

def foo(*elements, y)
  2
end

foo x: "something" # => 1
foo y: "something" # => 2
```

The splat parameter can also be left unnamed, with the meaning "after this, named parameters follow":

```crystal
def foo(x, y, *, z)
end

foo 1, 2, 3    # Error, wrong number of arguments (given 3, expected 2)
foo 1, 2       # Error, missing argument: z
foo 1, 2, z: 3 # OK
```

## Splatting a tuple

A `Tuple` can be splat into a method call by using `*`:

```crystal
def foo(x, y)
  x + y
end

tuple = {1, 2}
foo *tuple # => 3
```

## Double splats and named tuples

A double splat (`**`) captures named arguments that were not matched by other parameters. The type of the parameter is a `NamedTuple`:

```crystal
def foo(x, **other)
  # Return the captured named arguments as a NamedTuple
  other
end

foo 1, y: 2, z: 3    # => {y: 2, z: 3}
foo y: 2, x: 1, z: 3 # => {y: 2, z: 3}
```

## Double splatting a named tuple

A `NamedTuple` can be splat into a method call by using `**`:

```crystal
def foo(x, y)
  x - y
end

tuple = {y: 3, x: 10}
foo **tuple # => 7
```
# Structs

Instead of defining a type with `class` you can do so with `struct`:

```crystal
struct Point
  property x, y

  def initialize(@x : Int32, @y : Int32)
  end
end
```

Structs inherit from [Value](https://crystal-lang.org/api/Value.html) so they are allocated on the stack and passed by value: when passed to methods, returned from methods or assigned to variables, a copy of the value is actually passed (while classes inherit from [Reference](https://crystal-lang.org/api/Reference.html), are allocated on the heap and passed by reference).

Therefore structs are mostly useful for immutable data types and/or stateless wrappers of other types, usually for performance reasons to avoid lots of small memory allocations when passing small copies might be more efficient (for more details, see the [performance guide](https://crystal-lang.org/docs/guides/performance.html#use-structs-when-possible)).

Mutable structs are still allowed, but you should be careful when writing code involving mutability if you want to avoid surprises that are described below.

## Passing by value

A struct is *always* passed by value, even when you return `self` from the method of that struct:

```crystal
struct Counter
  def initialize(@count : Int32)
  end

  def plus
    @count += 1
    self
  end
end

counter = Counter.new(0)
counter.plus.plus # => Counter(@count=2)
puts counter      # => Counter(@count=1)
```

Notice that the chained calls of `plus` return the expected result, but only the first call to it modifies the variable `counter`, as the second call operates on the *copy* of the struct passed to it from the first call, and this copy is discarded after the expression is executed.

You should also be careful when working on mutable types inside of the struct:

```crystal
class Klass
  property array = ["str"]
end

struct Strukt
  property array = ["str"]
end

def modify(object)
  object.array << "foo"
  object.array = ["new"]
  object.array << "bar"
end

klass = Klass.new
puts modify(klass) # => ["new", "bar"]
puts klass.array   # => ["new", "bar"]

strukt = Strukt.new
puts modify(strukt) # => ["new", "bar"]
puts strukt.array   # => ["str", "foo"]
```

What happens with the `strukt` here:

* `Array` is passed by reference, so the reference to `["str"]` is stored in the property of `strukt`
* when `strukt` is passed to `modify`, a *copy* of the `strukt` is passed with the reference to array inside it
* the array referenced by `array` is modified (element inside it is added) by `object.array << "foo"`
* this is also reflected in the original `strukt` as it holds reference to the same array
* `object.array = ["new"]` replaces the reference in the *copy* of `strukt` with the reference to the new array
* `object.array << "bar"` appends to this newly created array
* `modify` returns the reference to this new array and its content is printed
* the reference to this new array was held only in the *copy* of `strukt`, but not in the original, so that's why the original `strukt` only retained the result of the first statement, but not of the other two statements

`Klass` is a class, so it is passed by reference to `modify`, and `object.array = ["new"]` saves the reference to the newly created array in the original `klass` object, not in the copy as it was with the `strukt`.

## Inheritance

* A struct implicitly inherits from [Struct](https://crystal-lang.org/api/Struct.html), which inherits from [Value](https://crystal-lang.org/api/Value.html). A class implicitly inherits from [Reference](https://crystal-lang.org/api/Reference.html).
* A struct cannot inherit from a non-abstract struct.

The second point has a reason to it: a struct has a very well defined memory layout. For example, the above `Point` struct occupies 8 bytes. If you have an array of points the points are embedded inside the array's buffer:

```crystal
# The array's buffer will have 8 bytes dedicated to each Point
ary = [] of Point
```

If `Point` is inherited, an array of such type should also account for the fact that other types can be inside it, so the size of each element should grow to accommodate that. That is certainly unexpected. So, non-abstract structs can't be inherited from. Abstract structs, on the other hand, will have descendants, so it is expected that an array of them will account for the possibility of having multiple types inside it.

A struct can also include modules and can be generic, just like a class.

## Records

The Crystal [Standard Library](https://crystal-lang.org/api) provides the [`record`](https://crystal-lang.org/api/toplevel.html#record(name,*properties)-macro) macro. It simplifies the definition of basic struct types with an initializer and some helper methods.

```crystal
record Point, x : Int32, y : Int32

Point.new 1, 2 # => #<Point(@x=1, @y=2)>
```

The `record` macro expands to the following struct definition:

```cr
struct Point
  getter x : Int32

  getter y : Int32

  def initialize(@x : Int32, @y : Int32)
  end

  def copy_with(x _x = @x, y _y = @y)
    self.class.new(_x, _y)
  end

  def clone
    self.class.new(@x.clone, @y.clone)
  end
end
```
# Ternary if

The ternary `if` allows writing an `if` in a shorter way:

```crystal
a = 1 > 2 ? 3 : 4

# The above is the same as:
a = if 1 > 2
      3
    else
      4
    end
```
# Program

The program is the entirety of the source code worked by the compiler. The source gets parsed and compiled to an executable version of the program.

The program’s source code must be encoded in UTF-8.

## Top-level scope

Features such as types, constants, macros and methods defined outside any other namespace are in the top-level scope.

```crystal
# Defines a method in the top-level scope
def add(x, y)
  x + y
end

# Invokes the add method on the top-level scope
add(1, 2) # => 3
```

Local variables in the top-level scope are file-local and not visible inside method bodies.

```crystal
x = 1

def add(y)
  x + y # error: undefined local variable or method 'x'
end

add(2)
```

Private features are also only visible in the current file.

A double colon prefix (`::`) unambiguously references a namespace, constant, method or macro in the top-level scope:

```crystal
def baz
  puts "::baz"
end

CONST = "::CONST"

module A
  def self.baz
    puts "A.baz"
  end

  # Without prefix, resolves to the method in the local scope
  baz

  # With :: prefix, resolves to the method in the top-level scope
  ::baz

  CONST = "A::Const"

  p! CONST   # => "A::CONST"
  p! ::CONST # => "::CONST"
end
```

### Main code

Any expression that is neither a method, macro, constant or type definition, or in a method or macro body,
is part of the main code.
Main code is executed when the program starts in the order of the source file's inclusion.

There is no need to use a special entry point for the main code (such as a `main` method).

```crystal
# This is a program that prints "Hello Crystal!"
puts "Hello Crystal!"
```

Main code can also be inside namespaces:

```crystal
# This is a program that prints "Hello"
class Hello
  # 'self' here is the Hello class
  puts self
end
```
# Truthy and falsey values

A *truthy* value is a value that is considered true for an `if`, `unless`, `while` or `until` guard. A *falsey* value is a value that is considered false in those places.

The only falsey values are `nil`, `false` and null pointers (pointers whose memory address is zero). Any other value is truthy.
# Type grammar

When:

* specifying [type restrictions](type_restrictions.md)
* specifying [type arguments](generics.md)
* [declaring variables](declare_var.md)
* declaring [aliases](alias.md)
* declaring [typedefs](c_bindings/type.md)
* the argument of an [is_a?](is_a.md) pseudo-call
* the argument of an [as](as.md) expression
* the argument of a [sizeof](sizeof.md) or [instance_sizeof](instance_sizeof.md) expression
* the argument of an [alignof](alignof.md) or [instance_alignof](instance_alignof.md) expression
* a method's [return type](return_types.md)

a convenient syntax is provided for some common types. These are especially useful when writing [C bindings](c_bindings/README.md), but can be used in any of the above locations.

## Paths and generics

Regular types and generics can be used:

```crystal
Int32
My::Nested::Type
Array(String)
```

## Union

```crystal
alias Int32OrString = Int32 | String
```

The pipe (`|`) in types creates a union type. `Int32 | String` is read "Int32 or String". In regular code, `Int32 | String` means invoking the method `|` on `Int32` with `String` as an argument.

## Nilable

```crystal
alias Int32OrNil = Int32?
```

is the same as:

```crystal
alias Int32OrNil = Int32 | ::Nil
```

In regular code, `Int32?` is an `Int32 | ::Nil` union type itself.

## Pointer

```crystal
alias Int32Ptr = Int32*
```

is the same as:

```crystal
alias Int32Ptr = Pointer(Int32)
```

In regular code, `Int32*` means invoking the `*` method on `Int32`.

## StaticArray

```crystal
alias Int32_8 = Int32[8]
```

is the same as:

```crystal
alias Int32_8 = StaticArray(Int32, 8)
```

In regular code, `Int32[8]` means invoking the `[]` method on `Int32` with `8` as an argument.

## Tuple

```crystal
alias Int32StringTuple = {Int32, String}
```

is the same as:

```crystal
alias Int32StringTuple = Tuple(Int32, String)
```

In regular code, `{Int32, String}` is a tuple instance containing `Int32` and `String` as its elements. This is different than the above tuple **type**.

## NamedTuple

```crystal
alias Int32StringNamedTuple = {x: Int32, y: String}
```

is the same as:

```crystal
alias Int32StringNamedTuple = NamedTuple(x: Int32, y: String)
```

In regular code, `{x: Int32, y: String}` is a named tuple instance containing `Int32` and `String` for `x` and `y`. This is different than the above named tuple **type**.

## Proc

```crystal
alias Int32ToString = Int32 -> String
```

is the same as:

```crystal
alias Int32ToString = Proc(Int32, String)
```

To specify a Proc without parameters:

```crystal
alias ProcThatReturnsInt32 = -> Int32
```

To specify multiple parameters:

```crystal
alias Int32AndCharToString = Int32, Char -> String
```

For nested procs (and any type, in general), you can use parentheses:

```crystal
alias ComplexProc = (Int32 -> Int32) -> String
```

In regular code `Int32 -> String` is a syntax error.

## self

`self` can be used in the type grammar to denote a `self` type. Refer to the [type restrictions](type_restrictions.md) section.

## class

`class` is used to refer to a class type, instead of an instance type.

For example:

```crystal
def foo(x : Int32)
  "instance"
end

def foo(x : Int32.class)
  "class"
end

foo 1     # "instance"
foo Int32 # "class"
```

`class` is also useful for creating arrays and collections of class type:

```crystal
class Parent
end

class Child1 < Parent
end

class Child2 < Parent
end

ary = [] of Parent.class
ary << Child1
ary << Child2
```

## Underscore

An underscore is allowed in type restrictions. It matches anything:

```crystal
# Same as not specifying a restriction, not very useful
def foo(x : _)
end

# A bit more useful: any two-parameter Proc that returns an Int32:
def foo(x : _, _ -> Int32)
end
```

In regular code `_` means the [underscore](assignment.md#underscore) variable.

## typeof

`typeof` is allowed in the type grammar. It returns a union type of the type of the passed expressions:

```crystal
typeof(1 + 2)  # => Int32
typeof(1, "a") # => (Int32 | String)
```
# Type inference

Crystal's philosophy is to require as few type restrictions as possible. However, some restrictions are required.

Consider a class definition like this:

```crystal
class Person
  def initialize(@name)
    @age = 0
  end
end
```

We can quickly see that `@age` is an integer, but we don't know the type of `@name`. The compiler could infer its type from all uses of the `Person` class. However, doing so has a few issues:

* The type is not obvious for a human reading the code: they would also have to check all uses of `Person` to find this out.
* Some compiler optimizations, like having to analyze a method just once, and incremental compilation, are nearly impossible to do.

As a code base grows, these issues gain more relevance: understanding a project becomes harder, and compile times become unbearable.

For this reason, Crystal needs to know, in an obvious way (as obvious as to a human), the types of instance and [class](class_variables.md) variables.

There are several ways to let Crystal know this.

## With type restrictions

The easiest, but probably most tedious, way is to use explicit type restrictions.

```crystal
class Person
  @name : String
  @age : Int32

  def initialize(@name)
    @age = 0
  end
end
```

## Without type restrictions

If you omit an explicit type restriction, the compiler will try to infer the type of instance and class variables using a bunch of syntactic rules.

For a given instance/class variable, when a rule can be applied and a type can be guessed, the type is added to a set. When no more rules can be applied, the inferred type will be the [union](union_types.md) of those types. Additionally, if the compiler infers that an instance variable isn't always initialized, it will also include the [Nil](literals/nil.md) type.

The rules are many, but usually the first three are most used. There's no need to remember them all. If the compiler gives an error saying that the type of an instance variable can't be inferred you can always add an explicit type restriction.

The following rules only mention instance variables, but they apply to class variables as well. They are:

### 1. Assigning a literal value

When a literal is assigned to an instance variable, the literal's type is added to the set. All [literals](literals/README.md) have an associated type.

In the following example, `@name` is inferred to be `String` and `@age` to be `Int32`.

```crystal
class Person
  def initialize
    @name = "John Doe"
    @age = 0
  end
end
```

This rule, and every following rule, will also be applied in methods other than `initialize`. For example:

```crystal
class SomeObject
  def lucky_number
    @lucky_number = 42
  end
end
```

In the above case, `@lucky_number` will be inferred to be `Int32 | Nil`: `Int32` because 42 was assigned to it, and `Nil` because it wasn't assigned in all of the class' initialize methods.

### 2. Assigning the result of invoking the class method `new`

When an expression like `Type.new(...)` is assigned to an instance variable, the type `Type` is added to the set.

In the following example, `@address` is inferred to be `Address`.

```crystal
class Person
  def initialize
    @address = Address.new("somewhere")
  end
end
```

This also is applied to generic types. Here `@values` is inferred to be `Array(Int32)`.

```crystal
class Something
  def initialize
    @values = Array(Int32).new
  end
end
```

**Note**: a `new` method might be redefined by a type. In that case the inferred type will be the one returned by `new`, if it can be inferred using some of the next rules.

### 3. Assigning a variable that is a method parameter with a type restriction

In the following example `@name` is inferred to be `String` because the method parameter `name` has a type restriction of type `String`, and that parameter is assigned to `@name`.

```crystal
class Person
  def initialize(name : String)
    @name = name
  end
end
```

Note that the name of the method parameter is not important; this works as well:

```crystal
class Person
  def initialize(obj : String)
    @name = obj
  end
end
```

Using the shorter syntax to assign an instance variable from a method parameter has the same effect:

```crystal
class Person
  def initialize(@name : String)
  end
end
```

Also note that the compiler doesn't check whether a method parameter is reassigned a different value:

```crystal
class Person
  def initialize(name : String)
    name = 1
    @name = name
  end
end
```

In the above case, the compiler will still infer `@name` to be `String`, and later will give a compile time error, when fully typing that method, saying that `Int32` can't be assigned to a variable of type `String`. Use an explicit type restriction if `@name` isn't supposed to be a `String`.

### 4. Assigning the result of a class method that has a return type restriction

In the following example, `@address` is inferred to be `Address`, because the class method `Address.unknown` has a return type restriction of `Address`.

```crystal
class Person
  def initialize
    @address = Address.unknown
  end
end

class Address
  def self.unknown : Address
    new("unknown")
  end

  def initialize(@name : String)
  end
end
```

In fact, the above code doesn't need the return type restriction in `self.unknown`. The reason is that the compiler will also look at a class method's body and if it can apply one of the previous rules (it's a `new` method, or it's a literal, etc.) it will infer the type from that expression. So, the above can be simply written like this:

```crystal
class Person
  def initialize
    @address = Address.unknown
  end
end

class Address
  # No need for a return type restriction here
  def self.unknown
    new("unknown")
  end

  def initialize(@name : String)
  end
end
```

This extra rule is very convenient because it's very common to have "constructor-like" class methods in addition to `new`.

### 5. Assigning a variable that is a method parameter with a default value

In the following example, because the default value of `name` is a string literal, and it's later assigned to `@name`, `String` will be added to the set of inferred types.

```crystal
class Person
  def initialize(name = "John Doe")
    @name = name
  end
end
```

This of course also works with the short syntax:

```crystal
class Person
  def initialize(@name = "John Doe")
  end
end
```

The default parameter value can also be a `Type.new(...)` method or a class method with a return type restriction.

### 6. Assigning the result of invoking a `lib` function

Because a [lib function](c_bindings/fun.md) must have explicit types, the compiler can use the return type when assigning it to an instance variable.

In the following example `@age` is inferred to be `Int32`.

```crystal
class Person
  def initialize
    @age = LibPerson.compute_default_age
  end
end

lib LibPerson
  fun compute_default_age : Int32
end
```

### 7. Using an `out` lib expression

Because a [lib function](c_bindings/fun.md) must have explicit types, the compiler can use the `out` argument's type, which should be a pointer type, and use the dereferenced type as a guess.

In the following example `@age` is inferred to be `Int32`.

```crystal
class Person
  def initialize
    LibPerson.compute_default_age(out @age)
  end
end

lib LibPerson
  fun compute_default_age(age_ptr : Int32*)
end
```

### Other rules

The compiler will try to be as smart as possible to require less explicit type restrictions. For example, if assigning an `if` expression, type will be inferred from the `then` and `else` branches:

```crystal
class Person
  def initialize
    @age = some_condition ? 1 : 2
  end
end
```

Because the `if` above (well, technically a ternary operator, but it's similar to an `if`) has integer literals, `@age` is successfully inferred to be `Int32` without requiring a redundant type restriction.

Another case is `||` and `||=`:

```crystal
class SomeObject
  def lucky_number
    @lucky_number ||= 42
  end
end
```

In the above example `@lucky_number` will be inferred to be `Int32 | Nil`. This is very useful for lazily initialized variables.

Constants will also be followed, as it's pretty simple for the compiler (and a human) to do so.

```crystal
class SomeObject
  DEFAULT_LUCKY_NUMBER = 42

  def initialize(@lucky_number = DEFAULT_LUCKY_NUMBER)
  end
end
```

Here rule 5 (default parameter value) is used, and because the constant resolves to an integer literal, `@lucky_number` is inferred to be `Int32`.
# Type reflection

Crystal provides basic methods to do type reflection, casting and introspection.
# Type restrictions

Type restrictions are applied to method parameters to restrict the types accepted by that method.

```crystal
def add(x : Number, y : Number)
  x + y
end

# Ok
add 1, 2

# Error: no overload matches 'add' with types Bool, Bool
add true, false
```

Note that if we had defined `add` without type restrictions, we would also have gotten a compile time error:

```crystal
def add(x, y)
  x + y
end

add true, false
```

The above code gives this compile error:

```
Error in foo.cr:6: instantiating 'add(Bool, Bool)'

add true, false
^~~

in foo.cr:2: undefined method '+' for Bool

  x + y
    ^
```

This is because when you invoke `add`, it is instantiated with the types of the arguments: every method invocation with a different type combination results in a different method instantiation.

The only difference is that the first error message is a little more clear, but both definitions are safe in that you will get a compile time error anyway. So, in general, it's preferable not to specify type restrictions and almost only use them to define different method overloads. This results in more generic, reusable code. For example, if we define a class that has a `+` method but isn't a `Number`, we can use the `add` method that doesn't have type restrictions, but we can't use the `add` method that has restrictions.

```crystal
# A class that has a + method but isn't a Number
class Six
  def +(other)
    6 + other
  end
end

# add method without type restrictions
def add(x, y)
  x + y
end

# OK
add Six.new, 10

# add method with type restrictions
def restricted_add(x : Number, y : Number)
  x + y
end

# Error: no overload matches 'restricted_add' with types Six, Int32
restricted_add Six.new, 10
```

Refer to the [type grammar](type_grammar.md) for the notation used in type restrictions.

Note that type restrictions do not apply to the variables inside the actual methods.

```crystal
def handle_path(path : String)
  path = Path.new(path) # *path* is now of the type Path
  # Do something with *path*
end
```

## Restrictions from instance variables

In some cases it is possible to restrict the type of a method's parameter based on its usage. For instance, consider the following example:

```crystal
class Foo
  @x : Int64

  def initialize(x)
    @x = x
  end
end
```

In this case we know that the parameter `x` from the initialization function must be an `Int64`, and there is no point in leave it unrestricted.

When the compiler finds an assignment from a method parameter to an instance variable, then it inserts such a restriction. In the example above, calling `Foo.new "hi"` fails with (note the type restriction):

```
Error: no overload matches 'Foo.new' with type String

Overloads are:
 - Foo.new(x : ::Int64)
```

## self restriction

A special type restriction is `self`:

```crystal
class Person
  def ==(other : self)
    other.name == name
  end

  def ==(other)
    false
  end
end

john = Person.new "John"
another_john = Person.new "John"
peter = Person.new "Peter"

john == another_john # => true
john == peter        # => false (names differ)
john == 1            # => false (because 1 is not a Person)
```

In the previous example `self` is the same as writing `Person`. But, in general, `self` is the same as writing the type that will finally own that method, which, when modules are involved, becomes more useful.

As a side note, since `Person` inherits `Reference` the second definition of `==` is not needed, since it's already defined in `Reference`.

Note that `self` always represents a match against an instance type, even in class methods:

```crystal
class Person
  getter name : String

  def initialize(@name)
  end

  def self.compare(p1 : self, p2 : self)
    p1.name == p2.name
  end
end

john = Person.new "John"
peter = Person.new "Peter"

Person.compare(john, peter) # OK
```

You can use `self.class` to restrict to the Person type. The next section talks about the `.class` suffix in type restrictions.

## Classes as restrictions

Using, for example, `Int32` as a type restriction makes the method only accept instances of `Int32`:

```crystal
def foo(x : Int32)
end

foo 1       # OK
foo "hello" # Error
```

If you want a method to only accept the type Int32 (not instances of it), you use `.class`:

```crystal
def foo(x : Int32.class)
end

foo Int32  # OK
foo String # Error
```

The above is useful for providing overloads based on types, not instances:

```crystal
def foo(x : Int32.class)
  puts "Got Int32"
end

def foo(x : String.class)
  puts "Got String"
end

foo Int32  # prints "Got Int32"
foo String # prints "Got String"
```

## Type restrictions in splats

You can specify type restrictions in splats:

```crystal
def foo(*args : Int32)
end

def foo(*args : String)
end

foo 1, 2, 3       # OK, invokes first overload
foo "a", "b", "c" # OK, invokes second overload
foo 1, 2, "hello" # Error
foo()             # Error
```

When specifying a type, all elements in a tuple must match that type. Additionally, the empty-tuple doesn't match any of the above cases. If you want to support the empty-tuple case, add another overload:

```crystal
def foo
  # This is the empty-tuple case
end
```

A simple way to match against one or more elements of any type is to use `_` as a restriction:

```crystal
def foo(*args : _)
end

foo()       # Error
foo(1)      # OK
foo(1, "x") # OK
```

## Free variables

You can make a type restriction take the type of an argument, or part of the type of an argument, using `forall`:

```crystal
def foo(x : T) forall T
  T
end

foo(1)       # => Int32
foo("hello") # => String
```

That is, `T` becomes the type that was effectively used to instantiate the method.

A free variable can be used to extract the type argument of a generic type within a type restriction:

```crystal
def foo(x : Array(T)) forall T
  T
end

foo([1, 2])   # => Int32
foo([1, "a"]) # => (Int32 | String)
```

To create a method that accepts a type name, rather than an instance of a type, append `.class` to a free variable in the type restriction:

```crystal
def foo(x : T.class) forall T
  Array(T)
end

foo(Int32)  # => Array(Int32)
foo(String) # => Array(String)
```

Multiple free variables can be specified too, for matching types of multiple arguments:

```crystal
def push(element : T, array : Array(T)) forall T
  array << element
end

push(4, [1, 2, 3])      # OK
push("oops", [1, 2, 3]) # Error
```

## Splat type restrictions

If a splat parameter's restriction also has a splat, the restriction must name a [`Tuple`](https://crystal-lang.org/api/Tuple.html) type, and the arguments corresponding to the parameter must match the elements of the splat restriction:

```crystal
def foo(*x : *{Int32, String})
end

foo(1, "") # OK
foo("", 1) # Error
foo(1)     # Error
```

It is extremely rare to specify a tuple type in a splat restriction directly, since the above can be expressed by simply not using a splat (i.e. `def foo(x : Int32, y : String)`. However, if the restriction is a free variable instead, then it is inferred to be a `Tuple` containing the types of all corresponding arguments:

```crystal
def foo(*x : *T) forall T
  T
end

foo(1, 2)  # => Tuple(Int32, Int32)
foo(1, "") # => Tuple(Int32, String)
foo(1)     # => Tuple(Int32)
foo()      # => Tuple()
```

On the last line, `T` is inferred to be the empty tuple, which is not possible for a splat parameter having a non-splat restriction.

Double splat parameters similarly support double splat type restrictions:

```crystal
def foo(**x : **T) forall T
  T
end

foo(x: 1, y: 2)  # => NamedTuple(x: Int32, y: Int32)
foo(x: 1, y: "") # => NamedTuple(x: Int32, y: String)
foo(x: 1)        # => NamedTuple(x: Int32)
foo()            # => NamedTuple()
```

Additionally, single splat restrictions may be used inside a generic type as well, to extract multiple type arguments at once:

```crystal
def foo(x : Proc(*T, Int32)) forall T
  T
end

foo(->(x : Int32, y : Int32) { x + y }) # => Tuple(Int32, Int32)
foo(->(x : Bool) { x ? 1 : 0 })         # => Tuple(Bool)
foo(-> { 1 })                           # => Tuple()
```
# typeof

The `typeof` expression returns the type of an expression:

```crystal
a = 1
b = typeof(a) # => Int32
```

It accepts multiple arguments, and the result is the union of the expression types:

```crystal
typeof(1, "a", 'a') # => (Int32 | String | Char)
```

It is often used in generic code, to make use of the compiler's type inference capabilities:

```crystal
hash = {} of Int32 => String
another_hash = typeof(hash).new # :: Hash(Int32, String)
```

Since `typeof` doesn't actually evaluate the expression, it can be
used on methods at compile time, such as in this example, which
recursively forms a union type out of nested generic types:

```crystal
class Array
  def self.elem_type(typ)
    if typ.is_a?(Array)
      elem_type(typ.first)
    else
      typ
    end
  end
end

nest = [1, ["b", [:c, ['d']]]]
flat = Array(typeof(Array.elem_type(nest))).new
typeof(nest) # => Array(Int32 | Array(String | Array(Symbol | Array(Char))))
typeof(flat) # => Array(String | Int32 | Symbol | Char)
```

This expression is also available in the [type grammar](type_grammar.md).
# Types and methods

The next sections will assume you know what [object oriented programming](http://en.wikipedia.org/wiki/Object-oriented_programming) is, as well as the concepts of [classes](http://en.wikipedia.org/wiki/Class_%28computer_programming%29) and [methods](http://en.wikipedia.org/wiki/Method_%28computer_programming%29).
# Union types

The type of a variable or expression can consist of multiple types. This is called a union type. For example, when assigning to a same variable inside different [if](if.md) branches:

```crystal
if 1 + 2 == 3
  a = 1
else
  a = "hello"
end

a # : Int32 | String
```

At the end of the if, `a` will have the `Int32 | String` type, read "the union of Int32 and String". This union type is created automatically by the compiler. At runtime, `a` will of course be of one type only. This can be seen by invoking the `class` method:

```crystal
# The runtime type
a.class # => Int32
```

The compile-time type can be seen by using [typeof](typeof.md):

```crystal
# The compile-time type
typeof(a) # => Int32 | String
```

A union can consist of an arbitrary large number of types. When invoking a method on an expression whose type is a union type, all types in the union must respond to the method, otherwise a compile-time error is given. The type of the method call is the union type of the return types of those methods.

```crystal
# to_s is defined for Int32 and String, it returns String
a.to_s # => String

a + 1 # Error, because String#+(Int32) isn't defined
```

If necessary a variable can be defined as a union type at compile time

```crystal
# set the compile-time type
a = 0.as(Int32 | Nil | String)
typeof(a) # => Int32 | Nil | String
```

## Union types rules

In the general case, when two types `T1` and `T2` are combined, the result is a union `T1 | T2`. However, there are a few cases where the resulting type is a different type.

### Union of classes and structs under the same hierarchy

If `T1` and `T2` are under the same hierarchy, and their nearest common ancestor `Parent` is not `Reference`, `Struct`, `Int`, `Float` nor `Value`, the resulting type is `Parent+`. This is called a virtual type, which basically means the compiler will now see the type as being `Parent` or any of its subtypes.

For example:

```crystal
class Foo
end

class Bar < Foo
end

class Baz < Foo
end

bar = Bar.new
baz = Baz.new

# Here foo's type will be Bar | Baz,
# but because both Bar and Baz inherit from Foo,
# the resulting type is Foo+
foo = rand < 0.5 ? bar : baz
typeof(foo) # => Foo+
```

### Union of tuples of the same size

The union of two tuples of the same size results in a tuple type that has the union of the types in each position.

For example:

```crystal
t1 = {1, "hi"}   # Tuple(Int32, String)
t2 = {true, nil} # Tuple(Bool, Nil)

t3 = rand < 0.5 ? t1 : t2
typeof(t3) # Tuple(Int32 | Bool, String | Nil)
```

### Union of named tuples with the same keys

The union of two named tuples with the same keys (regardless of their order) results in a named tuple type that has the union of the types in each key. The order of the keys will be the ones from the tuple on the left hand side.

For example:

```crystal
t1 = {x: 1, y: "hi"}   # Tuple(x: Int32, y: String)
t2 = {y: true, x: nil} # Tuple(y: Bool, x: Nil)

t3 = rand < 0.5 ? t1 : t2
typeof(t3) # NamedTuple(x: Int32 | Nil, y: String | Bool)
```
# unless

An `unless` evaluates the then branch if its condition is *falsey*, and evaluates the `else branch`, if there’s any, otherwise. That is, it behaves in the opposite way of an `if`:

```crystal
unless some_condition
  expression_when_falsey
else
  expression_when_truthy
end

# The above is the same as:
if some_condition
  expression_when_truthy
else
  expression_when_falsey
end

# Can also be written as a suffix
close_door unless door_closed?
```
# Unsafe code

These parts of the language are considered unsafe:

* Code involving raw pointers: the [Pointer](https://crystal-lang.org/api/Pointer.html) type and [pointerof](pointerof.md).
* The [allocate](new,_initialize_and_allocate.md) class method.
* Code involving C bindings
* [Uninitialized variable declaration](declare_var.md)

"Unsafe" means that memory corruption, segmentation faults and crashes are possible to achieve. For example:

```crystal
a = 1
ptr = pointerof(a)
ptr[100_000] = 2 # undefined behaviour, probably a segmentation fault
```

However, regular code usually never involves pointer manipulation or uninitialized variables. And C bindings are usually wrapped in safe wrappers that include null pointers and bounds checks.

No language is 100% safe: some parts will inevitably be low-level, interface with the operating system and involve pointer manipulation. But once you abstract that and operate on a higher level, and assume (after mathematical proof or thorough testing) that the lower grounds are safe, you can be confident that your entire codebase is safe.
# until

An `until` executes its body until its condition is *truthy*. An `until` is just syntax sugar for a `while` with the condition negated:

```crystal
until some_condition
  do_this
end

# The above is the same as:
while !some_condition
  do_this
end
```

`break` and `next` can also be used inside an `until`, and like in `while` expressions, `break`s may be used to return values from an `until`.
# Virtual and abstract types

When a variable's type combines different types under the same class hierarchy, its type becomes a **virtual type**. This applies to every class and struct except for `Reference`, `Value`, `Int` and `Float`. An example:

```crystal
class Animal
end

class Dog < Animal
  def talk
    "Woof!"
  end
end

class Cat < Animal
  def talk
    "Miau"
  end
end

class Person
  getter pet

  def initialize(@name : String, @pet : Animal)
  end
end

john = Person.new "John", Dog.new
peter = Person.new "Peter", Cat.new
```

If you compile the above program with the `tool hierarchy` command you will see this for `Person`:

```
- class Object
  |
  +- class Reference
     |
     +- class Person
            @name : String
            @pet : Animal+
```

You can see that `@pet` is `Animal+`. The `+` means it's a virtual type, meaning "any class that inherits from `Animal`, including `Animal`".

The compiler will always resolve a type union to a virtual type if they are under the same hierarchy:

```crystal
if some_condition
  pet = Dog.new
else
  pet = Cat.new
end

# pet : Animal+
```

The compiler will always do this for classes and structs under the same hierarchy: it will find the first superclass from which all types inherit from (excluding `Reference`, `Value`, `Int` and `Float`). If it can't find one, the type union remains.

The real reason the compiler does this is to be able to compile programs faster by not creating all kinds of different similar unions, also making the generated code smaller in size. But, on the other hand, it makes sense: classes under the same hierarchy should behave in a similar way.

Lets make John's pet talk:

```crystal
john.pet.talk # Error: undefined method 'talk' for Animal
```

We get an error because the compiler now treats `@pet` as an `Animal+`, which includes `Animal`. And since it can't find a `talk` method on it, it errors.

What the compiler doesn't know is that for us, `Animal` will never be instantiated as it doesn't make sense to instantiate one. We have a way to tell the compiler so by marking the class as `abstract`:

```crystal
abstract class Animal
end
```

Now the code compiles:

```crystal
john.pet.talk # => "Woof!"
```

Marking a class as abstract will also prevent us from creating an instance of it:

```crystal
Animal.new # Error: can't instantiate abstract class Animal
```

To make it more explicit that an `Animal` must define a `talk` method, we can add it to `Animal` as an abstract method:

```crystal
abstract class Animal
  # Makes this animal talk
  abstract def talk
end
```

By marking a method as `abstract` the compiler will check that all subclasses implement this method (matching the parameter types and names), even if a program doesn't use them.

Abstract methods can also be defined in modules, and the compiler will check that including types implement them.
# Visibility

Methods are public by default: the compiler will always let you invoke them. There is no `public` keyword for this reason.

Methods *can* be marked as `private` or `protected`.

## Private methods

A `private` method can only be invoked without a receiver, that is, without something before the dot. The only exception is `self` as a receiver:

```crystal
class Person
  private def say(message)
    puts message
  end

  def say_hello
    say "hello"      # OK, no receiver
    self.say "hello" # OK, self is a receiver, but it's allowed.

    other = Person.new
    other.say "hello" # Error, other is a receiver
  end
end
```

Note that `private` methods are visible by subclasses:

```crystal
class Employee < Person
  def say_bye
    say "bye" # OK
  end
end
```

## Private types

Private types can only be referenced inside the namespace where they are defined, and never be fully qualified.

```crystal
class Foo
  private class Bar
  end

  Bar      # OK
  Foo::Bar # Error
end

Foo::Bar # Error
```

`private` can be used with `class`, `module`, `lib`, `enum`, `alias` and constants:

```crystal
class Foo
  private ONE = 1

  ONE # => 1
end

Foo::ONE # Error
```

## Protected methods

A `protected` method can only be invoked on:

1. instances of the same type as the current type
2. instances in the same namespace (class, struct, module, etc.) as the current type

```crystal
# Example of 1

class Person
  protected def say(message)
    puts message
  end

  def say_hello
    say "hello"      # OK, implicit self is a Person
    self.say "hello" # OK, self is a Person

    other = Person.new "Other"
    other.say "hello" # OK, other is a Person
  end
end

class Animal
  def make_a_person_talk
    person = Person.new
    person.say "hello" # Error: person is a Person but current type is an Animal
  end
end

one_more = Person.new "One more"
one_more.say "hello" # Error: one_more is a Person but current type is the Program

# Example of 2

module Namespace
  class Foo
    protected def foo
      puts "Hello"
    end
  end

  class Bar
    def bar
      # Works, because Foo and Bar are under Namespace
      Foo.new.foo
    end
  end
end

Namespace::Bar.new.bar
```

A `protected` method can only be invoked from the scope of its class or its descendants. That includes the class scope and bodies of class methods and instance methods of the same type the protected method is defined on, as well as all types including or inherinting that type and all types in that namespace.

```crystal
class Parent
  protected def self.protected_method
  end

  Parent.protected_method # OK

  def instance_method
    Parent.protected_method # OK
  end

  def self.class_method
    Parent.protected_method # OK
  end
end

class Child < Parent
  Parent.protected_method # OK

  def instance_method
    Parent.protected_method # OK
  end

  def self.class_method
    Parent.protected_method # OK
  end
end

class Parent::Sub
  Parent.protected_method # OK

  def instance_method
    Parent.protected_method # OK
  end

  def self.class_method
    Parent.protected_method # OK
  end
end
```

## Private top-level methods

A `private` top-level method is only visible in the current file.

```crystal title="one.cr"
private def greet
  puts "Hello"
end

greet # => "Hello"
```

```crystal title="two.cr"
require "./one"

greet # undefined local variable or method 'greet'
```

This allows you to define helper methods in a file that will only be known in that file.

## Private top-level types

A `private` top-level type is only visible in the current file.

```crystal title="one.cr"
private class Greeter
  def self.greet
    "Hello"
  end
end

Greeter.greet # => "Hello"
```

```crystal title="two.cr"
require "./one"

Greeter.greet # undefined constant 'Greeter'
```
# while

A `while` executes its body as long as its condition is *truthy*.

```crystal
while some_condition
  do_this
end
```

The condition is first tested and, if *truthy*, the body is executed. That is, the body might never be executed.

Similar to an `if`, if a `while`'s condition is a variable, the variable is guaranteed to not be `nil` inside the body. If the condition is an `var.is_a?(Type)` test, `var` is guaranteed to be of type `Type` inside the body. And if the condition is a `var.responds_to?(:method)`, `var` is guaranteed to be of a type that responds to that method.

The type of a variable after a `while` depends on the type it had before the `while` and the type it had before leaving the `while`'s body:

```crystal
a = 1
while some_condition
  # a : Int32 | String
  a = "hello"
  # a : String
  a.size
end
# a : Int32 | String
```

## Checking the condition at the end of a loop

If you need to execute the body at least once and then check for a breaking condition, you can do this:

```crystal
while true
  do_something
  break if some_condition
end
```

Or use `loop`, found in the standard library:

```crystal
loop do
  do_something
  break if some_condition
end
```

## As an expression

The value of a `while` is the value of the `break` expression that exits the `while`'s body:

```crystal
a = 0
x = while a < 5
  a += 1
  break "four" if a == 4
  break "three" if a == 3
end
x # => "three"
```

If the `while` loop ends normally (because its condition became false), the value is `nil`:

```crystal
x = while 1 > 2
  break 3
end
x # => nil
```

`break` expressions with no arguments also return `nil`:

```crystal
x = while 2 > 1
  break
end
x # => nil
```

`break` expressions with multiple arguments are packed into [`Tuple`](https://crystal-lang.org/api/Tuple.html) instances:

```crystal
x = while 2 > 1
  break 3, 4
end
x         # => {3, 4}
typeof(x) # => Tuple(Int32, Int32)
```

The type of a `while` is the union of the types of all `break` expressions in the body, plus `Nil` because the condition can fail:

```crystal
x = while 1 > 2
  if rand < 0.5
    break 3
  else
    break '4'
  end
end
typeof(x) # => (Char | Int32 | Nil)
```

However, if the condition is exactly the `true` literal, then its effect is excluded from the return value and return type:

```crystal
x = while true
  break 1
end
x         # => 1
typeof(x) # => Int32
```

In particular, a `while true` expression with no `break`s has the `NoReturn` type, since the loop can never be exited in the same scope:

```crystal
x = while true
  puts "yes"
end
x         # unreachable
typeof(x) # => NoReturn
```
# Tutorials

This is the starting point to learn the basics of Crystal.
# Hello World

The first thing you need to learn in any programming language is the famous [`Hello World!` program](https://en.wikipedia.org/wiki/%22Hello,_World!%22_program).

In Crystal this is pretty simple, maybe a little bit boring:

```crystal-play
puts "Hello World!"
```

> TIP:
> You can build and run code examples interactively in this tutorial by clicking the `Run` button (thanks to [carc.in](https://carc.in)).
> The output is shown directly inline.
>
> If you want to follow along locally, follow the [installation](https://crystal-lang.org/install/) and [getting started](../../getting_started/README.md) instructions.

!!! info inline end
    The name `puts` is short for “put string”.

The entire program consists of a call to the method [`puts`](https://crystal-lang.org/api/toplevel.html#puts%28%2Aobjects%29%3ANil-class-method) with the string `Hello World!` as an argument.

This method prints the string (plus a trailing newline character) to the [standard output](https://en.wikipedia.org/wiki/Standard_output).

All code in the top-level scope is part of the main program. There is no explicit `main` function as [entry point](https://en.wikipedia.org/wiki/Entry_point) to the program.
# Variables

To store a value and re-use it later, it can be assigned to a variable.

For example, if you want to say `Hello Penny!` three times, you don't need to repeat the same string multiple times.
Instead, you can assign it to a variable and re-use it:

```crystal-play
message = "Hello Penny!"

puts message
puts message
puts message
```

This program prints the string `Hello Penny!` three times to the standard output, each followed by a line break.

The name of a variable always starts with a lowercase [Unicode](https://en.wikipedia.org/wiki/Unicode) letter (or an underscore, but that's reserved for special use cases) and can otherwise consist of alphanumeric characters or underscores. As a typical convention, upper-case letters are avoided and names are written in [`snake_case`](https://en.wikipedia.org/wiki/Snake_case).

NOTE:
The kind of variables this lesson discusses is called *local variables*.
Other kinds will be introduced later. For now, we focus on local variables only.

## Type

The type of a variable is automatically inferred by the compiler. In the above example, it's [`String`](https://crystal-lang.org/api/String.html).

You can verify this with [`typeof`](https://crystal-lang.org/api/toplevel.html#typeof(*expression):Class-class-method):

```crystal-play
message = "Hello Penny!"

p! typeof(message)
```

NOTE: [`p!`](https://crystal-lang.org/api/toplevel.html#p!(*exps)-macro) is similar to `puts` as it prints the value to the standard output, but it also prints the expression in code. This makes it a useful tool for inspecting the state of a Crystal program and debugging.

## Reassigning a Value

A variable can be reassigned with a different value:

```crystal-play
message = "Hello Penny!"

p! message

message = "Hello Sheldon!"

p! message
```

This also works with values of different types. The type of the variable changes when a value of a different type is assigned. The compiler is smart enough to know which type it has at which point in the program.

```crystal-play
message = "Hello Penny!"

p! message, typeof(message)

message = 73

p! message, typeof(message)
```
# Math

## Numeric types

The two most common number types are `Int32` and `Float64`. The number in the name denotes the size in bits: `Int32` is a 32-bit [integer type](https://en.wikipedia.org/wiki/Integer_(computer_science)), `Float64` is a 64-bit [floating point number](https://en.wikipedia.org/wiki/Floating-point_arithmetic).

* An integer literal is written as a series of one or more base-10 digits (`0-9`) without leading zeros. The default type is `Int32`.
* A floating-point literal is written as a series of two or more base-10 digits (`0-9`) with a point (`.`) somewhere in the middle,
  indicating the decimal point. The default type is `Float64`.

All numeric types allow underscores at any place in the middle. This is useful to write large numbers in a more readable way: `100000` can be written as `100_000`.

```crystal-play
p! 1, typeof(1)
p! 1.0, typeof(1.0)
p! 100_000, typeof(100_000)
p! 100_000.0, typeof(100_000.0)
```

Float values print with a decimal point. Integer values don't.

> INFO:
> There are quite a few more numeric types, but most of them are intended only for special use cases such as binary protocols,
> specific numeric algorithms, and performance optimization. You probably don't need them for everyday programs.
>
> See [Integer literal reference](../../syntax_and_semantics/literals/integers.md) and [Float literal reference](../../syntax_and_semantics/literals/floats.md)
> for a full reference on all primitive number types and alternative representations.

## Arithmetic

### Equality and Comparison

Numbers of the same numerical value are considered equal regarding the equality operator `==`, independent of their type.

```crystal-play
p! 1 == 1,
  1 == 2,
  1.0 == 1,
  -2000.0 == -2000
```

Besides the equality operator, there are also comparison operators. They determine the relationship between two values.
As with equality, comparability is also independent of type.

```crystal-play
p! 2 > 1,
  1 >= 1,
  1 < 2,
  1 <= 2
```

The universal comparison operator is `<=>`, also called *Spaceship operator* for its appearance. It compares its operands and returns a value that is either zero (both operands are equal),
a positive value (the first operand is bigger), or a negative value (the second operand is bigger). It combines the behaviour of all other comparison operators.

```crystal-play
p! 1 <=> 1,
  2 <=> 1,
  1 <=> 2
```

### Operators

Basic arithmetic operations can be performed with operators. Most operators are *binary* (i.e. two operands), and
written in infix notation (i.e. between the operands). Some operators are *unary* (i.e. one operand), and written in prefix
notation (i.e. before the operand).
The value of the expression is the result of the operation.

```crystal-play
p! 1 + 1, # addition
  1 - 1,  # subtraction
  2 * 3,  # multiplication
  2 ** 4, # exponentiation
  2 / 3,  # division
  2 // 3, # floor division
  3 % 2,  # modulus
  -1      # negation (unary)
```

As you can see, the result of most of these operations between integer operands is also an integer value.
The division operator (`/`) is an exception. It always returns a float value. The floor division operator (`//`) however returns an integer value, but it's obviously reduced to integer precision.
An operation between integer and float operands always returns a float value. Otherwise, the return type is usually the type of the first operand.

INFO: A full list of operators is available in [the Operator reference](../../syntax_and_semantics/operators.md#arithmetic-operators).

#### Precedence

When several operators are combined, the question arises in which order are they executed.
In math, there are several rules, like multiplication and division taking precedence over addition and subtraction.
Crystal operators implement these precedence rules.

A tool to structure operations are parentheses. An operator expression in parentheses always takes precedence over external operators.

```crystal-play
p! 4 + 5 * 2,
  (4 + 5) * 2
```

INFO: All the precedence rules are detailed in the [the Operator reference](../../syntax_and_semantics/operators.md#operator-precedence).

### Number Methods

Some less common math operations are not operators, but named methods.

```crystal-play
p! -5.abs,   # absolute value
  4.3.round, # round to nearest integer
  5.even?,   # odd/even check
  10.gcd(16) # greatest common divisor
```

INFO: A full list of numerical methods is available in [the Number API docs](https://crystal-lang.org/api/Number.html) (also check subtypes).

### Math Methods

Some arithmetic methods are not defined on the number types directly but in the `Math` namespace.

```crystal-play
p! Math.cos(1),     # cosine
  Math.sin(1),      # sine
  Math.tan(1),      # tangent
  Math.log(42),     # natural logarithm
  Math.log10(312),  # logarithm to base 10
  Math.log(312, 5), # logarithm to base 5
  Math.sqrt(9)      # square root
```

INFO: A full list of math methods is available in [the Math API docs](https://crystal-lang.org/api/Math.html).

## Constants

Some mathematical constants are available as constants of the `Math` module.

```crystal-play
p! Math::E,  # Euler's number
  Math::TAU, # Full circle constant (2 * PI)
  Math::PI   # Archimedes' constant (TAU / 2)
```
# Strings

In the previous lessons, we have already made an acquaintance with a major building block
of most programs: strings. Let's recapitulate the basic properties:

A [string](https://en.wikipedia.org/wiki/String_(computer_science)) is a sequence of [Unicode](https://en.wikipedia.org/wiki/Unicode) characters encoded in [UTF-8](https://en.wikipedia.org/wiki/UTF-8).
A string is [immutable](https://en.wikipedia.org/wiki/Immutable_object):
If you apply a modification to a string, you actually get a new string with the
modified content. The original string stays the same.

Strings are written as literals typically enclosed in double-quote characters (`"`).

## Interpolation

String interpolation is a convenient method for combining strings: `#{...}` inside a string literal inserts the value of the expression between the curly braces at this position of the string.

```crystal-play
name = "Crystal"
puts "Hello #{name}"
```

The expression inside an interpolation should be kept short to either a variable or a simple method call. More complex expressions reduce code readability.

The value of the expression doesn't need to be a string. Any type will do and it gets converted to a string representation by calling the `#to_s` method. This method is defined for any object. Let's try with a number:

```crystal-play
name = 6
puts "Hello #{name}!"
```

NOTE:
An alternative to interpolation is concatenation. Instead of `"Hello #{name}!"` you could write `"Hello " + name + "!"`. But that's bulkier and has some gotchas with non-string types. Interpolation is generally preferred over concatenation.

## Escaping

Some characters can't be written directly in string literals. For example a double quote: If used inside a string, the compiler would interpret it as the end delimiter.

The solution to this problem is escaping: If a double quote is preceded by a backslash (`\`), it's interpreted as an escape sequence and both characters together encode a double quote character.

```crystal-play
puts "I say: \"Hello World!\""
```

There are other escape sequences: For example non-printable characters such as a line break (`\n`) or a tabulator (`\t`). If you want to write a literal backslash, the escape sequence is a double backslash (`\\`). The null character (codepoint `0`) is a regular character in Crystal strings. In some programming languages, this character denotes the end of a string. But in Crystal, it's only determined by its `#size` property.

```crystal-play
puts "I say: \"Hello \\\n\tWorld!\""
```

TIP: You can find more info on available escape sequences in the [string literal reference](../../syntax_and_semantics/literals/string.md#escaping).

### Alternative Delimiters

Some string literals may contain a lot of double quotes – think of HTML tags with quoted argument values for example. It would be cumbersome to have to escape each one with a backslash. Alternative literal delimiters are a convenient alternative. `%(...)` is equivalent to `"..."` except that the delimiters are denoted by parentheses (`(` and `)`) instead of double quotes.

```crystal-play
puts %(I say: "Hello World!")
```

Escape sequences and interpolation still work the same way.

TIP: You can find more info on alternative delimiters in the [string literal reference](../../syntax_and_semantics/literals/string.md#percent-string-literals).

## Unicode

Unicode is an international standard for representing text in many different writing systems. Besides letters of the latin alphabet used by English and many other languages, it includes many other character sets. Not just for plain text, but the Unicode standard also includes emojis and icons.

The following example uses the Unicode character [`U+1F310` (*Globe with Meridians*)](https://codepoints.net/U+1F310) to address the world:

```crystal-play
puts "Hello 🌐"
```

Working with Unicode symbols can be a bit tricky sometimes. Some characters may not be supported by your editor font, some characters are not even printable. As an alternative, Unicode characters can be expressed as an escape sequence. A backslash followed by the letter `u` denotes a Unicode codepoint. The codepoint value is written as hexadecimal digits enclosed in curly braces. The curly braces can be omitted if the codepoint has exactly four digits.

```crystal-play
puts "Hello \u{1F310}"
```

## Transformation

Let's say you want to change something about a string. Maybe scream the message and make it all uppercase?
The method `String#upcase` converts all lower case characters to their upper case equivalent.
The opposite is `String#downcase`. There are a couple more similar methods, which let us express our message in different
styles:

```crystal-play
message = "Hello World! Greetings from Crystal."

puts "normal: #{message}"
puts "upcased: #{message.upcase}"
puts "downcased: #{message.downcase}"
puts "camelcased: #{message.camelcase}"
puts "capitalized: #{message.capitalize}"
puts "reversed: #{message.reverse}"
puts "titleized: #{message.titleize}"
puts "underscored: #{message.underscore}"
```

The methods `#camelcase` and `#underscore` don't change this particular string, but try them with the inputs `"snake_cased"` or `"CamelCased"`.

## Information

Let's take a more detailed look at a string and what we can know about it. First of all, a string
has a length, i.e. the number of characters it contains. This value is available as `String#size`.

```crystal-play
message = "Hello World! Greetings from Crystal."

p! message.size
```

To determine if a string is empty, you can check if the size is zero, or just use the shorthand `String#empty?`:

```crystal-play
empty_string = ""

p! empty_string.size == 0,
  empty_string.empty?
```

The method `String#blank?` returns `true` if the string is empty or if it only contains whitespace characters. A related method is `String#presence` which returns `nil` if the string is blank, otherwise the string itself.

```crystal-play
blank_string = ""

p! blank_string.blank?,
  blank_string.presence
```

## Equality and Comparison

You can test two strings for equality with the equality operator (`==`) and compare them with the
comparison operator (`<=>`). Both compare the strings strictly character by character.
Remember, `<=>` returns an integer indicating the relationship between both operands,
and `==` returns `true` if the comparison results in `0`, i.e. both values compare equally.

There is however also a `#compare` method that offers case insensitive comparison.

```crystal-play
message = "Hello World!"

p! message == "Hello World",
  message == "Hello Crystal",
  message == "hello world",
  message.compare("hello world", case_insensitive: false),
  message.compare("hello world", case_insensitive: true)
```

## Partial Components

Sometimes it's not important to know whether a string matches another exactly, and you just want to
know if one string contains another. For example, let's check if the message is about Crystal using the
`#includes?` method.

```crystal-play
message = "Hello World!"

p! message.includes?("Crystal"),
  message.includes?("World")
```

Sometimes the beginning or end of a string are of particular interest. That's where the methods `#starts_with?` and `#ends_with?`
come into play.

```crystal-play
message = "Hello World!"

p! message.starts_with?("Hello"),
  message.starts_with?("Bye"),
  message.ends_with?("!"),
  message.ends_with?("?")
```

## Indexing Substrings

We can get even more detailed information on the position of a substring with the `#index` method.
It returns the index of the first character in the substring's first appearance.
The result `0` means the same as `starts_with?`.

```crystal-play
p! "Crystal is awesome".index("Crystal"),
  "Crystal is awesome".index("s"),
  "Crystal is awesome".index("aw")
```

The method has an optional `offset` argument that can be used to start searching from a different
position than the beginning of the string. This is useful when the substring may appear multiple times.

```crystal-play
message = "Crystal is awesome"

p! message.index("s"),
  message.index("s", offset: 4),
  message.index("s", offset: 10)
```

The method `#rindex` works the same, but it searches from the end of the string instead.

```crystal-play
message = "Crystal is awesome"

p! message.rindex("s"),
  message.rindex("s", 13),
  message.rindex("s", 8)
```

In case the substring is not found, the result is a special value called `nil`.
It means "no value". Which makes sense when the substring has no index.

Looking at the return type of `#index` we can see that it returns either `Int32` or `Nil`.

```crystal-play
a = "Crystal is awesome".index("aw")
p! a, typeof(a)
b = "Crystal is awesome".index("meh")
p! b, typeof(b)
```

TIP: We'll cover `nil` more deeply in the next lesson.

## Extracting Substrings

A substring is a part of a string. If you want to extract parts of the string,
there are several ways to do that.

The index accessor `#[]` allows referencing a substring by character index and size. Character
indices start at `0` and reach to length (i.e. the value of `#size`) minus one.
The first argument specifies the index of the first character that is supposed to be in the substring,
and the second argument specifies the length of the substring. `message[6, 5]` extracts a substring
of five characters long, starting at index six.

```crystal-play
message = "Hello World!"

p! message[6, 5]
```

Let's assume we have established that the string starts with `Hello` and ends with `!` and want to extract what's in
between.
If the message was `Hello Crystal`, we wouldn't get the entire word `Crystal` because it's longer than five characters.

A solution is to calculate the length of the substring from the length of the entire string minus the lengths of beginning and end.

```crystal-play
message = "Hello World!"

p! message[6, message.size - 6 - 1]
```

There's an easier way to do that: The index accessor can be used with a [`Range`](https://crystal-lang.org/api/Range.html)
of character indices. A range literal consists of a start value and an end value, connected by two dots (`..`).
The first value indicates the start index of the substring, as before, but the second is the end index (as opposed to the length).
Now we don't need to repeat the start index in the calculation because the end index is just the size minus two
(one for the end index, and one for excluding the last character).

It can be even easier: Negative index values automatically relate to the end of the string, so we don't need to calculate
the end index from the string size explicitly.

```crystal-play
message = "Hello World!"

p! message[6..(message.size - 2)],
  message[6..-2]
```

## Substitution

In a very similar manner, we can modify a string. Let's make sure we properly greet Crystal and nothing else.
Instead of accessing a substring, we call `#sub`. The first argument is again a range to indicate the location
that gets replaced by the value of the second argument.

```crystal-play
message = "Hello World!"

p! message.sub(6..-2, "Crystal")
```

The `#sub` method is very versatile and can be used in different ways. We could also pass a search string as the first argument
and it replaces that substring with the value of the second argument.

```crystal-play
message = "Hello World!"

p! message.sub("World", "Crystal")
```

`#sub` only replaces the first instance of a search string. Its big brother `#gsub` applies to all instances.

```crystal-play
message = "Hello World! How are you, World?"

p! message.sub("World", "Crystal"),
  message.gsub("World", "Crystal")
```

TIP: You can find more detailed info in the [string literal reference](../../syntax_and_semantics/literals/string.md) and [String API docs](https://crystal-lang.org/api/String.html).
# Control Flow

## Primitive Types

### Nil

The simplest type is `Nil`. It has only a single value: `nil` and represents
the absence of an actual value.

Remember [`String#index` from last lesson](./40_strings.md#indexing-substrings)?
It returns `nil` if the substring does not exist in the search string. It has no index,
so the index position is absent.

```crystal-play
p! "Crystal is awesome".index("aw"),
  "Crystal is awesome".index("xxxx")
```

### Bool

The `Bool` type has just two possible values: `true` and `false` which represent the
truth values of logic and Boolean algebra.

```crystal-play
p! true, false
```

[Boolean values](https://en.wikipedia.org/wiki/Boolean_data_type) are particularly useful for
managing control flow in a program.

## Boolean Algebra

The following example shows operators for implementing [boolean algebra](https://en.wikipedia.org/wiki/Boolean_algebra) with
boolean values:

```crystal-play
a = true
b = false

p! a && b, # conjunction (AND)
  a || b,  # disjunction (OR)
  !a,      # negation (NOT)
  a != b,  # inequivalence (XOR)
  a == b   # equivalence
```

You can try flicking the values of `a` and `b` to see the operator behaviour for different input values.

### Truthiness

Boolean algebra isn't limited to just boolean types, though. All values have an implicit truthiness: `nil`, `false`,
and null pointers (just for completeness, we cover that later) are *falsey*. Any other value (including `0`) is *truthy*.

Let's replace `true` and `false` in the above example with other values, for example `"foo"` and `nil`.

```crystal-play
a = "foo"
b = nil

p! a && b, # conjunction (AND)
  a || b,  # disjunction (OR)
  !a,      # negation (NOT)
  a != b,  # inequivalence (XOR)
  a == b   # equivalence
```

The `AND` and `OR` operators return the first operand value matching the operator's truthiness.

```crystal-play
p! "foo" && nil,
  "foo" && false,
  false || "foo",
  "bar" || "foo"
```

The `NOT`, `XOR`, and equivalence operators always return a `Bool` value (`true` or `false`).

<!-- markdownlint-disable-next-line no-duplicate-heading -->
## Control Flow

Controlling the flow of a program means taking different paths based on conditions.
Up until now, every program in this tutorial has been a sequential series of expressions.
Now this is going to change.

### Conditionals

A conditional clause puts a branch of code behind a gate that only opens if the condition is met.

In the most basic form, it consists of a keyword `if` followed by an expression serving as the condition.
The condition is met when the return value of the expression is *truthy*.
All subsequent expressions are part of the branch until it closes with the keyword `end`.

Per convention, we indent nested branches by two spaces.

The following example prints the message only if it meets the condition to start with `Hello`.

```crystal-play
message = "Hello World"

if message.starts_with?("Hello")
  puts "Hello to you, too!"
end
```

NOTE:
Technically, this program still runs in a predefined order. The fixed message always matches and makes the condition truthy.
But let's assume we don't define the value of the message in the source code. It could just as well come from user input,
for example a chat client.

If the message has a value that does not start with `Hello`, the conditional branch skips, and the program prints nothing.

The condition expression can be more complex. With [boolean algebra](#boolean-algebra) we can construct a condition that accepts either `Hello`
or `Hi`:

```crystal-play
message = "Hello World"

if message.starts_with?("Hello") || message.starts_with?("Hi")
  puts "Hey there!"
end
```

Let's turn the condition around: Only print the message if it does *not*  start with `Hello`.
That's just a minor deviation from the previous example: We can use the negation operator (`!`) to turn the condition
into the opposite expression.

```crystal-play
message = "Hello World"

if !message.starts_with?("Hello")
  puts "I didn't understand that."
end
```

An alternative is to replace `if` with the keyword `unless` which expects just the opposite truthiness. `unless x` is equivalent to `if !x`.

```crystal-play
message = "Hello World"

unless message.starts_with?("Hello")
  puts "I didn't understand that."
end
```

Let's look at an example that uses `String#index` to find a substring and highlight its location.
Remember that it returns `nil` if it can't find the substring? In that case, we can't highlight anything.
So we need an `if` clause with a condition that checks if the index is `nil`. The `.nil?` method is perfect for that.

```crystal-play
str = "Crystal is awesome"
index = str.index("aw")

if !index.nil?
  puts str
  puts "#{" " * index}^^"
end
```

The compiler enforces that you handle the `nil` case.
Try to remove the conditional or change the condition to `true`: a type error shows up and explains that you can't
use a `Nil` value in that expression.
With the proper condition, the compiler knows that `index` can't be `nil` inside the branch and it can be used as a numeric input.

TIP:
A shorter form for `if !index.nil?` is `if index`, which is mostly equivalent.
It only makes a difference if you wanted to tell apart whether a falsey value is `nil` or `false`
because the former condition matches for `false`, while the latter does not.

### Else

Let's refine our program and react in both cases, whether the message meets the condition or not.

We can do this as two separate conditionals with negated conditions:

```crystal-play
message = "Hello World"

if message.starts_with?("Hello")
  puts "Hello to you, too!"
end

if !message.starts_with?("Hello")
  puts "I didn't understand that."
end
```

This works but there are two drawbacks: The condition expression `message.starts_with?("Hello")` evaluates twice, which is inefficient.
Later, if we change the condition in one place (maybe allowing `Hi` as well), we might forget to change the other one as well.

A conditional can have multiple branches. The alternate branch is indicated by the keyword `else`. It executes if the condition is not met.

```crystal-play
message = "Hello World"

if message.starts_with?("Hello")
  puts "Hello to you, too!"
else
  puts "I didn't understand that."
end
```

### More branches

Our program only reacts to `Hello`, but we want more interaction. Let's add a branch to respond to `Bye` as well.
We can have branches for different conditions in the same conditional. It's like an `else` with another
integrated `if`. Hence the keyword is `elsif`:

```crystal-play
message = "Bye World"

if message.starts_with?("Hello")
  puts "Hello to you, too!"
elsif message.starts_with?("Bye")
  puts "See you later!"
else
  puts "I didn't understand that."
end
```

The `else` branch still only executes if neither of the previous conditions is met. It can always be omitted, though.

Note that the different branches are mutually exclusive and conditions evaluate from top to bottom.
In the above example that doesn't matter because both conditions can't be truthy at the same time (the message can't start with both `Hello` and `Bye`).
However, we can add an alternative condition that is not exclusive to demonstrate this:

```crystal-play
message = "Hello Crystal"

if message.starts_with?("Hello")
  puts "Hello to you, too!"
elsif message.includes?("Crystal")
  puts "Shine bright like a crystal."
end

if message.includes?("Crystal")
  puts "Shine bright like a crystal."
elsif message.starts_with?("Hello")
  puts "Hello to you, too!"
end
```

Both clauses have branches with the same conditions but in a different order and they behave differently.
The first matching condition selects which branch executes.

## Loops

This section introduces the basics of repeated execution of code.

The basic feature is the `while` clause. Its structured quite similar to an `if` clause:
The keyword `while` designates the beginning and is followed by an expression serving as the loop condition.
All subsequent expressions are part of the loop until the closing keyword `end`.
The loop continues to repeat itself as long as the return value of the condition is *truthy*.

Let's try a simple program for counting from 1 to 10:

```{.crystal .crystal-play}
counter = 0

while counter < 10
  counter += 1

  puts "Counter: #{counter}"
end
```

The code between `while` and `end` is executed 10 times. It prints the current counter value and increases it by one.
After the 10th iteration, the value of `counter` is `10`, thus `counter < 10` fails and the loop breaks.

An alternative is to replace `while` with the keyword `until` which expects just the opposite truthiness. `until x` is equivalent to `while !x`.

```{.crystal .crystal-play}
counter = 0

until counter >= 10
  counter += 1

  puts "Counter: #{counter}"
end
```

TIP: You can find more details on these expressions in the language specification: [`while`](../../syntax_and_semantics/while.md) and [`until`](../../syntax_and_semantics/until.md).

### Infinite loops

When working with loops, it's important to care about the loop condition being *falsey* at some point.
Otherwise, it would continue forever or until you stop the program externally (for example <kbd>Ctrl+C</kbd>, `kill`, pull the plug or when armageddon arrives).

In this example, not incrementing the counter it would be the same as writing:

```
while true
  puts "Counter: #{counter}"
end
```

Or if the condition was `counter > 0`, it would match for all values: they only increase from `1`.
This would not technically be infinite, as it will fail with a math error when the counter reaches the maximum value of a 32-bit integer. But conceptually that's similar to an infinite loop.
Such logic errors can be easy to miss and so it's very important to pay attention when writing the loop condition and also taking care of meeting said breaking case.
A good practice for index variables (such as `counter` in our example) is to increment them at the beginning of the loop.
That makes it harder to forget to update them.

TIP:
Fortunately, there are many features in the language that relieve the burden of writing loops manually
and also take care of ensuring valid breaking conditions. A few of them will be introduced in following lessons.

In some cases, the intention is to really have an endless loop.
An example would be a server that always repeats waiting for a connection, or
a command processor waiting for user input.
Then it should be obvious of course, and not hidden in a complex, never-failing loop condition. The most plain way to express that is `while true`.
The condition `true` is always truthy, so the loop repeats endlessly.

```cr
while true
  puts "Hi, what's your name? (hit Enter when done)"

  # `gets` returns input from the console
  name = gets

  puts "Nice to meet you, #{name}."
  puts "Now, let's repeat."
end
```

> NOTE:
> This example is not an interactive playground by choice because the playground can't
> handle non self-terminating programs, and processing user input.
> It would just time out and print an error.
> You can compile and run this code with a local compiler, though.
>
> To stop the program, hit <kbd>Ctrl+C</kbd>. This sends a signal to the process asking it
> to exit.

### Skipping and Breaking

It can be useful to skip some iterations in between, or stop the iteration entirely on some condition.

The keyword `next` inside a loop body skips to the next iteration, ignoring any expressions left in the current iteration.
If the loop condition isn't met, the loop finishes and the body won't execute another time.

```{.crystal .crystal-play}
counter = 0

while counter < 10
  counter += 1

  if counter % 3 == 0
    next
  end

  puts "Counter: #{counter}"
end
```

This example could've easily be written without `next` by placing the `puts` expression in a conditional instead.
The worth of `next` becomes apparent when there are many more expressions in the method body to be skipped.

Loop conditions can be difficult to calculate, for example because they require multiple steps or depend on input that needs to be determined.
In such situations, it's not very practical to write all the logic in the loop condition.
The keyword `break` can be used anywhere in a loop body and serves as an additional option to break from a loop regardless of its loop condition.
Control flow immediately continues after the end of the loop.

```{.crystal .crystal-play}
counter = 0

while true
  counter += 1

  puts "Counter: #{counter}"

  if counter >= 10
    break
  end
end

puts "done"
```
# Methods

To avoid duplication of the same message, instead of using a variable we can
define a method and call it multiple times.

A method definition is indicated by the keyword `def` followed by the method name.
Every expression until the keyword `end` is part of the method body.

```crystal-play
def say_hello
  puts "Hello Penny!"
end

say_hello
say_hello
say_hello() # syntactically equivalent method call with parentheses
```

TIP:
Method calls are unambiguously indicated by parentheses after the name, but they can be omitted. It would only be
necessary for disambiguation, for example, if `say_hello` was also a local variable.

## Arguments

What if we want to greet different people, but all in the same manner?
Instead of writing individual messages, we can define a method that allows customization through a parameter.
A parameter is like a local variable inside the method body. Parameters are declared after the method name in parentheses.
When calling a method, you can pass in arguments that are mapped as values for the method's parameters.

```crystal-play
def say_hello(recipient)
  puts "Hello #{recipient}!"
end

say_hello "World"
say_hello "Crystal"
```

> TIP:
> Arguments at method calls are typically placed in parentheses, but it can often be omitted. `say_hello "World"`
> and `say_hello("World")` are syntactically equivalent.
>
> It's generally recommended to use parentheses because it avoids ambiguity. But they're often omitted if the
> expression reads like natural language.

### Default arguments

Arguments can be assigned a default value. It is used in case the argument is missing in the method call. Usually,
arguments are mandatory but when there's a default value, it can be omitted.

```crystal-play
def say_hello(recipient = "World")
  puts "Hello #{recipient}!"
end

say_hello
say_hello "Crystal"
```

## Type Restrictions

Our example method expects `recipient` to be a `String`. But any other type would work as well. Try `say_hello 6`
for example.

This isn't necessarily a problem for this method. Using any other type would be valid code.
But semantically we want to greet people with a name as a `String`.

Type restrictions limit the allowed type of an argument. They come after the argument name, separated by a colon:

```crystal-play
def say_hello(recipient : String)
  puts "Hello #{recipient}!"
end

say_hello "World"
say_hello "Crystal"

# Now this expression doesn't compile:
# say_hello 6
```

Now names cannot be numbers or other data types anymore. This doesn't mean you can't
greet people with a number as a name. The number just needs to be expressed as a string.
Try `say_hello "6"` for example.

## Overloading

Restricting the type of an argument can be used for positional overloading.
When a method has an unrestricted argument like `say_hello(recipient)`, *all* calls to a method `say_hello` go to that method.
But with overloading several methods of the same name can exist with different argument type restrictions. Each call is routed
to the most fitting overload.

```crystal-play
# This methods greets *recipient*.
def say_hello(recipient : String)
  puts "Hello #{recipient}!"
end

# This method greets *times* times.
def say_hello(times : Int32)
  puts "Hello " * times
end

say_hello "World"
say_hello 3
```

Overloading isn't defined just by type restrictions. The number of arguments as well as named arguments are also
relevant characteristics.

## Returning a value

Methods return a value which becomes the value of the method call. By default, it's the value of the last expression in the method:

```crystal-play
def adds_2(n : Int32)
  n + 2
end

puts adds_2 40
```

A method can return at any place in its body using the `return` statement. The argument passed to `return` becomes the method's return value. If there is no argument, it's `nil`.

The following example illustrates the use of an *explicit* and an *implicit* `return`:

```crystal-play
# This method returns:
# - the same number if it's even,
# - the number multiplied by 2 if it's odd.
def build_even_number(n : Int32)
  return n if n.even?

  n * 2
end

puts build_even_number 7
puts build_even_number 28
```

### Return type

Let's begin defining a method that we expect it will return an `Int32` value, but mistakenly returns a `String`:

```crystal
def life_universe_and_everything
  "Fortytwo"
end

puts life_universe_and_everything + 1 # Error: no overload matches 'String#+' with type Int32
```

Because we never told the compiler we were expecting the method to return an `Int32`, the best the compiler can do is to tell us that there is no `String#+` method that takes an `Int32` value as an argument (i.e. the compiler is pointing at the moment when we use the value but not at the root of the bug: the type of the method's return value).

The error message can be more accurate if using type information, so let's try again the example but now specifying the type:

```crystal
def life_universe_and_everything : Int32
  "Fortytwo"
end

puts life_universe_and_everything + 1 # Error: method top-level life_universe_and_everything must return Int32 but it is returning String
```

Now the compiler can show us exactly where the problem is originated. As we can see, providing type information is really useful for finding errors at compile time.
# Language Introduction

This course is targeted at novice Crystal programmers and conveys a basic understanding
of the language's core concepts.
Prior programming experience is recommended, but not required. This course can help you learn
your first programming language.

Contents:

* [Hello World](10_hello_world.md) – A simple program that prints a famous first message
* [Variables](20_variables.md) – Introduction to variables and assignments
* [Math](30_math.md) – Basic numbers and algebra
* [Strings](40_strings.md) – Examples on how to modify strings
* [Control Flow](50_control_flow.md) – How to structure a program with conditionals and loops
* [Methods](60_methods.md) – Introduction to methods, arguments and type restrictions
