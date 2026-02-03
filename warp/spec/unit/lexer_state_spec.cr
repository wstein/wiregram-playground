require "../spec_helper"

describe Warp::Lexer::LexerState do
  it "defaults to Root when empty" do
    state = Warp::Lexer::LexerState.new
    state.current.should eq(Warp::Lexer::LexerState::State::Root)
  end

  it "pushes and pops states" do
    state = Warp::Lexer::LexerState.new
    state.push(Warp::Lexer::LexerState::State::String)
    state.current.should eq(Warp::Lexer::LexerState::State::String)
    state.pop
    state.current.should eq(Warp::Lexer::LexerState::State::Root)
  end

  it "resets the stack" do
    state = Warp::Lexer::LexerState.new
    state.push(Warp::Lexer::LexerState::State::Comment)
    state.push(Warp::Lexer::LexerState::State::String)
    state.reset
    state.current.should eq(Warp::Lexer::LexerState::State::Root)
  end

  it "reports in_string?" do
    state = Warp::Lexer::LexerState.new
    state.in_string?.should be_false
    state.push(Warp::Lexer::LexerState::State::String)
    state.in_string?.should be_true
    state.pop
    state.push(Warp::Lexer::LexerState::State::StringEscape)
    state.in_string?.should be_true
  end
end
