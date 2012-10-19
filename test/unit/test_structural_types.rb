require 'test/unit'
require 'rtc_lib'

class StructuralClass
  rtc_annotated
  typesig("join_strings: (Array<[ to_s: () -> String ]>) -> String")
  def join_strings(f)
    strings = f.map {
      |t|
      t.to_s
    }
    strings.join(",")
  end

  typesig("wider_type: ([ to_s: () -> String ]) -> String")
  def wider_type(arg)
    arg.other_method
  end
end

class ProperToS
  rtc_annotated
  typesig("to_s: () -> String")
  def to_s
    "asdf"
  end

  typesig("other_method: () -> String")
  def other_method
    "foo"
  end
end

class BadToS
  rtc_annotated
  typesig("to_s: () -> Fixnum")
  def to_s
    1
  end
end

class TestStructuralTypes < Test::Unit::TestCase
  class A; end
  def test_array_of_structures
    test_instance = StructuralClass.new.rtc_annotate("StructuralClass")
    assert_nothing_raised do
      test_instance.join_strings([ProperToS.new, ProperToS.new])
    end
    assert_raise Rtc::TypeMismatchException do
      test_instance.join_strings([ProperToS.new, BadToS.new])
    end
    assert_raise Rtc::TypeMismatchException do
      test_instance.join_strings([ProperToS.new, A.new ])
    end
  end

  def test_no_type_widening
    test_instance = StructuralClass.new.rtc_annotate("StructuralClass")
    assert_raise NoMethodError do
      test_instance.wider_type(ProperToS.new)
    end
  end
end
