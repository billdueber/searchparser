require 'searchparser/basics'

module SearchParser

# A little mini-parser to see if parens are balanced
  class Parens < Parslet::Parser
    include Basics


    rule(:nonparens) { match['^\\(\\)'].repeat(1) }

    rule(:balanced_parens) { lp >> balanced_parens.repeat(0) >> rp | nonparens}
    rule(:bp_string) { balanced_parens.repeat(0) }
    root(:bp_string)

    def balanced?(str)
      self.parse(str)
      true
    rescue Parslet::ParseFailed => e
      false
    end

  end

  # Another little mini-parser used to check if the given string
  # has balanced double-quotes
  class DoubleQuotes < Parslet::Parser
    include Basics
    rule(:nonquotes) { match['^"'].repeat(1) }
    rule(:quoted)    { dq >> nonquotes >> dq }
    rule(:double_quotes_balanced_string) { (quoted | nonquotes).repeat(0) }
    root(:double_quotes_balanced_string)

    def balanced?(str)
      self.parse(str)
      true
    rescue Parslet::ParseFailed => e
      false
    end

  end


  # Determine if the given string has correctly-nested parens
  # (no esacping is assumed)

  PARENS_PARSER = Parens.new
  DQ_PARSER = DoubleQuotes.new

  # Return true iff the passed string has balanced parentheses
  def self.balanced_parens?(str)
    PARENS_PARSER.balanced? str
  end

  # Return true iff the string has an even number of double quotes
  # We could more easily do this just by counting them, but I wanted
  # to leave it easier to potentially copy it or escape the dqs
  def self.balanced_double_quotes?(str)
    DQ_PARSER.balanced? str
  end

end
