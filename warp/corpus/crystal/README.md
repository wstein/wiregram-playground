# Crystal Corpus

This directory contains a curated collection of Crystal source files for testing the lexer and parser.

## Files

- **00_simple.cr** - Basic literals, variables, method definitions, and constants
- **01_strings.cr** - String literals, interpolation, escape sequences, percent strings
- **02_regex.cr** - Regular expressions with various patterns, flags, and matching
- **03_macros.cr** - Macro definitions, code generation, conditional macros
- **04_annotations.cr** - Type annotations, compiler annotations, custom annotations
- **05_classes.cr** - Class definitions, inheritance, mixins, instance variables
- **06_blocks_procs.cr** - Blocks, Procs, yield, lambda expressions
- **07_control_flow.cr** - If/elsif/else, case/when, loops, break/next
- **08_complex.cr** - Real-world patterns with modules, classes, and API client example

## Testing Goals

These files validate that the Crystal lexer can correctly handle:

1. **String handling**: Interpolation, escape sequences, multiple literal formats
2. **Regex patterns**: Literal syntax, flags, named captures, percent format
3. **Macro syntax**: Code generation, conditional expansion, nested expressions
4. **Annotations**: Compiler directives, custom annotations, parameter syntax
5. **Complex code**: Real-world patterns combining multiple language features

## Coverage Summary

- **Lexical elements**: 8 files
- **Language features**: Strings, regex, macros, annotations, classes, blocks, control flow
- **Total LOC**: ~400 lines of representative Crystal code
