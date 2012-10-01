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

  typesig("bar: () -> String")
  def bar()
    "hello"
  end

  typesig("baz: (B) -> String")
  def baz(x)
    x.proxy_type.to_s
  end

  typesig("foo_2: (B) -> String")
  def foo_2(x)
    x.proxy_type.to_s
  end

  typesig("foo_1: (A) -> String")
  def foo_1(x)
    z1 = foo_2(x)
    z2 = x.proxy_type.to_s
    z1 + z2
  end
end

rtc_typesig("class Array<t>")
class Array
  rtc_annotated

  typesig("f3<w>: (Fixnum) -> Fixnum")
  def f3(x)
    0
  end

  typesig("f2<v>: (Fixnum) -> Fixnum")
  def f2(x)
    f3(x)
  end

  typesig("f1<u>: (Fixnum) -> Fixnum")
  def f1(x)
    f2(x)
  end

  typesig("my_push: (Fixnum or String) -> Array<Fixnum or String>")
  def my_push(x)
    push(x)
  end
end

class MyClass
  rtc_annotated

  typesig("fb: (Fixnum) {(Fixnum) -> String} -> String")
  def fb(blk)
    x = yield(blk)
    x
  end

  typesig("fb_wrong: (Fixnum) {(Fixnum) -> Fixnum} -> String")
  def fb_wrong(blk)
    x = yield(blk)
    x
  end

  typesig("fbp: (t) {(t) -> t} -> String")
  def fbp(blk)
    x = yield(blk)
    x
  end

  typesig("fhi: (Fixnum, (Fixnum) -> String) -> TrueClass", {'unwrap'=>[0]})
  def fhi(x, p)
    if p.call(x) == "0"
      true
    else
      true
    end
  end

  typesig("f1: (Fixnum) -> Fixnum")
  typesig("f1: (String) -> String")
  typesig("f1: (TrueClass) -> TrueClass")
  def f1(x)
    x
  end

  typesig("no_arg_method: () -> .?")
  def no_arg_method()
    "boo"
  end

  typesig("bad_method: () -> Fixnum")
  typesig("bad_method: () -> String")
  def bad_method()
  end

  typesig("weird_method: (t) -> t")
  def weird_method(x)
    x
  end

  typesig("weird_method2: (.?) -> .?")
  def weird_method2(x)
    x
  end
end

class Misc
  rtc_annotated

  typesig("addNum: (Array<Numeric>) -> Array<Numeric>", {'mutate'=>true})
  def addNum(a)
    a << "foo"
    a
  end
end

class A1
  class N1
  end

  class N2
  end
end

