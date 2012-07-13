require "test/unit"
require 'rtc'
#require 'weakref'

class A
  def f1
  end

  def f2
  end
end

class B < A
end

class C < B
end

class D < A
end

class F
end

class Array
  rtc_annotated

  typesig("my_f3: () -> Array<t>")
  def my_f3
    self.push("s")
  end

  typesig("my_f2: () -> Array<t>")
  def my_f2
    self + my_f3
  end

  typesig("my_f: () -> Array<t>")
  def my_f
    self + my_f2
  end

  typesig("my_foo2: () -> Array<Fixnum or String>")
  def my_foo2
    self.push("doh")
  end

  typesig("my_foo3: (Array<Fixnum or String>) -> Array<Fixnum or String>")
  def my_foo3(a)
    a.push("doh")
  end

  typesig("my_foo: (Array<t>) -> Array<t>")
  def my_foo(a)
    a.my_foo2
  end

  typesig("my_foo_arg: (Array<t>) -> Array<t>")
  def my_foo_arg(a)
    my_foo3(a)
  end

  typesig("my_a: (t, t) -> Fixnum")
  def my_a(x, y)
    if x.class == Array
      "0"
    else
      0
    end
  end
end

class MyClass
  rtc_annotated

  typesig("fb: (Fixnum) {(Fixnum) -> String} -> String")
  def fb(blk)
    x = yield(blk)
    x
  end

  typesig("fb2: (Fixnum) {(Fixnum) -> String} -> TrueClass")
  def fb2(blk)
    x = yield(blk)
    true
  end

  typesig("fb3: (Fixnum) {(Fixnum) -> String} -> TrueClass")
  def fb3(blk)
    x = yield(blk)

    if x == "3"
      true
    else
      false
    end
  end

  typesig("fbp: (t) {(t) -> u} -> TrueClass or FalseClass")
  def fbp(blk)
    x = yield(blk)

    if x == "3"
      true
    else
      false
    end
  end

#  typesig("fp: (Fixnum, (Fixnum) -> String) -> TrueClass")
  def fp(x, p)
    if p.call("3") == "0"
      false
    else
      "str"
    end
  end

  typesig("fh_simple: (Hash<Fixnum, String>) -> Fixnum")
  def fh_simple(h)
    0
  end

  typesig("fh: (Hash<t, t>) -> Fixnum")
  def fh(h)
    0
  end

  typesig("fh2: (Hash<t, t>) -> t or u or v")
  def fh2(h)
    0
  end

  typesig("foo: (Hash<t, Hash<t, Hash<t, t>>>) -> Fixnum")
  def foo(x)
    0
  end
end

