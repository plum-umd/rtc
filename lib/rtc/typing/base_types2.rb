class Array
  rtc_annotated [:t, :each]

  typesig("'[]' : (Range) -> Array<t>", {'unwrap'=>[0]})
  typesig("'[]' : (Fixnum, Fixnum) -> Array<t>")
  typesig("'[]' : (Fixnum) -> t", {'unwrap'=>[0]})
  typesig("'[]' : (Float) -> t", {'unwrap'=>[0]})
  typesig("'&'<u>: (Array<u>) -> Array<t>")
  typesig("'*': (Fixnum) -> Array<t>")
  typesig("'*': (String) -> String")
  typesig("'+'<u>: (Array<u>) -> Array<u or t>")
  typesig("'-'<u>: (Array<u>) -> Array<t>")
  typesig("slice: (Fixnum) -> t")
  typesig("slice: (Fixnum,Fixnum) -> Array<t>")
  typesig("slice: (Range) -> Array<t>")
  typesig("'[]=': (Fixnum, t) -> t")
  typesig("'[]=': (Fixnum, Fixnum,t) -> t")
  typesig("'[]=': (Fixnum, Fixnum,Array<t>) -> Array<t>")
  typesig("'[]=': (Range,Array<t>) -> Array<t>")
  typesig("'[]=': (Range,t) -> t")
  typesig("assoc: (t) -> Array<t>")
  typesig("at: (Fixnum) -> t")
  typesig("clear: () -> Array<t>")
  typesig("map<u>: () {(t) ->  u } -> Array<u>")
  typesig("collect<u>: () { (t) -> u } -> Array<u>")
  typesig("map<u>: () -> Enumerator")
  typesig("collect<u>: () -> Enumerator")
  typesig("combination: (Fixnum) { (Array<t>) -> %any } -> Array<t>")
  typesig("combination: (Fixnum) -> Enumerator")
  typesig("push: (t) -> Array<t>", {'mutate'=>true})
  typesig("compact: () -> Array<t>")
  typesig("'compact!': () -> Array<t>")
  typesig("concat: (Array<t>) -> Array<t>")
  typesig("count: () -> Fixnum")
  typesig("count: (t) -> Fixnum")
  typesig("count: () { (t) -> %bool } -> Fixnum")
  typesig("cycle: (?Fixnum) { (t) -> %any } -> %any")
  typesig("cycle: (?Fixnum) -> Enumerator")
  typesig("delete<u>: (u) -> t")
  typesig("delete<u,v>: (u) { () -> v } -> t or v")
  typesig("delete_at: (Fixnum) -> Array<t>")
  typesig("delete_if: () { (t) -> %bool } -> Array<t>")
  typesig("delete_if: () -> Enumerator")
  typesig("drop: (Fixnum) -> Array<t>")
  typesig("drop_while: () { (t) -> %bool } -> Array<t>")
  typesig("drop_while: () -> Enumerator")
  typesig("each: () { (t) -> %any } -> Array<t>")
  typesig("each_index: () { (Fixnum) -> %any } -> Array<t>")
  typesig("each_index: () -> Enumerator")
  typesig("'empty?': () -> %bool")
  typesig("fetch: (Fixnum) -> t")
  typesig("fetch<u>: (Fixnum, u) -> u")
  typesig("fetch<u>: (Fixnum) { (Fixnum) -> u } -> t or u")
  typesig("fill: (t) -> Array<t>")
  typesig("fill: (t,Fixnum,?Fixnum) -> Array<t>")
  typesig("fill: (t, Range) -> Array<t>")
  typesig("fill: () { (Fixnum) -> t } -> Array<t>")
  typesig("fill: (Fixnum,?Fixnum) { (Fixnum) -> t } -> Array<t>")
  typesig("fill: (Range) { (Fixnum) -> t } -> Array<t>")
  typesig("index<u>: (u) -> Fixnum")
  typesig("index: () { (t) -> %bool } -> Fixnum")
  typesig("index: () -> Enumerator")
  typesig("first: () -> t")
  typesig("first: (Fixnum) -> Array<t>")
  typesig("'include?'<u>: (u) -> %bool")
  typesig("insert: (Fixnum, *t) -> Array<t>")
  typesig("to_s: () -> String")
  typesig("inspect: () -> String")
  typesig("join: (?String) -> String")
  typesig("keep_if: () { (t) -> %bool } -> Array<t>")
  typesig("last: () -> t")
  typesig("last: (Fixnum) -> Array<t>")
  typesig("length: () -> Fixnum")
  typesig("permutation: (?Fixnum) -> Enumerator")
  typesig("permutation: (?Fixnum) { (Array<t>) -> %any } -> Array<t>")
  typesig("pop: (Fixnum) -> Array<t>")
  typesig("pop: () -> t")
  typesig("product<u>: (*Array<u>) -> Array<Array<t or u>>")
  typesig("rassoc<u>: (u) -> t")
  typesig("reject: () { (t) -> %bool } -> Array<t>")
  typesig("reject: () -> Enumerator")
  typesig("'reject!': () { (t) -> %bool } -> Array<t>")
  typesig("'reject!': () -> Enumerator")
  typesig("repeated_combination: (Fixnum) { (Array<t>) -> %any } -> Array<t>")
  typesig("repeated_combination: (Fixnum) -> Enumerator")
  typesig("repeated_permutation: (Fixnum) { (Array<t>) -> %any } -> Array<t>")
  typesig("repeated_permutation: (Fixnum) -> Enumerator")
  typesig("reverse: () -> Array<t>")
  typesig("'reverse!': () -> Array<t>")
  typesig("reverse_each: () { (t) -> %any } -> Array<t>")
  typesig("reverse_each: () -> Enumerator")
  typesig("rindex<u>: (u) -> t")
  typesig("rindex: () { (t) -> %bool } -> Fixnum")
  typesig("rindex: () -> Enumerator")
  typesig("rotate: (?Fixnum) -> Array<t>")
  typesig("'rotate!': (?Fixnum) -> Array<t>")
  typesig("sample: () -> t")
  typesig("sample: (Fixnum) -> Array<t>")
  typesig("select: () { (t) -> %bool } -> Array<t>")
  typesig("select: () -> Enumerator")
  typesig("'select!': () { (t) -> %bool } -> Array<t>")
  typesig("'select!': () -> Enumerator")
  typesig("shift: () -> t")
  typesig("shift: (Fixnum) -> Array<t>")
  typesig("shuffle: () -> Array<t>")
  typesig("'shuffle!': () -> Array<t>")
  typesig("size: () -> Fixnum")
  typesig("slice: (Range) -> Array<t>", {'unwrap'=>[0]})
  typesig("slice: (Fixnum, Fixnum) -> Array<t>")
  typesig("slice: (Fixnum) -> t", {'unwrap'=>[0]})
  typesig("slice: (Float) -> t", {'unwrap'=>[0]})
  typesig("'slice!': (Range) -> Array<t>", {'unwrap'=>[0]})
  typesig("'slice!': (Fixnum, Fixnum) -> Array<t>")
  typesig("'slice!': (Fixnum) -> t", {'unwrap'=>[0]})
  typesig("'slice!': (Float) -> t", {'unwrap'=>[0]})
  typesig("sort: () -> Array<t>")
  typesig("sort: () { (t,t) -> Fixnum } -> Array<t>")
  typesig("'sort!': () -> Array<t>")
  typesig("'sort!': () { (t,t) -> Fixnum } -> Array<t>")
  typesig("'sort_by!'<u>: () { (t) -> u } -> Array<t>")
  typesig("'sort_by!': () -> Enumerator")
  typesig("take: (Fixnum) -> Array<t>")
  typesig("take_while: () { (t) ->%bool } -> Array<t>")
  typesig("take_while: () -> Enumerator")
  typesig("to_a: () -> Array<t>", {'unwrap' => [-1]})
  typesig("to_ary: () -> Array<t>", {'unwrap' => [-1]})
  typesig("transponse: () -> Array<t>")
  typesig("uniq: () -> Array<t>")
  typesig("'uniq!': () -> Array<t>")
  typesig("unshift: (*t) -> Array<t>")
  typesig("values_at: (*Range or Fixnum) -> Array<t>")
  typesig("zip<u>: (*Array<u>) -> Array<Array<t or u>>", {'unwrap' => [0]})
  typesig("'|'<u>: (Array<u>) -> Array<t or u>")
