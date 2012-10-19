require 'rtc'
require 'test/unit'

require 'stringio'
class TestOptions < Test::Unit::TestCase
  class BadClass
    rtc_annotated
    typesig("bad_function: () -> String")
    def bad_function
      4
    end
  end
  
  attr_accessor :bad_class
  
  def initialize(*)
    @bad_class = BadClass.new
    super
  end
  
  def test_ignore
    Rtc.on_type_error = :ignore
    assert_nothing_raised do
      bad_class.bad_function
    end
    Rtc.on_type_error = :exception
  end
  
  def test_callback
    flag = false
    Rtc.on_type_error = lambda {
      |error_message|
      flag = true
    }
    assert_nothing_raised do
      bad_class.bad_function
    end
    assert(flag)
    Rtc.on_type_error = :exception
  end
  
  def test_log
    Rtc.on_type_error = (io_str = StringIO.new())
    assert_nothing_raised do
      bad_class.bad_function
    end
    assert(io_str.string.size > 0)
    Rtc.on_type_error = :exception
  end
  
end
