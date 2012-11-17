require "test/unit"
require "rtc_lib"

class PolymorphicTests
  rtc_annotated
  typesig("trailing_return<t>: () -> t")
  def trailing_return
    return 2
  end
  
  typesig("unsolved_arg<t>: (Fixnum or Array<t>) -> Fixnum or Array<t>")
  def unsolved_arg(f)
    3
  end
  
  typesig("two_unsovled_args<t,u>: (u or Array<t>) -> Array<t> or u")
  def two_unsolved_args(r)
    4
  end

  typesig("identity<u>: (u) -> u")
  def identity(i)
    i
  end
  
  typesig("bad_identity<u>: (u) -> u")
  def bad_identity(arg)
    3
  end
end

class TestPolymorphicMethod < Test::Unit::TestCase
  attr_accessor :instance
  def setup
    @instance = PolymorphicTests.new.rtc_annotate("PolymorphicTests")
  end

  def test_bad_identity
    assert_raise Rtc::TypeMismatchException do
      instance.bad_identity("foo")
    end
  end

  def test_identity
    to_return = nil
    assert_nothing_raised do
      to_return = instance.identity("foo")
    end
    assert_equal(to_return.rtc_type, "asdf".rtc_type)
    assert_nothing_raised do
      to_return = instance.identity(:foo)
    end
    assert_equal(to_return.rtc_type, :foo.rtc_type)
  end

  def test_unsolved_arg
    to_return = nil
    assert_nothing_raised do
      to_return = instance.unsolved_arg(4)
    end
    assert_equal(Rtc::Types::UnionType.of([
          4.rtc_type,
          Rtc::Types::ParameterizedType.new(Rtc::Types::NominalType.of(Array), [ Rtc::Types::BottomType.instance ])
                                                              ]),to_return.rtc_type)
    assert_nothing_raised do
      to_return = instance.unsolved_arg(["1"])
    end
    assert_equal(to_return.rtc_type, Rtc::Types::UnionType.of([4.rtc_type,Rtc::Types::ParameterizedType.new(Rtc::Types::NominalType.of(Array), [ "4".rtc_type ])]))
  end
end