class TestProxy < Test::Unit::TestCase
  def test_calls1
    Rtc::MasterSwitch.turn_on if not Rtc::MasterSwitch.is_on?

    x = [3].rtc_annotate("Array<Fixnum or String>")
    n = 0
    x.push(n)

    x_str = "{ProxyObject @object: [3, 0], @proxy_type: Array<(Fixnum or String)>}"

    assert_equal(x_str, x.rtc_to_str)
    Rtc::MasterSwitch.turn_off
    x0 = x[0]
    x1 = x[1]
    x1_str = "{ProxyObject @object: 0, @proxy_type: (Fixnum or String)}"
    Rtc::MasterSwitch.turn_on

    assert_equal(3, x0)
    assert_equal(x1_str, x1.rtc_to_str)

    x.push("s")
    x_str = "{ProxyObject @object: [3, 0, \"s\"], @proxy_type: Array<(Fixnum or String)>}"
    assert_equal(x_str, x.rtc_to_str)

    assert_raise Rtc::TypeMismatchException do
      x.push(true)
    end

    x = [3].rtc_annotate("Array<Fixnum>")
    n = 0.rtc_annotate("Fixnum or String")
    y = x.push(n)

    Rtc::MasterSwitch.turn_off
    x0 = x[0]
    x1 = x[1]
    x1_str = "{ProxyObject @object: 0, @proxy_type: (Fixnum or String)}"

    Rtc::MasterSwitch.turn_on
    assert_equal(3, x0)
    assert_equal(x1_str, x1.rtc_to_str)

    assert_raise Rtc::TypeMismatchException do
      x.push("s")
    end

    x = [3]
    n = 0.rtc_annotate("Fixnum")
    y = x.push(n)

    Rtc::MasterSwitch.turn_off
    x1 = x[1]
    Rtc::MasterSwitch.turn_on
    x1_str = "{ProxyObject @object: 0, @proxy_type: (Fixnum)}"
    assert_equal(x1_str, x1.rtc_to_str)

    r = [1,2].push(3)
    r_str = "{ProxyObject @object: [1, 2, 3], @proxy_type: Array<Fixnum>}"
    assert_equal(r_str, r.rtc_to_str)

    r2 = r[2]
    r2_str = "{ProxyObject @object: 3, @proxy_type: Fixnum}"
    assert_equal(r2_str, r2.rtc_to_str)

    r = [1, 2, "s"].rtc_annotate("Array<Fixnum or String>")
    r2 = r[2]
    r2_str = "{ProxyObject @object: s, @proxy_type: (Fixnum or String)}"
    assert_equal(r2_str, r2.rtc_to_str)
  end

  def test_weird_methods
    Rtc::MasterSwitch.turn_on if not Rtc::MasterSwitch.is_on?

    r = MyClass.new.weird_method(0)
    r_to_str = "{ProxyObject @object: 0, @proxy_type: Fixnum}"
    assert_equal(r_to_str, r.rtc_to_str)

    r = MyClass.new.weird_method2(0)
    r_to_str = "{ProxyObject @object: 0, @proxy_type: t}"
    assert_equal(r_to_str, r.rtc_to_str)

    r = MyClass.new.no_arg_method
    r_to_str = "{ProxyObject @object: boo, @proxy_type: t}"
    assert_equal(r_to_str, r.rtc_to_str)
  end

  def test_intersection
    Rtc::MasterSwitch.turn_on if not Rtc::MasterSwitch.is_on?

    assert_raise Rtc::TypeMismatchException do
      MyClass.new.bad_method
    end

    x = MyClass.new.f1("s")
    x_str = "{ProxyObject @object: s, @proxy_type: String}"
    assert_equal(x_str, x.rtc_to_str)
  end

  def test_block
    Rtc::MasterSwitch.turn_on if not Rtc::MasterSwitch.is_on?

    x = [100, 200]

    Rtc::MasterSwitch.turn_off
    x = Rtc::ProxyObject.new(x, [0,1].rtc_type)
    Rtc::MasterSwitch.turn_on

    x = x.map {|i| i + 1}
    x_str = "{ProxyObject @object: [101, 201], @proxy_type: Array<Fixnum>}"
    assert_equal(x_str, x.rtc_to_str)

    x = [100]
    y = x.push(200)
    x = y.map {|i| i + 1}
    x_str = "{ProxyObject @object: [101, 201], @proxy_type: Array<Fixnum>}"
    assert_equal(x_str, x.rtc_to_str)

    assert_raise Rtc::TypeMismatchException do
      MyClass.new.fbp(3) {|x| x.to_s}
    end

    x = MyClass.new.fbp("3") {|x| x}
    x_str = "{ProxyObject @object: 3, @proxy_type: String}"
    assert_equal(x_str, x.rtc_to_str)

    x = MyClass.new.fb(3) {|x| x.to_s}
    assert_equal("3", x.object)

    assert_raise Rtc::TypeMismatchException do
      MyClass.new.fb_wrong(3) {|x| x.to_s}
    end

    x = MyClass.new.fhi(2, Proc.new {|v| v.to_s + "hello"})
    x_str = "{ProxyObject @object: true, @proxy_type: TrueClass}"
    assert_equal(x_str, x.rtc_to_str)

    assert_raise Rtc::TypeMismatchException do
      MyClass.new.fb("3") {|x| x + 1}
    end
  end

  def ttest_calls1
    Rtc::MasterSwitch.turn_on if not Rtc::MasterSwitch.is_on?
#    x = [3]
#    n = 0.rtc_annotate("Fixnum")
#    y = x.push(n)

#    n = 0.rtc_annotate("Array<Fixnum>")
#    x = [3]
#    x.push(n)

#    n = 0
#    x = [3].rtc_annotate("Array<Fixnum or String>")
#    x.push(n)

    x = [100,200,300]
    y = x.map {|i| i+5}
return
   puts "Y = #{y.inspect}"

  end

  def ttest_stuff
    Rtc::MasterSwitch.turn_on if not Rtc::MasterSwitch.is_on?
    x = [3]
    n = 0.rtc_annotate("Fixnum")

    r = x.push(n)

    puts "--------------------------------------------------------------------------------------------------"

#    r = [1, 2]
#    r = r.map{|x| x + 1}
#    puts "RRRRRRRRR = #{r.inspect}"
#    exit
  end

  def ttest_annotate
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

  def ttest_array_calls
    Rtc::MasterSwitch.turn_on if not Rtc::MasterSwitch.is_on?

    x = [0]
    n = 1
    x.push(n)
    assert_equal([0, 1], x)
    
    np = n.rtc_annotate("Fixnum")
    x.push(np)
    assert_equal([0, 1, 1], x)
  end

  def ttest_misc_class
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

