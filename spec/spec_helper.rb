$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
begin
  require 'warning'
  # ignore any warnings coming from parslet
  Warning.ignore(/\/lib\/parslet/)
rescue # didn't get warning
end

require 'searchparser'


# Minitest has a circular require somewhere in it. Suppress

oldv = $VERBOSE
$VERBOSE=nil

  require 'minitest/spec'
  require 'minitest/autorun'

$VERBOSE=oldv

require 'minitest/reporters'
MiniTest::Reporters.use!


# We need a simple transformer to turn a parse tree
# into something we can actually test.
#
#
