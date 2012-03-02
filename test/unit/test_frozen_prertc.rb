require "test/unit"

class TestFrozenPreRtc < Test::Unit::TestCase

  def initialize(*)
    @a = "MyString"
    @a.freeze
    require 'rtc'
    super
  end
  def test_prefreeze
    assert_nothing_raised do
      @a.rtc_type
      @a.rtc_meta
    end
  end
end
