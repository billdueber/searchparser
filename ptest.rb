require 'parslet'
# require "searchtree"

module SearchParser

  # Just some basic definitions that are widely useful
  module ParseBasics
    include Parslet

    rule(:lp) { str('(') >> space? }
    rule(:rp) { space? >> str(')') }

    rule(:space) { match['\\s'].repeat(1) }
    rule(:space?) { space.maybe }

    rule(:dq) { str('"') }
    rule(:sq) { str("'") }

    rule(:colon) { str(':') }

  end


  # A little mini-parser to see if parens are balanced
  class Parens < Parslet::Parser
    include ParseBasics
    rule(:nonparens) { match['^\\(\\)'].repeat(1) }

    rule(:balanced_parens) { lp >> balanced_parens.repeat(0) >> rp | nonparens}
    rule(:bp_string) { balanced_parens.repeat(0) }

    def balanced?(str)
      self.balanced_parens.parse(str)
      true
    rescue Parslet::ParseFailed => e
      false
    end

  end


  # Another little mini-parser used to check if the given string
  # has balanced double-quotes
  class DoubleQuotes < Parslet::Parser
    include ParseBasics
    rule(:nonquotes) { match['^"'].repeat(1) }
    rule(:quoted)    { dq >> nonquotes >> dq }
    rule(:_double_quotes_balanced) { (quoted | nonquotes).repeat(1) }

    def balanced?(str)
      self._double_quotes_balanced.parse(str)
      true
    rescue Parslet::ParseFailed => e
      false
    end

  end

  # A parser that does correct operator precedence for AND/OR/NOT
  # Set up as a module, so you can include it in another parser and
  # just define a rule for :base and everything will work
  # :base is something like a set of keywords, or maybe a field:value
  # pair, whatever
  module BooleanParser
    include Parslet
    include ParseBasics

    # Allow the injection of strings to use for AND/OR/NOT
    # if you don't want just the regular words

    # TODO: Change signature to take a single parser that defines
    # andop/orop/notop so it's easier to specify less-restricted
    # operators (e..g., 'AND' | '&&')
    def setup_operators(andStr: "AND", orStr: "OR", notStr: "NOT")
      define_singleton_method(:andStr) { str(andStr) }
      define_singleton_method(:orStr)  { str(orStr)  }
      define_singleton_method(:notStr) { str(notStr) }
    end


    rule(:andop) { space? >> andStr >> space? }
    rule(:orop) {  space? >> orStr  >> space? }
    rule(:notop) { space? >> notStr >> space? }

    rule(:anyop) { notop | orop | andop }

    rule(:parens) { lp >> or_expr >> rp | base }
    rule(:notexpr) { notop >> parens.as(:not) | parens }
    rule(:andexpr) { (notexpr.as(:left) >> andop >> andexpr.as(:right)).as(:and) | notexpr }
    rule(:orexpr) { (andexpr.as(:left) >> orop >> orexpr.as(:right)).as(:or) | andexpr }

    rule(:expr) { (orexpr >> notexpr.repeat(0)).as(:search) }


  end


  # A boolean parser wehre the :base is a string of keywords or
  # quoteds. Note that adjacent keywords bind more closely than
  # anything else, e.g. "x y AND z" parses as (x y) AND z

  class BooleanKeywordParser < Parslet::Parser
    include BooleanParser

    def initialize(andStr: "AND", orStr: "OR", notStr: "NOT")
      super()
      self.setup_operators(andStr: andStr, orStr: orStr, notStr: notStr)
    end

    rule(:word) { match['^")(\\s'].repeat(1) } # normal word
    rule(:words) { word >> (space >> word).repeat(0) }

    # Within double-quotes, relax the restriction against parentheses
    # and allow leading and trailing spaces

    rule(:dqword) { match['^"\\s'].repeat(1)}
    rule(:dqwords) { space? >> dqword >> (space >> dqword).repeat(0) >> space? }
    rule(:quoted) { dq >> dqwords.as(:quoted) >> dq }

    # A keyword is any word that's not an operator
    rule(:keyword) { anyop.absent? >> word }

    rule(:token) { quoted | keyword.as(:keywords) }
    rule(:tokens) { (token >> (space >> tokens).repeat(0)).repeat(1) }


    # Base ourselves off of tokens. You can override this in a
    # subclass to get a different parser with the same boolean
    # behavior but different leaf nodes

    rule(:base) { tokens.as(:tokens) }
    root(:expr)


  end


  # We can also define a "tagged" search format that allows things of the form
  #
  #   field:(terms for "this field") AND field2:(whatever goes in here)
  #
  # To make things fancy, allow the caller to override the names of the valid fields,
  # the and/or/not strings, and the start/end delimiters for each grouped field search

  class FieldedParser < Parslet::Parser
    include BooleanParser

    def initialize(fields: %w[title author], start_field_terms_string: ':(',
                   end_field_terms_string: ')',
                   andStr: "AND", orStr: "OR", notStr: "NOT")
      super()
      self.setup_operators(andStr: andStr, orStr: orStr, notStr: notStr)
      define_singleton_method(:field) do
        fields.map{|x| str(x)}.reduce(:|)
      end
      define_singleton_method(:start_field_terms_string) {
        str(start_field_terms_string)
      }
      define_singleton_method(:end_field_terms_string) {
        str(end_field_terms_string)
      }
    end

    rule(:fielded) { field.as(:field) >> start_field_terms_string >>
                     BooleanKeywordParser.new.parens >> end_field_terms_string >> space? }

    rule(:base) { space? >> fielded >> space? }
    root(:expr)

  end

  # Or one with angle brackets to denote where the field choice extends
  class AngleBracketFieldedParser < Parslet::Parser
    include BooleanParser


  end


end
#
# module ST
#   class Terms
#
#     attr_reader :terms
#
#     def initialize(*args)
#       @terms = args
#     end
#
#     def to_s
#       @terms.map(&:to_s).join(' ')
#     end
#   end
#
#   class SimpleString
#     attr_reader :term
#     def initialize(str)
#       @term = str
#     end
#
#     def inspect
#       @term.to_s
#     end
#
#     def to_s
#       @term.to_s
#     end
#   end
#
#   class QuotedString < SimpleString
#     def to_s
#       %q{"#{@term.to_s}"}
#     end
#   end
#
# end
#
# class ToST < Parslet::Transform
#
#   rule(:keywords => simple(:str)) { ST::SimpleString.new(str.to_s) }
#   rule(:quoted   => simple(:str)) { ST::QuotedString.new(str.to_s) }
#   rule(:tokens   => sequence(:x)) { SearchTree::Node[ST::Terms.new(x)] }
#   rule(:not => simple(:x)) { !x }
#   rule(:and => {:left => simple(:l), :right=>simple(:r)}) { l & r }
#   rule(:or => {:left => simple(:l), :right=>simple(:r)}) { l | r }
#   rule(:search => simple(:tree))  { tree }
#
#   # If we have something like "Bill AND Danit NOT Ziv", turn it into
#   # (Bill AND Danit) AND (NOT Ziv). We assume 'AND' for this; if someone
#   # want x OR y OR NOT(z) they'll need to be explicit.
#
#   rule(:search => sequence(:s)) { s.inject(:&) }
#
# end