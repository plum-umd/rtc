require "test/unit"
require 'rtc_lib'

module Foo
  module Bar
    class B; end
    class C; end
  end
  module Baz
    class D; end
  end
end

class ParserTestClass
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
  
  typesig("no_return: (Fixnum)")
  def no_return(a)
    
  end
  typesig("type %t = :kind or :subscriber")
  typesig("simple_type_abbreviation: (%t) -> Fixnum")
  def simple_type_abbreviation(a); end
  
  typesig("nested_type_abbreviation: (Array<%t>) -> Fixnum")
  def nested_type_abbreviation(a); end
  
  typesig("type %f = %t or Fixnum")
  typesig("composed_type_abbreviation: (%f) -> Fixnum")
  def composed_type_abbreviation(a); end

  typesig("type %t' = :date or :talks")
  typesig("unioned_unions: (%t') -> Fixnum")
  def unioned_unions(a); end
end

class TestParser < Test::Unit::TestCase
  
  def test_anon_typesig
    my_add_sig = ParserTestClass.new.rtc_typeof("my_add")
    assert_equal(my_add_sig.arg_types, [
      Rtc::Types::NominalType.of(Fixnum), Rtc::Types::NominalType.of(Fixnum)
    ])
    assert_equal(my_add_sig.return_type, Rtc::Types::NominalType.of(Fixnum))
    assert(ParserTestClass.new.rtc_typeof("my_intersection").instance_of?(Rtc::Types::IntersectionType))
    assert(ParserTestClass.new.rtc_typeof("mixed_annotations").instance_of?(Rtc::Types::IntersectionType))
  end
  
  def test_name_resolution
    my_parser = Rtc::TypeAnnotationParser.new(Foo::Bar::B)
    assert_nothing_raised do
      my_parser.scan_str("(C) -> Fixnum")
      my_parser.scan_str("(Baz::D) -> Fixnum")
      my_parser.scan_str("(B) -> Fixnum")
      my_parser.scan_str("(Bar::C) -> Bar::B")
    end
  end
  
  def test_no_return
    assert_equal(ParserTestClass.rtc_instance_typeof("no_return").return_type, Rtc::Types::TopType.instance)
  end

  def test_structural_annotations
    my_parser = Rtc::TypeAnnotationParser.new(Object)
    assert_nothing_raised do
      my_parser.scan_str("foo: ([ to_s: () -> String ]) -> String")
      my_parser.scan_str("'%': (Array<[to_s : () -> String]>) -> String")
    end
  end

  def test_type_abbreviations
    parser = Rtc::TypeAnnotationParser.new(Object)
    simple_msig = ParserTestClass.rtc_instance_typeof("simple_type_abbreviation")
    assert(simple_msig.arg_types[0] <= parser.scan_str("##:kind or :subscriber"))
    
    nested_msig = ParserTestClass.rtc_instance_typeof("nested_type_abbreviation")
    assert(nested_msig.arg_types[0] <= parser.scan_str("##Array<:kind or :subscriber>"))

    composed_msig = ParserTestClass.rtc_instance_typeof("composed_type_abbreviation")
    assert(composed_msig.arg_types[0] <= parser.scan_str("##:kind or :subscriber or Fixnum"))

    unioned_msig = ParserTestClass.rtc_instance_typeof("unioned_unions")
    assert(unioned_msig.arg_types[0] <= parser.scan_str("##:kind or :subscriber or :date or :talks"))

    assert_raise RuntimeError do
      ParserTestClass.instance_exec {
        typesig("type %t = Fixnum")
      }
    end

    assert_raise RuntimeError do
      ParserTestClass.instance_exec {
        typesig("foo: (%undefined)")
      }
    end
  end
end
