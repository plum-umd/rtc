class Fixnum
  rtc_annotated

  typesig("'+': (Fixnum) -> Fixnum", {'unwrap'=>[0]})
  typesig("'*': (Fixnum) -> Fixnum", {'unwrap'=>[0]})
  typesig("'to_s': () -> String")
end


#rtc_typesig("class Array<t>")
class Array
  rtc_annotated [:t, :each]

  alias :old_initialize :initialize

  typesig("'[]' : (Range) -> Array<t>", {'unwrap'=>[0]})
  typesig("'[]' : (Fixnum, Fixnum) -> Array<t>")
  typesig("'[]' : (Fixnum) -> t", {'unwrap'=>[0]})
  typesig("'[]' : (Float) -> t", {'unwrap'=>[0]})
#  typesig("zip<u> : (Array<u>) -> Array<Array<u or t> >")


#  typesig("initialize: (Array<t>) -> Array<t>", true, true)
#  typesig("initialize: () -> Array<t>", true, true)
#  def initialize(*x)
#    if x == nil
#      old_initialize
#    else
#      old_initialize x
#    end
#  end

  typesig("map<u>: () {(t) ->  u } -> Array<u>")
 # typesig("'+': (Array<t>) -> Array<t>")
  typesig("push: (t) -> Array<t>", {'mutate'=>true})
  typesig("each: () { (t) -> .? } -> Array<t>")
end

#rtc_typesig("class Set<t>")
#class Set
#  rtc_annotated
#  define_iterators :t => :each
#  typesig("to_a: () -> Array<t>")
#  typesig("'includes?': (t) -> TrueClass or FalseClass")
#end

#rtc_typesig("class Hash<k, v>")
class Hash
  rtc_annotated [:k, :each_key], [:v, :each_value]

  typesig("'[]' : (k) -> v", {'unwrap'=>[0]})
#  typesig("'[]' : (k) -> v")
  typesig("'[]=' : (k, v) -> v", {'unwrap'=>[0]})
#  typesig("'[]=' : (k, v) -> v")

end
