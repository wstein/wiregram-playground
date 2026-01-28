# Error and token types used across the library.
#
# Summary
#
# Contains common enums and small value types used by the public API
# (error codes, token descriptions and stage1 buffer/result structs).
module Simdjson
  # ErrorCode
  #
  # A set of error codes returned by the parser and validation routines.
  #
  # These codes describe success and a range of failure modes (UTF-8
  # validation, unclosed strings, number/literal validation failures,
  # IO errors, etc.). Use `ErrorCode#success?` to test for success.
  enum ErrorCode : Int32
    Success = 0
    Capacity
    Memalloc
    TapeError
    DepthError
    StringError
    TAtomError
    FAtomError
    NAtomError
    NumberError
    BigIntError
    Utf8Error
    Uninitialized
    Empty
    UnescapedChars
    UnclosedString
    UnsupportedArchitecture
    IncorrectType
    NumberOutOfRange
    IndexOutOfBounds
    NoSuchField
    IoError
    InvalidJsonPointer
    InvalidUriFragment
    UnexpectedError
    ParserInUse
    OutOfOrderIteration
    InsufficientPadding
    IncompleteArrayOrObject
    ScalarDocumentAsValue
    OutOfBounds
    TrailingContent
    OutOfCapacity
    NumErrorCodes

    def success? : Bool
      self == ErrorCode::Success
    end
  end

  # TokenType
  #
  # Token kinds produced by `Parser#each_token`.
  enum TokenType
    StartObject
    EndObject
    StartArray
    EndArray
    Colon
    Comma
    Newline
    String
    Number
    True
    False
    Null
  end

  # Token
  #
  # Describes a single lexical token in the input. The first paragraph
  # above is the short summary used by generated docs.
  #
  # `type` is the token kind. `start` and `length` describe a zero-copy
  # slice into the original `Bytes` buffer; call `Token#slice(bytes)` to
  # obtain that slice.
  struct Token
    getter type : TokenType
    getter start : Int32
    getter length : Int32

    def initialize(@type : TokenType, @start : Int32, @length : Int32)
    end

    # Slice the original `Bytes` for this token.
    def slice(bytes : Bytes) : Slice(UInt8)
      bytes[@start, @length]
    end
  end

  # Stage1Buffer
  #
  # Wrapper for a pointer/length pair referencing structural indices
  # produced by `Stage1.index`. The optional backing `Array(UInt32)` is
  # kept to maintain ownership when needed.
  struct Stage1Buffer
    getter ptr : Pointer(UInt32)
    getter count : Int32
    @backing : Array(UInt32)?

    def initialize(@ptr : Pointer(UInt32), @count : Int32, @backing : Array(UInt32)? = nil)
    end
  end

  # Stage1Result
  #
  # Result returned from `Stage1.index` containing the `Stage1Buffer`
  # and an `ErrorCode` indicating success or the specific failure.
  struct Stage1Result
    getter buffer : Stage1Buffer
    getter error : ErrorCode

    def initialize(@buffer : Stage1Buffer, @error : ErrorCode)
    end
  end
end
