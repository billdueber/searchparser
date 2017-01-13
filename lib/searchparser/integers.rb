require 'searchparser/basics'

module SearchParser
  module Integers
    include Basics

    # A generic integer or range of same
    rule(:integer) { digits }
    rule(:integer_range) { integer.as(:start) >> rangesep >> integer.as(:end) | integer  }


    # A year range is of the form
    # 1990-1993 or
    # 1990-93
    rule(:rangesep) { dash }

    rule(:year4) { digit.repeat(4) }
    rule(:year2) { digit.repeat(2) }
    rule(:yearrange) { year4.as(:start) >> yearrangesep >> (year4 | year2).as(:end) }
    rule(:yearrange) { yearrange | year }

  end
end

