require "test/unit"

class TestFrozenPreRtc < Test::Unit::TestCase

  def initialize(*)
    @a = "MyString"
    @a.freeze
    require 'rtc_lib'
    super
  end
  def test_prefreeze
    old_meta = nil
    assert_nothing_raised do
      old_meta = @a.rtc_meta
    end
    assert_equal(old_meta.object_id, @a.rtc_meta.object_id)
  end
end
