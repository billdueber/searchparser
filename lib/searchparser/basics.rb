require 'parslet'

module SearchParser
  module Basics
    include Parslet

    rule(:empty_string) { str("") }
    rule(:lp) { str('(') >> space? }
    rule(:rp) { space? >> str(')') }

    rule(:space) { match['\\s'].repeat(1) }
    rule(:space?) { space.maybe }

    rule(:dot) { str('.') }
    rule(:dot?) { dot.maybe }

    rule(:plus) { str('+') }
    rule(:minus) { str('-') }
    rule(:dash) { minus }

    rule(:dq) { str('"') }
    rule(:sq) { str("'") }
    rule(:nondq) { match['^"'].repeat(1) }
    rule(:nonsq) { match["^'"].repeat(1) }

    rule(:colon) { str(':') }

    rule(:lab) { str('<') }
    rule(:rab) { str('>') }
    rule(:lsb) { str('[') }
    rule(:rsb) { str(']') }

    rule(:digit) { match('\d') }
    rule(:digits) { digit.repeat(1) }
    rule(:digits?) { digit.repeat(0) }

  end
end