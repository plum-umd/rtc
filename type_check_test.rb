require 'rtc'

Rtc::Types::NominalType.of(Array).type_parameters = [:t]

class MyClass
  rtc_annotated
  
  typesig("f: (Fixnum,?String,*Fixnum,Fixnum) -> Fixnum")
  def f(*a)
    a[0] + a[-1]
  end
end

test_instance = MyClass.new
f_sig = test_instance.rtc_typeof("f")

MyClass.new.f(1,2)
puts "success!"