class TestProxy < Test::Unit::TestCase
  def simplify_constraints(h)
    h.to_a.map{|k, v| k.to_s + "->" + v.to_s}
  end

  def test_polymorphic_nested
    parser = Rtc::TypeAnnotationParser.new(Array)

    constraints = {}
    annotation_string = "foo: (Array<t>) -> Fixnum"
    annotation_type = parser.scan_str(annotation_string)[0]
    method_type = annotation_type.type
    assert_equal(false, 0.rtc_type.le_poly(method_type.arg_types[0], {}))
    nested = [[[[[0]]]]].rtc_type.le_poly(method_type.arg_types[0], constraints)
    assert_equal(true, nested)
    nc = ["t->Array<Array<Array<Array<Fixnum>>>>"]
    assert_equal(nc, simplify_constraints(constraints))

    constraints = {}
    annotation_string = "foo: (Array<Array<Array<Array<Array<t>>>>>) -> Fixnum"
    annotation_type = parser.scan_str(annotation_string)[0]
    method_type = annotation_type.type
    assert_equal(false, 0.rtc_type.le_poly(method_type.arg_types[0], {}))
    nested = [[[[[0]]]]].rtc_type.le_poly(method_type.arg_types[0], constraints)
    assert_equal(true, nested)
    nc = ["t->Fixnum"]
    assert_equal(nc, simplify_constraints(constraints))

    constraints = {}
    annotation_string = "foo: (Array<Array<t>>) -> Array<t>"
    annotation_type = parser.scan_str(annotation_string)[0]
    method_type = annotation_type.type
    assert_equal(true, [[0]].rtc_type.le_poly(method_type.arg_types[0], constraints))
    nc = ["t->Fixnum"]
    assert_equal(nc, simplify_constraints(constraints))
    assert_equal(true, [[0]].rtc_type.le_poly(method_type.return_type, constraints))
    nc = ["t->(Fixnum or Array<Fixnum>)"]
    assert_equal(nc, simplify_constraints(constraints))    

    constraints = {}
    annotation_string = "foo: (Array<Array<t>>) -> Array<t> or u"
    annotation_type = parser.scan_str(annotation_string)[0]
    method_type = annotation_type.type
   
    assert_raise Rtc::AmbiguousUnionException do
      [[0]].rtc_type.le_poly(method_type.return_type, constraints)
    end

    assert_equal(true, [[0]].rtc_type.le_poly(method_type.return_type, constraints, true))

    constraints = {}
    annotation_string = "foo: (Array<t> or u) -> Array<t>"
    annotation_type = parser.scan_str(annotation_string)[0]
    method_type = annotation_type.type

    assert_raise Rtc::AmbiguousUnionException do
      [[0]].rtc_type.le_poly(method_type.arg_types[0], constraints)
    end

    assert_equal(true, 0.rtc_type.le_poly(method_type.arg_types[0], constraints))
    assert_equal(["u->Fixnum"], simplify_constraints(constraints))

    constraints = {}
    annotation_string = "foo: (Array<t> or u or v) -> Array<t>"
    annotation_type = parser.scan_str(annotation_string)[0]
    method_type = annotation_type.type

    assert_raise Rtc::AmbiguousUnionException do
      0.rtc_type.le_poly(method_type.arg_types[0], constraints)
    end
  end

  def test_polymorphic_le_poly
    nilt = Rtc::Types::NominalType.of(NilClass)
    tt = Rtc::Types::TypeParameter.new(:t)
    union_type = Rtc::Types::UnionType.of([nilt, tt])

    # if used as arguments
    constraints = {}
    assert_equal(true, 0.rtc_type.le_poly(union_type, constraints))
    nc = simplify_constraints(constraints)
    assert_equal(["t->Fixnum"], nc)

    # if used as return
    constriants = {}
    assert_equal(true, 0.rtc_type.le_poly(union_type, constraints, true))
    nc = simplify_constraints(constraints)
    assert_equal(["t->Fixnum"], nc)

    constraints = {}
    tt = Rtc::Types::TypeParameter.new(:t)
    args = [tt, tt, tt]
    ret = tt
    mt = Rtc::Types::ProceduralType.new(ret, args)
    aat = [true.rtc_type, false.rtc_type, "s".rtc_type]
    amt = Rtc::Types::ProceduralType.new(0.rtc_type, aat)
    constraints = {}
    r = []

    i = 0
    for a in mt.arg_types
      r.push(aat[i].le_poly(a, constraints))
      i += 1
    end

    nc = simplify_constraints(constraints)
    assert_equal([true, true, true], r)
    assert_equal(["t->(TrueClass or FalseClass or String)"], nc)
    
    assert_equal(true, "s".rtc_type.le_poly(ret, constraints))
    nc = simplify_constraints(constraints)
    assert_equal(["t->(TrueClass or FalseClass or String)"], nc)

    assert_equal(true, 0.rtc_type.le_poly(ret, constraints))
    nc = simplify_constraints(constraints)
    assert_equal(["t->(TrueClass or FalseClass or String or Fixnum)"], nc)

    constraints = {}
    t = Rtc::Types::TypeParameter.new(:t)
    u = Rtc::Types::TypeParameter.new(:u)
    ret = Rtc::Types::UnionType.of([t, u])
    
    assert_raise Rtc::AmbiguousUnionException do
      0.rtc_type.le_poly(ret, constraints)
    end

    ut = Rtc::Types::UnionType.of([0.rtc_type, true.rtc_type])
    assert_raise Rtc::AmbiguousUnionException do
      ut.rtc_type.le_poly(ret, constraints)
    end

    assert_equal(true, 0.rtc_type.le_poly(ret, constraints, true))

    constraints = {}
    union_type = Rtc::Types::UnionType.of([0.rtc_type, true.rtc_type, false.rtc_type])
    t = Rtc::Types::TypeParameter.new(:t)
    u = Rtc::Types::TypeParameter.new(:u)
    v = Rtc::Types::TypeParameter.new(:v)
    union_type2 = Rtc::Types::UnionType.of([t, u])
    
    assert_equal(true, union_type.le_poly(t, constraints))
    nc = simplify_constraints(constraints)
    assert_equal(["t->(Fixnum or TrueClass or FalseClass)"], nc)

    constraints = {}
    assert_raise Rtc::AmbiguousUnionException do
      union_type.le_poly(union_type2, constraints)
    end

    assert_equal(true, union_type.le_poly(union_type2, constraints, true))

    parser = Rtc::TypeAnnotationParser.new(Array)

    constraints = {}
    annotation_string = "foo: (Array<t>, Array<Array<t>>, u, v, t, u, u) -> u"
    annotation_type = parser.scan_str(annotation_string)[0]
    method_type = annotation_type.type
    aat = [[0], [[[0]]], [[[[0]]]], 3, true, "s", false]
    constraints = {}
    r = []

    i = 0
    for a in method_type.arg_types
      r.push(aat[i].rtc_type.le_poly(a, constraints))
      i += 1
    end

    assert_equal([true, true, true, true, true, true, true], r)
    nc = simplify_constraints(constraints)
    enc = ["t->(Fixnum or Array<Fixnum> or TrueClass)", "u->(Array<Array<Array<Array<Fixnum>>>> or String or FalseClass)", "v->Fixnum"]
    assert_equal(enc, nc)
  end

  def test_methods
    my_arr = Array.new
    assert_equal(0, my_arr.my_a(0, 0))
    assert_equal(0, my_arr.my_a(0, "0"))

    assert_raise Rtc::TypeMismatchException do
      my_arr.my_a([0], 0)
    end

    my_arr.rtc_inst("my_a: (String, String) -> Fixnum")

    assert_raise Rtc::TypeMismatchException do
      my_arr.my_a(0, 0)
    end
    
    assert_equal(0, my_arr.my_a("0", "0"))
    assert_equal(0, Array.new.my_a(0, 0))
  end

  def test_block
    x = MyClass.new.fb(3) {|x| x.to_s}
    assert_equal("3", x)
    
    assert_raise Rtc::TypeMismatchException do
      MyClass.new.fb2(3) {|x| x + 1}
    end

    assert_raise Rtc::TypeMismatchException do
      MyClass.new.fb3(2) {|x| x.to_s}
    end
    
    x = MyClass.new
    x.rtc_inst("fbp: (t) {(t) -> String} -> TrueClass or FalseClass")
    assert_equal(true, x.fbp(3) {|x| x.to_s})

    assert_raise Rtc::TypeMismatchException do
      x.fbp(3) {|x| x + 1}
    end
  end
    
  def test_proc_arg
    #    obj = MyClass.new.fp(3, Proc.new {|v| v.to_s})
  end
  
  def test_hash
    h = {}
    assert_raise Rtc::TypeMismatchException do
      MyClass.new.fh_simple(h)
    end

    h[1] = nil
    assert_raise Rtc::TypeMismatchException do
      MyClass.new.fh_simple(h)
    end

    h['a'] = 'a'
    assert_raise Rtc::TypeMismatchException do
      MyClass.new.fh_simple(h)
    end

    h = {}
    h[1] = 'a'
    assert_equal(0, MyClass.new.fh_simple(h))

    h['a'] = 'a'
    assert_raise Rtc::TypeMismatchException do
      MyClass.new.fh_simple(h)
    end

    h = {}
    assert_equal(0, MyClass.new.fh(h))

    h[1] = "s"
    assert_equal(0, MyClass.new.fh(h))

    obj = MyClass.new.rtc_inst("fh: (Hash<String, t>) -> Fixnum")
    
    assert_raise Rtc::TypeMismatchException do
      obj.fh(h)
    end

    assert_equal(0, obj.fh({"a"=>1}))

    nh1 = {"b"=>2}
    nh2 = {nh1=>"c"}
    nh3 = {nh2=>nh1}
    obj = MyClass.new.rtc_inst("fh: (Hash<Hash<Hash<String, Fixnum>, String>, Hash<String, Fixnum>>) -> Fixnum")
    assert_equal(0, obj.fh(nh3))

    obj = MyClass.new.rtc_inst("fh: (Hash<Hash<Hash<String, t>, u>, Hash<v, Fixnum>>) -> Fixnum")
    assert_equal(0, obj.fh(nh3))

    obj = MyClass.new.rtc_inst("fh: (Hash<Hash<Hash<String, String>, String>, Hash<String, Fixnum>>) -> Fixnum")

    assert_raise Rtc::TypeMismatchException do
      obj.fh(nh3)
    end

    n1 = {"a"=>1}
    n2 = {"b"=>n1}
    n3 = {{1=>1}=>n2}
    assert_equal(0, obj.foo(n3))

    assert_raise Rtc::TypeMismatchException do
      obj.foo(n2)
    end

    obj.rtc_inst("fh: (Hash<Fixnum or t, Fixnum>) -> Fixnum")
    
    assert_raise Rtc::AmbiguousUnionException do
      obj.fh({1=>2})
    end

    obj.rtc_inst("fh2: (Hash<Fixnum or t, Fixnum>) -> t or u or v")
    assert_equal(0, obj.fh({"1"=>2}))
  end 

  def test_rtc_cast_1
    x = [1,2]
    y = x.rtc_cast("Array<Fixnum>")
    assert_equal(y.proxy_types_to_s, ["Array<Fixnum>"])

    z = y.rtc_cast("Array<Fixnum or String>")
    assert_equal(x.proxy_types_to_s, ["Array<Fixnum>", "Array<(Fixnum or String)>"])
    assert_equal(y.proxy_types_to_s, ["Array<Fixnum>", "Array<(Fixnum or String)>"])
    assert_equal(z.proxy_types_to_s, ["Array<Fixnum>", "Array<(Fixnum or String)>"])

    w = z.rtc_cast("Array<Fixnum>")
    assert_equal(w.proxy_types_to_s, ["Array<Fixnum>", "Array<(Fixnum or String)>"])

    a = [1, 2]

    assert_raise Rtc::CastException do
      a.rtc_cast("Array<TrueClass>")
    end
  end
  
  def test_rtc_annotate_1
    x = [1,2]
    y = x.rtc_annotate("Array<Fixnum>")
    assert_equal(y.proxy_types_to_s, ["Array<Fixnum>"])

    w = x

    w.rtc_annotate("Array<Fixnum or String>")
    assert_equal(w.proxy_types, y.proxy_types)
    assert_equal(w.proxy_types_to_s, ["Array<Fixnum>", "Array<(Fixnum or String)>"])

    assert_raise Rtc::AnnotateException do
      z = w.rtc_annotate("Array<String>")
    end

    z = y.rtc_annotate("Array<Object>")
    assert_equal(z.proxy_types_to_s, ["Array<Fixnum>", "Array<(Fixnum or String)>", "Array<Object>"])
  end

  def test_rtc_annotate_2
    x = [A.new]
    y = x.rtc_annotate("Array<A>")

    assert_raise Rtc::AnnotateException do
      z = y.rtc_annotate("Array<B>")
    end
  end

  def test_rtc_annotate_3
    x = [C.new]
    y = x.rtc_annotate("Array<B>")
    z = y.rtc_annotate("Array<A>")

    assert_equal(x.proxy_types_to_s, ["Array<B>", "Array<A>"])
    assert_equal(y.proxy_types_to_s, ["Array<B>", "Array<A>"])
    assert_equal(z.proxy_types_to_s, ["Array<B>", "Array<A>"])
  end

  def test_plus
    x = [1, 2].rtc_annotate("Array<Fixnum>")
    assert_equal(x + [3, 4], [1, 2, 3, 4])
    assert_equal(x + x, [1, 2, 1, 2])
    assert_equal([100] + [1, 2], [100, 1, 2])

    assert_raise NoMethodError do
      x.boo
    end
  end

  def test_annotation_violation
    assert_raise Rtc::AnnotateException do
      x = [1, 2].rtc_annotate("Array<String>")      
    end

    y = [1, 2].rtc_annotate("Array<Fixnum>")      

    assert_raise Rtc::AnnotateException do
      y.push("doh")
    end    
  end

  def test_proxy_arg
    x = [1, 2]
    y = [3, 4].rtc_annotate("Array<Fixnum>")
    
    assert_raise Rtc::AnnotateException do
      x.my_foo(y)
    end

    assert_raise Rtc::AnnotateException do
      x.my_foo_arg(y)
    end

    begin 
      x.my_foo_arg(y)
    rescue Exception => e
      ss = e.backtrace.to_s
      index_my_foo3 = ss.index("`my_foo3'")
      index_my_foo_arg = ss.index("`my_foo_arg'")
      
      assert_equal(true, index_my_foo3 > -1)
      assert_equal(true, index_my_foo3 < index_my_foo_arg)

      assert_equal(true, e.message.index("Array.push") > -1)
    end

    return
  end

  def test_nested_calls
    x = [1, 2].rtc_annotate("Array<Fixnum>")

    assert_raise Rtc::AnnotateException do
      x.my_f
    end

    begin
      x.my_f
    rescue Exception => e
      ss = e.backtrace.to_s
      index_f3 = ss.index("`my_f3'")
      index_f2 = ss.index("`my_f2'")
      index_f = ss.index("`my_f'")

      assert_equal(true, index_f3 > -1)
      assert_equal(true, index_f3 < index_f2)
      assert_equal(true, index_f2 < index_f)

      assert_equal(true, e.message.index("Array.push") > -1)
    end
  end
end
