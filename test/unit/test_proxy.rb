require "test/unit"
require 'rtc'
#require 'weakref'

class A
  def f1
  end

  def f2
  end
end

class B < A
end

class C < B
end

class D < A
end

class F
end

class Array
  rtc_annotated

  typesig("my_f3: () -> Array<t>")
  def my_f3
    self.push("s")
  end

  typesig("my_f2: () -> Array<t>")
  def my_f2
    self + my_f3
  end

  typesig("my_f: () -> Array<t>")
  def my_f
    self + my_f2
  end

  typesig("my_foo2: () -> Array<Fixnum or String>")
  def my_foo2
    self.push("doh")
  end

  typesig("my_foo3: (Array<Fixnum or String>) -> Array<Fixnum or String>")
  def my_foo3(a)
    a.push("doh")
  end

  typesig("my_foo: (Array<t>) -> Array<t>")
  def my_foo(a)
    a.my_foo2
  end

  typesig("my_foo_arg: (Array<t>) -> Array<t>")
  def my_foo_arg(a)
    my_foo3(a)
  end
end

class TestProxy < Test::Unit::TestCase
  def my_to_s(s)
    s.map {|x| x.to_s}
  end
  
  def test_rtc_cast_1
    x = [1,2]
    y = x.rtc_cast("Array<Fixnum>")
    assert_equal(y.proxy_types_to_s, ["Array<Fixnum>"])

    z = y.rtc_cast("Array<Fixnum or String>")
    assert_equal(x.proxy_types_to_s, ["Array<Fixnum>", "Array<(Fixnum or String)>"])
    assert_equal(y.proxy_types_to_s, ["Array<Fixnum>", "Array<(Fixnum or String)>"])
    assert_equal(z.proxy_types_to_s, ["Array<Fixnum>", "Array<(Fixnum or String)>"])

    w = z.rtc_cast("Array<Fixnum>")
    assert_equal(w.proxy_types_to_s, ["Array<Fixnum>", "Array<(Fixnum or String)>"])

    a = [1, 2]

    assert_raise Rtc::CastException do
      a.rtc_cast("Array<TrueClass>")
    end
  end
  
  def test_rtc_annotate_1
    x = [1,2]
    y = x.rtc_annotate("Array<Fixnum>")
    assert_equal(y.proxy_types_to_s, ["Array<Fixnum>"])

    w = x

    w.rtc_annotate("Array<Fixnum or String>")
    assert_equal(w.proxy_types, y.proxy_types)
    assert_equal(w.proxy_types_to_s, ["Array<Fixnum>", "Array<(Fixnum or String)>"])

    assert_raise Rtc::AnnotateException do
      z = w.rtc_annotate("Array<String>")
    end

    z = y.rtc_annotate("Array<Object>")
    assert_equal(z.proxy_types_to_s, ["Array<Fixnum>", "Array<(Fixnum or String)>", "Array<Object>"])
  end

  def test_rtc_annotate_2
    x = [A.new]
    y = x.rtc_annotate("Array<A>")

    assert_raise Rtc::AnnotateException do
      z = y.rtc_annotate("Array<B>")
    end
  end

  def test_rtc_annotate_3
    x = [C.new]
    y = x.rtc_annotate("Array<B>")
    z = y.rtc_annotate("Array<A>")

    assert_equal(x.proxy_types_to_s, ["Array<B>", "Array<A>"])
    assert_equal(y.proxy_types_to_s, ["Array<B>", "Array<A>"])
    assert_equal(z.proxy_types_to_s, ["Array<B>", "Array<A>"])
  end

  def test_plus
    x = [1, 2].rtc_annotate("Array<Fixnum>")
    assert_equal(x + [3, 4], [1, 2, 3, 4])
    assert_equal(x + x, [1, 2, 1, 2])
    assert_equal([100] + [1, 2], [100, 1, 2])

    assert_raise NoMethodError do
      x.boo
    end
  end

  def test_annotation_violation
    assert_raise Rtc::AnnotateException do
      x = [1, 2].rtc_annotate("Array<String>")      
    end

    y = [1, 2].rtc_annotate("Array<Fixnum>")      

    assert_raise Rtc::AnnotateException do
      y.push("doh")
    end    
  end

  def test_proxy_arg
    x = [1, 2]
    y = [3, 4].rtc_annotate("Array<Fixnum>")
    
    assert_raise Rtc::AnnotateException do
      x.my_foo(y)
    end

    assert_raise Rtc::AnnotateException do
      x.my_foo_arg(y)
    end

    begin 
      x.my_foo_arg(y)
    rescue Exception => e
      ss = e.backtrace.to_s
      index_my_foo3 = ss.index("`my_foo3'")
      index_my_foo_arg = ss.index("`my_foo_arg'")
      
      assert_equal(true, index_my_foo3 > -1)
      assert_equal(true, index_my_foo3 < index_my_foo_arg)

      assert_equal(true, e.message.index("Array.push") > -1)
    end

    return
  end

  def test_nested_calls
    x = [1, 2].rtc_annotate("Array<Fixnum>")

    assert_raise Rtc::AnnotateException do
      x.my_f
    end

    begin
      x.my_f
    rescue Exception => e
      ss = e.backtrace.to_s
      index_f3 = ss.index("`my_f3'")
      index_f2 = ss.index("`my_f2'")
      index_f = ss.index("`my_f'")

      assert_equal(true, index_f3 > -1)
      assert_equal(true, index_f3 < index_f2)
      assert_equal(true, index_f2 < index_f)

      assert_equal(true, e.message.index("Array.push") > -1)
    end
  end
end
