require 'test/unit'
require 'rtc_lib'

class TestAutoWrap < Test::Unit::TestCase
  class Wrapped
    rtc_annotated
    rtc_autowrap
  end
  
  class SubClass < Wrapped; end
  class SubClassNoSubtype < Wrapped
    no_subtype
  end
  class NoSubtypeWrapped < SubClassNoSubtype
    rtc_autowrap
  end
  def test_autowrapping
    assert(Wrapped.new.is_proxy_object?)
    assert(SubClass.new.is_proxy_object?)
    assert_equal(SubClass.new.rtc_type,Rtc::Types::NominalType.of(SubClass))
    assert(!SubClassNoSubtype.new.is_proxy_object?)
    assert(NoSubtypeWrapped.new.is_proxy_object?)
    assert_equal(NoSubtypeWrapped.new.rtc_type,Rtc::Types::NominalType.of(NoSubtypeWrapped))
  end
end
