require 'rtc_lib'

class HashTester
  rtc_annotated
  typesig("symbol_hash_arg: ({:a => String})")
  def symbol_hash_arg(a)
    
  end

  typesig("string_hash_arg: ({'a' => String})")
  def string_hash_arg(a)
  end

  typesig("optional_arg: ({'a' => Fixnum, 'b' => ?String })")
  def optional_arg(a)
  end

  typesig("poly_hash<t>: ({'a' => t}) -> t")
  def poly_hash(a)
    1
  end
  
  typesig("nested_poly_hash<t>: ({'a' => Array<t>}) { (t) -> t } -> t")
  def nested_poly_hash(a)
    yield a["a"][0]
  end
  
  typesig("bad_proxy: ({'a' => Fixnum}, :method or :set or :bad_key)")
  def bad_proxy(hash,behavior)
    if behavior == :method
      hash.each
    elsif behavior == :set
      hash["a"] = "foo"
    elsif behavior == :bad_key
      hash["b"] = "foo"
    end
  end
  
  typesig("good_proxy: ({'a' => Fixnum})")
  def good_proxy(hash)
    hash.has_key?("a")
    hash.member?("a")
    hash.key?("a")
    hash.include?("a")
    hash["a"] = 4
  end
  
  typesig("raw_hash_arg: ({'a' => Fixnum, 'b' => Fixnum}, :to_wide or :to_narrow or :to_opt)")
  def raw_hash_arg(hash,behavior)
    if behavior == :to_wide
      # this should throw a type error
      wider_proxy_arg(hash)
    elsif behavior == :to_narrow
      # this should succeed
      narrow_proxy_arg(hash)
    elsif behavior == :to_opt
      # this should succeed (tests the ability of non-optional members to fullfill optional args
      optional_proxy_arg(hash)
    end
  end
  
  typesig("opt_to_full: ({'a' => Fixnum, 'b' => ?Fixnum, 'c' => Fixnum})")
  def opt_to_full(hash)
    # this should throw a type error
    wider_proxy_arg(hash)
  end
  
  typesig("optional_proxy_arg: ({'a' => Fixnum, 'b' => ?Fixnum })")
  def optional_proxy_arg(a); end

  typesig("wider_proxy_arg: ({'a' => Fixnum, 'b' => Fixnum, 'c' => Fixnum})")
  def wider_proxy_arg(a); end
  typesig("narrow_proxy_arg: ({'a' => Fixnum})")
  def narrow_proxy_arg(a); end
end

class TestHashTypes < Test::Unit::TestCase
  attr_reader :test_instance
  def initialize(*)
    @test_instance = HashTester.new.rtc_annotate("HashTester")
    super
  end
  
  def test_optional
    assert_nothing_raised do
      test_instance.optional_arg({"a" => 1})
      test_instance.optional_arg({"a" => 1, "b" => "foo"})
    end
    
    assert_raise Rtc::TypeMismatchException do
      test_instance.optional_arg({"a" => 1, "b" => 1})
    end
    
    assert_raise Rtc::TypeMismatchException do
      test_instance.optional_arg({"c" => 1})
    end
  end

  def test_wider_hash
    assert_nothing_raised do
      test_instance.symbol_hash_arg({:a => "foo", :b => 2})
    end
  end

  def test_string_hash
    assert_nothing_raised do
      test_instance.string_hash_arg({"a" => "foo"})
    end

    assert_raise Rtc::TypeMismatchException do
      test_instance.string_hash_arg({:a => "foo"})
    end
    
    assert_raise Rtc::TypeMismatchException do
      test_instance.string_hash_arg({"a" => 1})
    end
    
    assert_nothing_raised do
      test_instance.string_hash_arg({"a" => "foo", :a => 1})
    end

  end

  def test_symbol_hash
    assert_nothing_raised do
      test_instance.symbol_hash_arg({:a => "foo"})
    end


    assert_raise Rtc::TypeMismatchException do
      test_instance.symbol_hash_arg({:a => 1})
    end

    assert_raise Rtc::TypeMismatchException do
      test_instance.symbol_hash_arg({"a" => "foo"})
    end
  end

  def test_polymorphic_hash
    assert_raise Rtc::TypeMismatchException do
      test_instance.poly_hash({"a" => "foo"})
    end

    assert_nothing_raised do
      test_instance.poly_hash({"a" => 1})
    end

    assert_nothing_raised do
      test_instance.poly_hash({"a" => 1, "b" => "a"})
    end

    assert_raise Rtc::TypeMismatchException do
      test_instance.poly_hash({"a" => ["a"]})
    end
  end

  def test_nested_polymorphic_hash
    assert_nothing_raised do
      test_instance.nested_poly_hash({"a" => [1]}) {
        |t| t
      }
    end

    assert_raise Rtc::TypeMismatchException do
      test_instance.nested_poly_hash({"a" => ["a"]}) {
        |t| 1
      }
    end
  end

  def test_hash_proxy
    assert_raise RuntimeError do
      test_instance.bad_proxy({"a" => 1}, :method)
    end
    assert_raise Rtc::TypeMismatchException do
      test_instance.bad_proxy({"a" => 1}, :set)
    end
    assert_raise RuntimeError do
      test_instance.bad_proxy({"a" => 1}, :bad_key)
    end
    
    assert_nothing_raised do
      test_instance.good_proxy({"a" => 1})
    end
    
    test_arg = {"a" => 1, "b" => 2 }

    assert_nothing_raised do
      test_instance.raw_hash_arg(test_arg, :to_narrow)
      test_instance.raw_hash_arg(test_arg, :to_opt)
    end
    assert_raise Rtc::TypeMismatchException do
      test_instance.raw_hash_arg(test_arg, :to_wide)
    end
    assert_raise Rtc::TypeMismatchException do
      test_instance.raw_hash_arg({"a" => 1, "b" => 2, "c" => 3}, :to_wide)
    end

    assert_raise Rtc::TypeMismatchException do
      test_instance.opt_to_full({"a" => 1, "b" => 3})
    end
    assert_raise Rtc::TypeMismatchException do
      test_instance.opt_to_full({"a" => 1, "b" => 2, "c" => 3})
    end

  end
end
