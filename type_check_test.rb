require 'rtc'

Rtc::Types::NominalType.of(Array).type_parameters = [:t]

class MyClass
  rtc_annotated
  
  typesig("f: (Fixnum,?String,*Fixnum,Fixnum) -> Fixnum")
  def f(*a)
    a[0] + a[-1]
  end

  typesig("my_method: (:foo or :bar) -> Fixnum")
  def my_method(b)
    5
  end
  typesig("my_other_method: (Array<:subscribers or :talks or :subscribed_talks>) -> Fixnum")
  def my_other_method(b)
    6
  end
end

test_instance = MyClass.new
f_sig = test_instance.rtc_typeof("f")

MyClass.new.f(1,2)
puts "success!"
MyClass.new.my_method(:foo)
MyClass.new.my_other_method([:subscribers, :talks])
