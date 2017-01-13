require 'searchparser/basics'

module SearchParser

  # A simple little parser that defines AND/OR/NOT
  # as the and_op, or_op, and not_op, respectively,
  # surrounded by whitespace

  class UppercaseEnglishOps < Parslet::Parser
    include Basics

    rule(:and_op) { space >> str('AND') >> space }
    rule(:or_op) { space >> str('OR') >> space }
    rule(:not_op) { space >> str('NOT') >> space }

  end


  # A partial parser that does correct operator precedence for AND/OR/NOT
  # Set up as a module, so you can include it in another parser and
  # just define a rule for :base and everything will work
  #
  # :base is the "thing" that is subjected to parenthesizing and
  # boolean operations
  module BooleanSkeleton
    include Parslet
    include Basics


    DEFAULT_OP_PARSER = UppercaseEnglishOps.new

    # By default, we use capitalized strings for AND OR NOT,
    # but you can change this by passing in a parser that
    # defines rules for :and_op, :or_op, and :not_op
    # (so, for example, you could use '&&' and '||' if you want)
    def setup_operators(op_parser: DEFAULT_OP_PARSER)
      define_singleton_method(:and_op) { op_parser.and_op }
      define_singleton_method(:or_op) { op_parser.or_op }
      define_singleton_method(:not_op) { op_parser.not_op }
    end

    # But until you call setup_operators, use the defaults
    rule(:and_op) { DEFAULT_OP_PARSER.and_op }
    rule(:or_op)  { DEFAULT_OP_PARSER.or_op  }
    rule(:not_op) { DEFAULT_OP_PARSER.not_op }

    rule(:any_op)   { not_op | or_op | and_op }

    rule(:parens)   { lp >> or_expr >> rp | base }
    rule(:not_expr) { not_op >> parens.as(:not) | parens }
    rule(:and_expr) { (not_expr.as(:left) >> and_op >> and_expr.as(:right)).as(:and) | not_expr }
    rule(:or_expr)  { (and_expr.as(:left) >> or_op >> or_expr.as(:right)).as(:or) | and_expr }

    rule(:expr) { (or_expr >> not_expr.repeat(0)).as(:search) }


  end


end