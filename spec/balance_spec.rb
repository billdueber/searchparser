require_relative 'spec_helper'
require 'searchparser/balanced'
require 'parslet'


describe "Balancing Parens" do
  before do
    @p = SearchParser::Parens.new
  end

  describe "expected failures" do

    it "fails on a single paren" do
      assert_raises(Parslet::ParseFailed) { @p.parse '(' }
    end

    it "fails on unbalanced parens" do
      assert_raises(Parslet::ParseFailed) { @p.parse('((') }
    end

    it "fails on three parens" do
      assert_raises(Parslet::ParseFailed) { @p.parse('()(') }
    end

    it "fails with uneven number of parens" do
      assert_raises(Parslet::ParseFailed) { @p.parse 'bill (and) bill (or) bill ( and' }
    end

  end

  describe "basics" do
    it "accepts empty parens" do
      assert @p.parse('()')
    end

    it "accepts empty string" do
      assert @p.parse('')
    end

    it "accepts string with no parens" do
      assert @p.parse('just a string')
    end

    it "accepts string that don't start/stop with parens" do
      assert @p.parse('string (inner)')
      assert @p.parse('(inner) string')
      assert @p.parse('string (inner string) string')
    end

    it "accepts proper nesting" do
      assert @p.parse('(())()()(())()((()))')
    end
  end


end

describe "Balancing double-quotes" do
  before do
    @p = SearchParser::DoubleQuotes.new
  end

  it "isn't freakin' rocket science, just test a few successes" do
    assert @p.parse %q{""}
    assert @p.parse %q{"bill"}
    assert @p.parse ''
    assert @p.parse %q{no quotes}
    assert @p.parse %q{two "sets" of "quotes" here}
  end

  it "should fail when, you know, it should fail" do
    assert_raises(Parslet::ParseFailed) { @p.parse %q{"} }
    assert_raises(Parslet::ParseFailed) { @p.parse %q{"bill} }
    assert_raises(Parslet::ParseFailed) { @p.parse %q{bill"} }
    assert_raises(Parslet::ParseFailed) { @p.parse %q{bill" "dueber"} }
    assert_raises(Parslet::ParseFailed) { @p.parse %q{"""} }
  end

end
