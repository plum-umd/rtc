class Foo
    extend Rtc::Annotated                                                                                                                                    

    typesig("inc: (Numeric) -> Numeric")
  
    def inc(x)
      puts "I'm in here"
      return x + 1
    end


    typesig("factorial: (Numeric) -> Numeric")

    def factorial(n)
      (1..n).reduce(1) { |a, b| a * b }
    end

    typesig("dummy: (String) -> String")

    def dummy(x)
      return x + "hello"
    end

    typesig("f: () -> Numeric")

    def f()
      return 0
    end

    typesig("f2: (['+': (Numeric) -> Numeric]) -> Numeric")

    def f2(x)
      return x + 3
    end

    typesig("f3: (Numeric) -> t")
    
    def f3(x)
      if (x < 0)
        return 3
      else
        puts "doh"
      end
   end

    typesig("f4: (Numeric, t) -> String")
    
    def f4(x, y)
      if y.class.to_s == "Numeric"
        return y.to_s
      else
        return x.to_s + "hello"
      end
    end
end


