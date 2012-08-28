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

  typesig("foo_2: (B) -> String", false)
  def foo_2(x)
    x.proxy_type.to_s
  end

  typesig("foo_1: (A) -> String", false)
  def foo_1(x)
    z1 = foo_2(x)
    z2 = x.proxy_type.to_s
    z1 + z2
  end
end

rtc_typesig("class Array<t>")
class Array
  rtc_annotated

  typesig("my_push: (Fixnum or String) -> Array<Fixnum or String>", true)
  def my_push(x)
    push(x)
  end
end

class Misc
  rtc_annotated

  typesig("addNum: (Array<Numeric>) -> Array<Numeric>", true)
  def addNum(a)
    a << "foo"
    a
  end
end

class TestProxy < Test::Unit::TestCase
  def test_annotate
    Rtc::MasterSwitch.turn_on if not Rtc::MasterSwitch.is_on?

    x = [0]
    y = x.rtc_annotate("Array<Fixnum>")

    assert_equal("{ProxyObject @object: [0], @proxy_type: Array<Fixnum>}", y.rtc_to_str)
    assert_equal("#<Set: {{ProxyObject @object: [0], @proxy_type: Array<Fixnum>}}>", x.proxies.inspect)

    y = x.rtc_annotate("Array<Fixnum or String>")
    assert_equal("{ProxyObject @object: [0], @proxy_type: Array<(Fixnum or String)>}", y.rtc_to_str)

    x_proxies_str = "#<Set: {{ProxyObject @object: [0], @proxy_type: Array<Fixnum>}, {ProxyObject @object: [0], @proxy_type: Array<(Fixnum or String)>}}>"
    assert_equal(x_proxies_str, x.proxies.inspect)

    z = y.rtc_annotate("Array<Fixnum or String or TrueClass>")
    y_proxies_str = "#<Set: {{ProxyObject @object: [0], @proxy_type: Array<(Fixnum or String or TrueClass)>}}>"
    assert_equal(y_proxies_str, y.proxies.inspect)

    x.push(1)
    assert_equal([0, 1], x)

    x2 = x.push(2)
    x2_proxies_str = "{ProxyObject @object: [0, 1, 2], @proxy_type: Array<(Fixnum)>}"
    assert_equal(x2_proxies_str, x2.rtc_to_str)

    assert_raise Rtc::TypeMismatchException do
      x.push("s")
    end

    y2 = y.push("s")
    y2_proxies_str = "{ProxyObject @object: [0, 1, 2, \"s\", \"s\"], @proxy_type: Array<(Fixnum or String)>}"
    assert_equal(y2_proxies_str, y2.rtc_to_str)
  end

  def test_array_calls
    Rtc::MasterSwitch.turn_on if not Rtc::MasterSwitch.is_on?

    x = [0]
    n = 1
    x.push(n)
    assert_equal([0, 1], x)
    
    np = n.rtc_annotate("Fixnum")
    x.push(np)
    assert_equal([0, 1, 1], x)
  end

  def test_misc_class
    Rtc::MasterSwitch.turn_on if not Rtc::MasterSwitch.is_on?

    x = []
    y = Misc.new
   
    assert_raise Rtc::TypeMismatchException do
      y.addNum(x)
    end
  end

  def ttest_simple_calls
    Rtc::MasterSwitch.turn_on if not Rtc::MasterSwitch.is_on?

    a = [1]
    w = a.rtc_annotate("Array<Fixnum or String>")
    n = 2
    w.push(n)
    w_str = "{ProxyObject @object: [1, 2], @proxy_type: Array<(Fixnum or String)>}"
    assert_equal(w_str, w.rtc_to_str)
    assert_equal(2, n)

    w = [1].rtc_annotate("Array<Fixnum or String>")
    n = 2
    w = w.push(n)
    w_str = "{ProxyObject @object: [1, 2], @proxy_type: Array<(Fixnum or String)>}"
    assert_equal(w_str, w.rtc_to_str)
    assert_equal(2, n)
  end
end

