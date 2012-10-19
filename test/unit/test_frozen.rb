require "test/unit"
require 'rtc_lib'
require 'weakref'
class TestFrozen < Test::Unit::TestCase
  def test_no_reinit
    test_obj = []
    old_type = test_obj.rtc_type
    old_meta = test_obj.rtc_meta
    #assert_same(old_type, test_obj.rtc_type)
    assert_same(old_meta, test_obj.rtc_meta)
  end

  def test_no_reinit_pre_freeze
    test_obj = []
    old_type = test_obj.rtc_type
    old_meta = test_obj.rtc_meta
    test_obj.freeze
    #assert_same(old_type, test_obj.rtc_type)
    assert_same(old_meta, test_obj.rtc_meta)
  end

  def test_no_reinit_post_free
    test_obj = []
    test_obj.freeze
    assert_same(test_obj.rtc_meta, test_obj.rtc_meta)
    #assert_same(test_obj.rtc_type, test_obj.rtc_type)
  end

  def test_init_mixed
    test_obj = []
    old_type = test_obj.rtc_type
    test_obj.freeze
    old_meta = test_obj.rtc_meta
    assert_same(old_meta, test_obj.rtc_meta)
    #assert_same(old_type, test_obj.rtc_type)
  end
end
