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
  
  typesig("two_unsolved_args<t,u>: (u or Array<t>) -> Array<t> or u")
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
  
  typesig("fixnum_block<t>: (Fixnum) { (Fixnum) -> t } -> Array<t>")
  def fixnum_block(limit)
    to_return = []
    for i in 0..limit
      val = yield i
      to_return.push(val)
    end
    to_return
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

  def test_instantiation
    instantiated_proc = instance.rtc_instantiate(:fixnum_block, 
                                                 :t => "Fixnum or String or Float");
    assert_nothing_raised do
      my_ret = instantiated_proc.call(5) {
        |i|
        if i % 3 == 0
          3.1
        elsif i % 3 == 1
          "foo"
        else
          3
        end
      }
      # ensure we don't get type errors due to the return value being
      # annotated incorrectly
      while my_ret.length > 0
        my_ret.pop
      end
    end
    assert_raise Rtc::TypeMismatchException do
      instantiated_proc.call(6) {
        |i|
        if i % 4 == 0
          3.1
        elsif i % 4 == 1
          "foo"
        elsif i % 4 == 2
          :bar
        else
          1
        end
      }
    end

    assert_raise Rtc::TypeMismatchException do
      instance.rtc_instantiate(:identity, :u => "Fixnum")["foo"]
    end

    assert_raise RuntimeError do
      # instantiate only one arg, this is an error
      instance.rtc_instantiate(:two_unsolved_args, :u => "Fixnum")
    end

  end
end
