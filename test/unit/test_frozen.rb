require "test/unit"
require 'rtc'
require 'weakref'
class TestFrozen < Test::Unit::TestCase
  def initialize(*)
    Rtc::Types::NominalType.of(Array).type_parameters = [ Rtc::Types::TypeParameter.new(:t)]
    super
  end

  def test_no_reinit
    test_obj = []
    old_type = test_obj.rtc_type
    old_meta = test_obj.rtc_meta
    assert_equal(old_type.object_id, test_obj.rtc_type.object_id)
    assert_equal(old_meta.object_id, test_obj.rtc_meta.object_id)
  end

  def test_no_reinit_pre_freeze
    test_obj = []
    old_type = test_obj.rtc_type
    old_meta = test_obj.rtc_meta
    test_obj.freeze
    assert_equal(old_type.object_id, test_obj.rtc_type.object_id)
    assert_equal(old_meta.object_id, test_obj.rtc_meta.object_id)
  end

  def test_no_reinit_post_free
    test_obj = []
    test_obj.freeze
    assert_equal(test_obj.rtc_meta.object_id, test_obj.rtc_meta.object_id)
    assert_equal(test_obj.rtc_type.object_id, test_obj.rtc_type.object_id)
  end

  def test_init_mixed
    test_obj = []
    old_type = test_obj.rtc_type
    test_obj.freeze
    old_meta = test_obj.rtc_meta
    assert_equal(old_meta.object_id, test_obj.rtc_meta.object_id)
    assert_equal(old_type.object_id, test_obj.rtc_type.object_id)
  end
end
