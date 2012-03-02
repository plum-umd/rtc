require "test/unit"

class TestFrozenPreRtc < Test::Unit::TestCase

  def initialize(*)
    @a = "MyString"
    @a.freeze
    require 'rtc'
    super
  end
  def test_prefreeze
    old_meta = nil
    old_type = nil
    assert_nothing_raised do
      old_meta = @a.rtc_meta
      old_type = @a.rtc_type
    end
    assert_equal(old_type.object_id, @a.rtc_type.object_id)
    assert_equal(old_meta.object_id, @a.rtc_meta.object_id)
  end
end
