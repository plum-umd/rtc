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

class TestProxy < Test::Unit::TestCase
  def same_type(p, v, t)
    pts = p.types.map {|x| x.to_s}
    p.object == v and t == pts   
  end

  def test_rtc_cast_1
    x = [1,2]
    y = x.rtc_cast("Array<Fixnum>")
    assert_equal(same_type(y, [1,2], ["Array<Fixnum>"]), true)

    z = y.rtc_cast("Array<Fixnum or String>")
    assert_equal(same_type(z, [1,2], ["Array<Fixnum>", "Array<(Fixnum or String)>"]), true)

    w = z.rtc_cast("Array<Fixnum>")
    assert_equal(same_type(w, [1,2], ["Array<Fixnum>", "Array<(Fixnum or String)>"]), true)
  end
  
  def test_rtc_annotate_1
    x = [1,2]
    y = x.rtc_annotate("Array<Fixnum>")
    assert_equal(same_type(y, [1,2], ["Array<Fixnum>"]), true)

    a = y.rtc_annotate("Array<Fixnum>")
    assert_equal(same_type(a, [1,2], ["Array<Fixnum>"]), true)

    z = y.rtc_annotate("Array<Fixnum or String>")
    assert_equal(same_type(z, [1,2], ["Array<Fixnum>", "Array<(Fixnum or String)>"]), true)

    z = y.rtc_annotate("Array<Object>")
    assert_equal(same_type(z, [1,2], ["Array<Fixnum>", "Array<(Fixnum or String)>", "Array<Object>"]), true)

    assert_raise Rtc::AnnotateException do
      w = z.rtc_annotate("Array<String>")
    end

    assert_raise Rtc::AnnotateException do
      w = z.rtc_annotate("Array<String>")
    end
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
    
    assert_equal(z.types.map{|x| x.to_s}, ["Array<B>", "Array<A>"])
  end

  def test_methods
    x = [1, 2].rtc_annotate("Array<Fixnum>")
    assert_equal(x + [3, 4], [1, 2, 3, 4])
    assert_equal(x + x, [1, 2, 1, 2])
    assert_equal([100] + [1, 2], [100, 1, 2])

    assert_raise Rtc::NoMethodException do
      x.boo()
    end
  end
end
