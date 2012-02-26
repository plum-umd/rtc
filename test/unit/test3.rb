require "test/unit"
require 'rtc'

include Rtc::Types

class ParentClass
  def my_method()
    puts "I'm a method!"
  end
end

class BreakingClass < ParentClass
  rtc_no_subtype
  undef_method :my_method
end


class TestMyClass3 < Test::Unit::TestCase
 
  def test_simple
    p = ParentClass.new
    b = BreakingClass.new
    assert_equal(false, b.rtc_type <= p.rtc_type)
  end
end
