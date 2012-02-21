require 'rtc'

class MyClass
  rtc_annotated
  
  typesig("f: (Fixnum) -> Fixnum")
  def f(a)
    "rar"
  end
end

MyClass.new.f(1)
