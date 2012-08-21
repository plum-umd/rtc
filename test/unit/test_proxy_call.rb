require "test/unit"
require 'rtc_lib'

Rtc::MasterSwitch.turn_off

class B 
end

class A < B
  rtc_annotated

  class << self
    alias :old_new :new
  end
  
  def self.new
    s = self.old_new
    return Rtc::ProxyObject.new(s, s.rtc_type)
  end

  typesig("bar: () -> String", false)
  def bar()
    "hello"
  end

  typesig("baz: (B) -> String", false)
  def baz(x)
    x.proxy_type.to_s
  end
end

Rtc::MasterSwitch.turn_off

class TestProxy < Test::Unit::TestCase
  def test_calls2
    Rtc::MasterSwitch.turn_on if not Rtc::MasterSwitch.is_on?

    x = [3].rtc_annotate("Array<Fixnum or String>")
    x.push(3)

    Rtc::MasterSwitch.turn_off
    assert_equal(x.proxy_type.to_s, "Array<(Fixnum or String)>")
  end

  def test_calls
    Rtc::MasterSwitch.turn_on if not Rtc::MasterSwitch.is_on?

    x = A.new
    Rtc::MasterSwitch.turn_off
    assert_equal(x.proxy_type.to_s, "A")
    Rtc::MasterSwitch.turn_on

    r = x.bar

    Rtc::MasterSwitch.turn_off
    assert_equal(r.to_s, "hello")
    Rtc::MasterSwitch.turn_on

    r_rtc_str = "{ProxyObject @object: \"hello\", @proxy_type: String}"

    Rtc::MasterSwitch.turn_off
    assert_equal(r.rtc_to_str, r_rtc_str)
    Rtc::MasterSwitch.turn_on
    
    x = x.rtc_annotate("B")
    Rtc::MasterSwitch.turn_off
    assert_equal(x.proxy_type.to_s, "B")
    Rtc::MasterSwitch.turn_on

    Rtc::MasterSwitch.turn_off
    assert_raise NoMethodError do
      x.bar
    end
    Rtc::MasterSwitch.turn_on

    x = x.rtc_annotate("A or B")
    Rtc::MasterSwitch.turn_off
    assert_equal(x.proxy_type.to_s, "(A or B)")
    Rtc::MasterSwitch.turn_on

    Rtc::MasterSwitch.turn_off
    assert_raise NoMethodError do
      x.bar
    end
    Rtc::MasterSwitch.turn_on

    a = A.new
    x = A.new
    r = a.baz(x)

    Rtc::MasterSwitch.turn_off
    assert_equal(r.object, "B")
    assert_equal(x.proxy_type.to_s, "A")
    Rtc::MasterSwitch.turn_on
  end

end