end

class Rtc::NativeArray < Array
  instance_methods.each {
    |m|
    if self.method_defined?(Rtc::MethodWrapper.mangle_name(m, Array.name))
      eval("alias :#{m} :#{Rtc::MethodWrapper.mangle_name(m, Array.name)}")
    end
  }
end

class Hash
  rtc_annotated [:k, :each_key], [:v, :each_value]

  typesig("'[]' : (k) -> v", {'unwrap'=>[0]})
  typesig("'[]=' : (k, v) -> v", {'unwrap'=>[0]})
  typesig("store: (k,v) -> v", {'unwrap' => [0]})
  typesig("assoc: (k) -> Tuple<k,v>")
  typesig("clear: () -> Hash<k,v>")
  typesig("compare_by_identity: () -> Hash<k,v>")
  typesig("'compare_by_indentity?': () -> %bool")
  typesig("default: (?k) -> v")
  typesig("'default=': (v) -> v")
  typesig("default_proc: () -> (Hash<k,v>,k) -> v")
  typesig("'default_proc=': ((Hash<k,v>,k) -> v) -> (Hash<k,v>,k) -> v")
  typesig("delete: (k) -> v")
  typesig("delete<u>: (k) { (k) -> u } -> u or v")
  typesig("delete_if: () { (k,v) -> %bool } -> Hash<k,v>")
  typesig("delete_if: () -> Enumerator")
  typesig("each: () { (k,v) -> %any } -> Hash<k,v>")
  typesig("each: () -> Enumerator")
  typesig("each_pair: () { (k,v) -> %any } -> Hash<k,v>")
  typesig("each_pair: () -> Enumerator")
  typesig("each_key: () { (k) -> %any } -> Hash<k,v>")
  typesig("each_key: () -> Enumerator")
  typesig("each_value: () { (v) -> %any } -> Hash<k,v>")
  typesig("each_value: () -> Enumerator")
  typesig("'empty?': () -> %bool")
  typesig("fetch: (k) -> v")
  typesig("fetch<u>: (k,u) -> u or v")
  typesig("fetch<u>: (k) { (k) -> u } -> u or v")
  typesig("'member?'<t>: (t) -> %bool")
  typesig("'has_key?'<t>: (t) -> %bool")
  typesig("'key?'<t>: (t) -> %bool")
  typesig("'has_value?'<t>: (t) -> %bool")
  typesig("'value?'<t>: (t) -> %bool")
  typesig("to_s: () -> String")
  typesig("inspect: () -> String")
  typesig("invert: () -> Hash<v,k>")
  typesig("keep_if: () { (k,v) -> %bool } -> Hash<k,v>")
  typesig("keep_if: () -> Enumerator")
  typesig("key<t>: (t) -> k")
  typesig("keys: () -> Array<k>")
  typesig("length: () -> Fixnum")
  typesig("size: () -> Fixnum")
  typesig("merge<a,b>: (Hash<a,b>) -> Hash<a or k, b or v>")
  typesig("merge<a,b>: (Hash<a,b>) { (k,v,b) -> v or b } -> Hash<a or k, b or v>")
  typesig("rassoc: (k) -> Tuple<k,v>")
  typesig("rehash: () -> Hash<k,v>")
  typesig("reject: () -> Enumerator")
  typesig("reject: () { (k,v) -> %bool } -> Hash<k,v>")
  typesig("'reject!': () { (k,v) -> %bool } -> Hash<k,v>")
  typesig("select: () { (k,v) -> %bool } -> Hash<k,v>")
  typesig("'select!': () { (k,v) -> %bool } -> Hash<k,v>")
  typesig("shift: () -> Tuple<k,v>")
  typesig("to_a: () -> Array<Tuple<k,v>>")
  typesig("to_hash: () -> Hash<k,v>")
  typesig("values: () -> Array<v>")
  typesig("values_at: (*k) -> Array<v>")
end

class Rtc::NativeHash
  instance_methods.each {
    |m|
    if self.method_defined?(Rtc::MethodWrapper.mangle_name(m, Hash.name))
      eval("alias :#{m} :#{Rtc::MethodWrapper.mangle_name(m, Hash.name)}")
    end
  }
end