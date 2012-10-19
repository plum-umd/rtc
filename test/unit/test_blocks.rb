require "test/unit"
require 'rtc_lib'

class TestBlockClass
  rtc_annotated
  typesig("trailing_return<u>: () { (Fixnum) -> u } -> u")
  def trailing_return()
    yield 3
  end
  typesig("block_argument: () { (Fixnum) -> %any } -> %any")
  def block_argument()
    yield "asdf"
  end
  
  typesig("requires_block: () { (Fixnum) -> Fixnum } -> Fixnum")
  def requires_block
    yield 2
  end
end

class TestBlocks < Test::Unit::TestCase
  def test_block_arguments()
    t = TestBlockClass.new.rtc_annotate("TestBlockClass")
    assert_raise Rtc::TypeMismatchException do
      t.block_argument {
        |f|
        f
      }
    end
  end

  def test_trailing_return()
    t = TestBlockClass.new.rtc_annotate("TestBlockClass")
    return_val = nil
    assert_nothing_raised do
      return_val = t.trailing_return {
        |f|
        return f.to_s
      }
    end
    assert_equals("a".rtc_type, return_val.rtc_type)
  end

  def test_require_block
    assert_raise Rtc::TypeMismatchException do
      TestBlockClass.new.rtc_annotate("TestBlockClass").requires_block
    end
  end

end
