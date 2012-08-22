rtc_typesig("class Array<t>")

class Array
  rtc_annotated

  alias :old_initialize :initialize

#  typesig("'[]': (Fixnum) -> t or nil")
  typesig("'[]': (Fixnum) -> t", false, true)

  typesig("initialize: (Array<t>) -> Array<t>", true, true)
  def initialize(x)
    old_initialize x
  end

  typesig("push: (t) -> Array<t>", true, true)

#  typesig("'[]': (Fixnum) -> t or nil")
#  typesig("'[]': (Fixnum, Fixnum) -> Array<t> or nil")
#  typesig("'[]': (Range) -> Array<t> or nil")
#  typesig("'+': (t) -> Array<t>")
#  typesig("push: (t) -> Array<t>")
end

#rtc_typesig("class Set<t>")
#class Set
#  rtc_annotated
#  define_iterators :t => :each
#  typesig("to_a: () -> Array<t>")
#  typesig("'includes?': (t) -> TrueClass or FalseClass")
#end

rtc_typesig("class Hash<k, v>")
class Hash
 # rtc_annotated
end
