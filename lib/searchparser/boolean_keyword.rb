require 'parslet'
require 'searchparser/boolean_skeleton'
require 'searchparser/balanced'
require 'searchtree'

module SearchParser
  class BooleanKeywordParser < Parslet::Parser
    include BooleanSkeleton

    # Just need to define the "base" -- our keyword
    # definition

    # We'll take double-quoted strings, of course
    rule(:quoted) { dq >> SearchParser::DQ_PARSER.nonquotes.as(:qinner) >> dq | dq >> dq }
    rule(:quoteds) { (quoted.as(:quoted) >> (any_op.absent? >> space >> quoted.as(:quoted)).repeat(0)).repeat(1) }

    rule(:wordchar) { match['^\s\)\(\"'] }
    rule(:basicword) { wordchar.repeat(1) }

    # A word is anything that's a valid basicword but not an operator
    rule(:word) { any_op.absent? >> basicword }

    # We're binding words next to each other very high

    rule(:words) { (word.as(:keyword) >> (space >> word.as(:keyword)).repeat(0)).repeat(1) }
    rule(:tokens) { quoteds   | words }

    # And we'll define that our base
    rule(:base) { tokens.as(:tokens) }

    # Everything else we get for free boolean_skeleton
    # We just need to tell it what to use as the root
    # type. Will usually be :expr

    root(:expr)



  end


  # Create a way to transform a parse tree from this
  # grammar into a SearchTree object

  class TokenSet
    attr_accessor :tokens

    def initialize(initial = [])
      @tokens = Array[initial]
    end

    def to_s
      @tokens.join('|')
    end
  end


  class SearchTreeTranslator < Parslet::Transform

    rule(:qinner  => simple(:str)) { str.to_s }
    rule(:keyword => simple(:str)) { ::SearchTree::Node[TokenSet.new(str.to_s)]  }
    rule(:keyword => sequence(:arr)) { arr }
    rule(:quoted => simple(:str)) { ::SearchTree::Node[TokenSet.new(str.to_s)] }
    rule(:tokens => simple(:str)) { ::SearchTree::Node[TokenSet.new(str)]}
    rule(:tokens => sequence(:x)) { ::SearchTree::Node[TokenSet.new(x)] }

    # All the "simple"s below here should be SearchTree::Node objects
    # so we can use that class's mechanisms to build it up
    rule(:not => simple(:x)) { !x }
    rule(:and => { :left => simple(:l), :right => simple(:r) }) { l & r }
    rule(:or => { :left => simple(:l), :right => simple(:r) }) { l | r }
    rule(:search => simple(:tree)) { tree }

    # If we have something like "Bill AND Danit NOT Ziv", turn it into
    # (Bill AND Danit) AND (NOT Ziv). We assume 'AND' for this; if someone
    # want x OR y OR NOT(z) they'll need to be explicit.

    rule(:search => sequence(:s))   { s.inject(:&) }
    rule(:search => simple(:t)) { t }
  end


end
