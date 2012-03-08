require 'rtc'
require 'test/unit'
module Foo
  class MyClass
    rtc_annotated
    typesig("foo: (Bar) -> Fixnum")
    typesig("bar: (Gorp) -> Fixnum")
  end
end

class Bar; end

class TestLazy < Test::Unit::TestCase
  @@bar_ident = {
      :type => :absoluet,
      :name_list => ["Bar"]
    }
  def test_lazy()
    my_instance = Foo::MyClass.new
    assert_nothing_raised do
      my_instance.rtc_typeof("foo")
    end
    
    assert_nothing_raised do
      my_instance.rtc_typeof("bar").to_s
    end
    
    assert_raise Rtc::ClassNotFoundException do
      # forces the lazy class
      my_instance.rtc_typeof("foo") <= my_instance.rtc_typeof("bar")
    end
  end
  
  def test_safe_methods
    my_lazy_type =  Rtc::Types::LazyNominalType.new({
      :type => :absolute,
      :name_list => ["FizBiz"]
    }, Object)
    
    assert_nothing_raised do
      my_lazy_type.inspect
      my_lazy_type.to_s
      my_lazy_type.eql?(my_lazy_type)
      my_lazy_type.hash
      my_lazy_type == my_lazy_type
    end
  end
  
  def test_lazy_equality
    my_lazy_1 = Rtc::Types::LazyNominalType.new(@@bar_ident, Object)
    my_lazy_2 = Rtc::Types::LazyNominalType.new(@@bar_ident, Object)
    
    my_nominal_type = Rtc::Types::NominalType.of(Bar)
    
    assert(my_lazy_2 == my_lazy_1)
    assert(my_lazy_2 != my_nominal_type)
    assert_nothing_raised do
      assert(my_lazy_2 <= my_lazy_2)
    end
    
    assert(my_lazy_1 != my_lazy_2)
    assert(my_lazy_2 == my_nominal_type)
    assert_nothing_raised do
      assert(my_lazy_1 <= my_lazy_1)
    end
    
    assert(my_lazy_1 == my_lazy_2)
  end
  
  def test_lazy_forwards
    my_lazy_1 = Rtc::Types::LazyNominalType.new(@@bar_ident, Object)
    assert_nothing_raised do
      my_lazy_1.add_method("foo", Rtc::Types::ProceduralType.new(Rtc::Types::NominalType.of(Fixnum), []))
    end
    
    assert(Rtc::Types::NominalType.of(Bar).get_method("foo") != nil)
    
  end
  
end