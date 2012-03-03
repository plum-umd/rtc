require "test/unit"
require 'rtc'

rtc_typesig("class MyHash<k,v>")
class MyHash
  rtc_annotated
end

module Foo
  rtc_typesig("class MyFooHash<k,v>")
  class MyFooHash
    rtc_annotated
  end
  module Bar
    class B; end
    class C; end
  end
  module Baz
    class D; end
  end
end

class MyClass
  rtc_annotated
  typesig("(Fixnum, Fixnum) -> Fixnum")
  def my_add(a,b)
    a + b
  end
  
  typesig("(Fixnum,Fixnum) -> Fixnum")
  typesig("(String, String) -> String")
  def my_intersection(a,b)
    a + b
  end
  
  typesig("mixed_annotations: (Fixnum) -> Fixnum")
  typesig("(String) -> String")
  def mixed_annotations(a)
    a
  end
end

class TestParser < Test::Unit::TestCase
  def test_annotations_applied
    assert_equal(Rtc::Types::NominalType.of(MyHash).type_parameters,
    [ Rtc::Types::TypeParameter.new(:k), Rtc::Types::TypeParameter.new(:v)])
    assert_equal(Rtc::Types::NominalType.of(Foo::MyFooHash).type_parameters,
    [ Rtc::Types::TypeParameter.new(:k), Rtc::Types::TypeParameter.new(:v)])
  end
  
  def test_anon_typesig
    my_add_sig = MyClass.new.rtc_typeof("my_add")
    assert_equal(my_add_sig.arg_types, [
      Rtc::Types::NominalType.of(Fixnum), Rtc::Types::NominalType.of(Fixnum)
    ])
    assert_equal(my_add_sig.return_type, Rtc::Types::NominalType.of(Fixnum))
    assert(MyClass.new.rtc_typeof("my_intersection").instance_of?(Rtc::Types::IntersectionType))
    assert(MyClass.new.rtc_typeof("mixed_annotations").instance_of?(Rtc::Types::IntersectionType))
  end
  
  def test_name_resolution
    my_parser = Rtc::TypeAnnotationParser.new(Foo::Bar::B)
    assert_nothing_raised do
      my_parser.scan_str("(C) -> Fixnum")
      my_parser.scan_str("(Baz::D) -> Fixnum")
      my_parser.scan_str("(B) -> Fixnum")
      my_parser.scan_str("(D) -> Fixnum")
      my_parser.scan_str("(Bar::C) -> Bar::B")
    end
  end
end