require 'parslet'
require 'searchparser/boolean_skeleton'
require 'searchparser/balanced'

module SearchParser
  class BooleanKeywordParser < Parslet::Parser
    include BooleanSkeleton

    # Just need to define the "base" -- our keyword
    # definition

    # We'll take double-quoted strings, of course
    rule(:quoted) { dq >> nonquotes.as(:quoted) >> dq | dq >> dq }

    rule(:wordchar) { match['^\\s\)\(\"'] }
    rule(:basicword) { wordchar.repeat(1) }

    # A word is anything that's a valid basicword but not an operator
    rule(:word) { anyop.absent? >> basicword }

    # We're binding words next to each other very high

    rule(:words) { word >> (space >> word).repeat(0) }
    rule(:token) { dqs | words.as(:keywords) }

    # And we'll define that our base
    rule(:base) { token }

    # Everything else we get for free boolean_skeleton

  end
end
