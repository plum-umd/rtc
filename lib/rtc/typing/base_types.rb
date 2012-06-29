require 'rtc'

rtc_typesig("class Array<t>")
class Array
  rtc_annotated
  typesig("'[]': (Fixnum) -> t or nil")
  typesig("'[]': (Fixnum, Fixnum) -> Array<t> or nil")
  typesig("'[]': (Range) -> Array<t> or nil")
  typesig("'+': (t) -> Array<t>")
end
rtc_typesig("class Set<t>")
class Set
  rtc_annotated
  define_iterators :t => :each
  typesig("to_a: () -> Array<t>")
  typesig("'includes?': (t) -> TrueClass or FalseClass")
end
