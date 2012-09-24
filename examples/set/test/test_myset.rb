require 'test/unit'
require 'myset'

Rtc::MasterSwitch.turn_off

class TC_MySet < Test::Unit::TestCase
  def test_aref
    Rtc::MasterSwitch.turn_on

    assert_nothing_raised {
#      MySet[]
#      MySet[nil]
#      MySet[1,2,3]

      MySet[].rtc_annotate("MySet<%none>")
      MySet[nil].rtc_annotate("MySet<%none>")
      MySet[1,2,3].rtc_annotate("MySet<Fixnum>")
    }

    #assert_equal(0, MySet[].size)
    #assert_equal(1, MySet[nil].size)
    #assert_equal(1, MySet[[]].size)
    #assert_equal(1, MySet[[nil]].size)

    s = MySet[].rtc_annotate("MySet<%none>")
    assert_equal(0, s.size)
    s = MySet[nil].rtc_annotate("MySet<%none>")
    assert_equal(1, s.size)
    s = MySet[[]].rtc_annotate("MySet<Array<%none>>")
    assert_equal(1, s.size)
    s = MySet[[nil]].rtc_annotate("MySet<Array<%none>>")
    assert_equal(1, s.size)

    set = MySet[2,4,6,4]
    set = set.rtc_annotate("MySet<Fixnum>")
    assert_equal(MySet.new([2,4,6]), set)

    Rtc::MasterSwitch.turn_off
  end

  def test_s_new
    Rtc::MasterSwitch.turn_on

    assert_nothing_raised {
      #MySet.new()
      #MySet.new(nil)
      #MySet.new([])
      #MySet.new([1,2])
      #MySet.new('a'..'c')

      MySet.new().rtc_annotate("MySet<%none>")
      MySet.new(nil).rtc_annotate("MySet<%none>")
      MySet.new([]).rtc_annotate("MySet<%none>")
      MySet.new([1,2]).rtc_annotate("MySet<Fixnum>")
      MySet.new('a'..'c').rtc_annotate("MySet<String>")
    }

    assert_raises(ArgumentError) {
      MySet.new(false)
      #MySet.new(false).rtc_annotate("MySet<False>")
    }
    assert_raises(ArgumentError) {
      MySet.new(1)
    }
    assert_raises(ArgumentError) {
      MySet.new(1,2)
    }

#    assert_equal(0, MySet.new().size)
#    assert_equal(0, MySet.new(nil).size)
#    assert_equal(0, MySet.new([]).size)
#    assert_equal(1, MySet.new([nil]).size)

    s = MySet.new().rtc_annotate("MySet<%none>")
    assert_equal(0, s.size)
    s = MySet.new(nil).rtc_annotate("MySet<%none>")
    assert_equal(0, s.size)
    s = MySet.new([]).rtc_annotate("MySet<%none>")
    assert_equal(0, s.size)
    s = MySet.new([nil]).rtc_annotate("MySet<%none>")
    assert_equal(1, s.size)

#    ary = [2,4,6,4]
#    set = MySet.new(ary)
#    ary.clear
    ary = [2,4,6,4]
    set = MySet.new(ary)   
    set = set.rtc_annotate("MySet<Fixnum>")
    ary.clear
    assert_equal(false, set.empty?)
    assert_equal(3, set.size)

    ary = [1,2,3]

    s = MySet.new(ary) { |o| o * 2 }
    s = s.rtc_annotate("MySet<Fixnum>")
    assert_equal([2,4,6], s.sort)

    Rtc::MasterSwitch.turn_off
  end

  def test_clone
    Rtc::MasterSwitch.turn_on

    set1 = MySet.new

    set1 = set1.rtc_annotate("MySet<String>")

    set2 = set1.clone
    set1 << 'abc'
    assert_equal(MySet.new, set2)

    Rtc::MasterSwitch.turn_off
  end

  def test_dup
    Rtc::MasterSwitch.turn_on
    set1 = MySet[1,2]
    set1 = set1.rtc_annotate("MySet<Fixnum>")
    set2 = set1.dup

#    assert_not_same(set1, set2)  

    assert_equal(set1, set2)

    set1.add(3)

    #assert_not_equal(set1, set2)

    Rtc::MasterSwitch.turn_off
  end

  def test_size
    Rtc::MasterSwitch.turn_on
    #assert_equal(0, MySet[].size)
    #assert_equal(2, MySet[1,2].size)
    #assert_equal(2, MySet[1,2,1].size)
    
    s = MySet[].rtc_annotate("MySet<%none>")
    assert_equal(0, s.size)
    s = MySet[1,2].rtc_annotate("MySet<Fixnum>")
    assert_equal(2, s.size)
    s = MySet[1,2,1].rtc_annotate("MySet<Fixnum>")
    assert_equal(2, s.size)

    Rtc::MasterSwitch.turn_off
  end

  def test_empty?
    Rtc::MasterSwitch.turn_on

    #assert_equal(true, MySet[].empty?)
    #assert_equal(false, MySet[1, 2].empty?)

    s = MySet[].rtc_annotate("MySet<%none>")
    assert_equal(true, s.empty?)
    s = MySet[1, 2].rtc_annotate("MySet<Fixnum>")
    assert_equal(false, s.empty?)

    Rtc::MasterSwitch.turn_off
  end

  def test_clear
    Rtc::MasterSwitch.turn_on

    set = MySet[1,2]
    set = set.rtc_annotate("MySet<Fixnum>")
    ret = set.clear
    assert_same(set, ret)
    assert_equal(true, set.empty?)

    Rtc::MasterSwitch.turn_on
  end

  def test_replace
    Rtc::MasterSwitch.turn_on

    set = MySet[1,2]

    set = set.rtc_annotate("MySet<Fixnum or String>")
    ret = set.replace('a'..'c')

    assert_same(set, ret)
    assert_equal(MySet['a','b','c'], set)
    
    Rtc::MasterSwitch.turn_off
  end

  def test_to_a
    Rtc::MasterSwitch.turn_on

    set = MySet[1,2,3,2]
    set = set.rtc_annotate("MySet<Fixnum>")
    ary = set.to_a

    assert_equal([1,2,3], ary.sort)

    Rtc::MasterSwitch.turn_off
  end

  def test_flatten
    Rtc::MasterSwitch.turn_on

    # test1
    set1 = MySet[
      1,
      MySet[
        5,
        MySet[7,
          MySet[0]
        ],
        MySet[6,2],
        1
      ],
      3,
      MySet[3,4]
    ]

    set1 = set1.rtc_annotate("MySet<Fixnum or MySet<Fixnum or MySet<Fixnum or MySet<Fixnum>>>>")
    set2 = set1.flatten  
exit
    set3 = MySet.new(0..7)

    assert_not_same(set2, set1)
    assert_equal(set3, set2)

    # test2; destructive
    orig_set1 = set1
    set1.flatten!

    assert_same(orig_set1, set1)
    assert_equal(set3, set1)

    # test3; multiple occurrences of a set in an set
    set1 = MySet[1, 2]
    set1 = set1.rtc_annotate("MySet<Fixnum>")
    set2 = MySet[set1, MySet[set1, 4], 3]

    set2 = set2.rtc_annotate("MySet<Fixnum or MySet<MySet<Fixnum> or Fixnum>>")

    assert_nothing_raised {
      set2.flatten!
    }

    assert_equal(MySet.new(1..4), set2)

    # test4; recursion
    set2 = MySet[]
    set1 = MySet[1, set2]
    set2.add(set1)

    assert_raises(ArgumentError) {
      set1.flatten!
    }

    # test5; miscellaneous
    empty = MySet[]
    set =  MySet[MySet[empty, "a"],MySet[empty, "b"]]

    set = set.rtc_annotate("MySet<MySet<String> or String>")

    assert_nothing_raised {
      set.flatten
    }

    empty = empty.rtc_annotate("MySet<MySet<String> or String>")
    set1 = empty.merge(MySet["no_more", set])

    assert_nil(MySet.new(0..31).flatten!)

    x = MySet[MySet[],MySet[1,2]].flatten!
    y = MySet[1,2]

    assert_equal(x, y)

    Rtc::MasterSwitch.turn_off
  end

  def test_include?
    Rtc::MasterSwitch.turn_on

    set = MySet[1,2,3]
    set = set.rtc_annotate("MySet<Fixnum>")

    assert_equal(true, set.include?(1))
    assert_equal(true, set.include?(2))
    assert_equal(true, set.include?(3))
    assert_equal(false, set.include?(0))
    assert_equal(false, set.include?(nil))

    set = MySet["1",nil,"2",nil,"0","1",false]
    set = set.rtc_annotate("MySet<String or FalseClass>")

    assert_equal(true, set.include?(nil))
    assert_equal(true, set.include?(false))
    assert_equal(true, set.include?("1"))
#    assert_equal(false, set.include?(0))
#    assert_equal(false, set.include?(true))

    Rtc::MasterSwitch.turn_off
  end

  def ttest_superset?
    Rtc::MasterSwitch.turn_on

    set = MySet[1,2,3]
    set = set.rtc_annotate("MySet<Fixnum>")

    assert_raises(ArgumentError) {
      set.superset?()
    }

    assert_raises(ArgumentError) {
      set.superset?(2)
    }

    assert_raises(ArgumentError) {
      set.superset?([2])
    }

    assert_equal(true, set.superset?(MySet[]))
    assert_equal(true, set.superset?(MySet[1,2]))
    assert_equal(true, set.superset?(MySet[1,2,3]))
    assert_equal(false, set.superset?(MySet[1,2,3,4]))
    assert_equal(false, set.superset?(MySet[1,4]))

    assert_equal(true, MySet[].superset?(MySet[]))

    Rtc::MasterSwitch.turn_off
  end

  def ttest_proper_superset?
    Rtc::MasterSwitch.turn_off

    set = MySet[1,2,3]
    set = set.rtc_annotate("MySet<Fixnum>")

    assert_raises(ArgumentError) {
      set.proper_superset?()
    }

    assert_raises(ArgumentError) {
      set.proper_superset?(2)
    }

    assert_raises(ArgumentError) {
      set.proper_superset?([2])
    }

    assert_equal(true, set.proper_superset?(MySet[]))
    assert_equal(true, set.proper_superset?(MySet[1,2]))
    assert_equal(false, set.proper_superset?(MySet[1,2,3]))
    assert_equal(false, set.proper_superset?(MySet[1,2,3,4]))
    assert_equal(false, set.proper_superset?(MySet[1,4]))

    assert_equal(false, MySet[].proper_superset?(MySet[]))

    Rtc::MasterSwitch.turn_off
  end

  def ttest_subset?
    Rtc::MasterSwitch.turn_on

    set = MySet[1,2,3]

    set = set.rtc_annotate("MySet<Fixnum>")

    assert_raises(ArgumentError) {
      set.subset?()
    }

    assert_raises(ArgumentError) {
      set.subset?(2)
    }

    assert_raises(ArgumentError) {
      set.subset?([2])
    }

    assert_equal(true, set.subset?(MySet[1,2,3,4]))
    assert_equal(true, set.subset?(MySet[1,2,3]))
    assert_equal(false, set.subset?(MySet[1,2]))
    assert_equal(false, set.subset?(MySet[]))

    assert_equal(true, MySet[].subset?(MySet[1]))
    assert_equal(true, MySet[].subset?(MySet[]))

    Rtc::MasterSwitch.turn_off
  end

  def ttest_proper_subset?
    Rtc::MasterSwitch.turn_on
    
    set = MySet[1,2,3]
    set = set.rtc_annotate("MySet<Fixnum>")

    assert_raises(ArgumentError) {
      set.proper_subset?()
    }

    assert_raises(ArgumentError) {
      set.proper_subset?(2)
    }

    assert_raises(ArgumentError) {
      set.proper_subset?([2])
    }

    assert_equal(true, set.proper_subset?(MySet[1,2,3,4]))
    assert_equal(false, set.proper_subset?(MySet[1,2,3]))
    assert_equal(false, set.proper_subset?(MySet[1,2]))
    assert_equal(false, set.proper_subset?(MySet[]))

    assert_equal(false, MySet[].proper_subset?(MySet[]))

    Rtc::MasterSwitch.turn_off
  end

  def ttest_each
    Rtc::MasterSwitch.turn_on

    ary = [1,3,5,7,10,20]
    ary = ary.rtc_annotate("MySet<Fixnum>")
    set = MySet.new(ary)

    ret = set.each { |o| }
    assert_same(set, ret)

    e = set.each
    assert_instance_of(Enumerator, e)

    assert_nothing_raised {
      set.each { |o|
        ary.delete(o) or raise "unexpected element: #{o}"
      }

      ary.empty? or raise "forgotten elements: #{ary.join(', ')}"
    }

    Rtc::MasterSwitch.turn_off
  end

  def ttest_add
    Rtc::MasterSwitch.turn_on

    set = MySet[1,2,3]
    set = MySet[1,2,3].rtc_annotate("MySet<Fixnum>")

    ret = set.add(2)
    assert_same(set, ret)
    assert_equal(MySet[1,2,3], set)

    ret = set.add?(2)
    assert_nil(ret)
    assert_equal(MySet[1,2,3], set)

    ret = set.add(4)
    assert_same(set, ret)
    assert_equal(MySet[1,2,3,4], set)

    ret = set.add?(5)
    assert_same(set, ret)
    assert_equal(MySet[1,2,3,4,5], set)

    Rtc::MasterSwitch.turn_off
  end

  def ttest_delete
    Rtc::MasterSwitch.turn_on

    set = MySet[1,2,3]
    set = set.rtc_annotate("MySet<Fixnum>")

    ret = set.delete(4)
    assert_same(set, ret)
    assert_equal(MySet[1,2,3], set)

    ret = set.delete?(4)
    assert_nil(ret)
    assert_equal(MySet[1,2,3], set)

    ret = set.delete(2)
    assert_equal(set, ret)
    assert_equal(MySet[1,3], set)

    ret = set.delete?(1)
    assert_equal(set, ret)
    assert_equal(MySet[3], set)

    Rtc::MasterSwitch.turn_off
  end

  def ttest_delete_if
    Rtc::MasterSwitch.turn_on

    set = MySet.new(1..10)
    set = set.rtc_annotate("MySet<Fixnum>")
    ret = set.delete_if { |i| i > 10 }
    assert_same(set, ret)
    assert_equal(MySet.new(1..10), set)

    set = MySet.new(1..10)
    set = set.rtc_annotate("MySet<Fixnum>")
    ret = set.delete_if { |i| i % 3 == 0 }
    assert_same(set, ret)
    assert_equal(MySet[1,2,4,5,7,8,10], set)

    Rtc::MasterSwitch.turn_off
  end

  def ttest_collect!
    Rtc::MasterSwitch.turn_on

    set = MySet[1,2,3,'a','b','c',-1..1,2..4]

    ret = set.collect! { |i|
      case i
      when Numeric
        i * 2
      when String
        i.upcase
      else
        nil
      end
    }

    assert_same(set, ret)
    assert_equal(MySet[2,4,6,'A','B','C',nil], set)

    Rtc::MasterSwitch.turn_off
  end

  def ttest_reject!
    Rtc::MasterSwitch.turn_off

    set = MySet.new(1..10)
    set = set.rtc_annotate("MySet<Fixnum>")

    ret = set.reject! { |i| i > 10 }
    assert_nil(ret)
    assert_equal(MySet.new(1..10), set)

    ret = set.reject! { |i| i % 3 == 0 }
    assert_same(set, ret)
    assert_equal(MySet[1,2,4,5,7,8,10], set)

    Rtc::MasterSwitch.turn_off
  end

  def ttest_merge
    Rtc::MasterSwitch.turn_on
    set = MySet[1,2,3]

    set = set.rtc_annotate("MySet<Fixnum>")

    ret = set.merge([2,4,6])
    assert_same(set, ret)
    assert_equal(MySet[1,2,3,4,6], set)

    Rtc::MasterSwitch.turn_off
  end

  def ttest_subtract
    Rtc::MasterSwitch.turn_on

    set = MySet[1,2,3]

    set = set.rtc_annotate("MySet<Fixnum>")

    ret = set.subtract([2,4,6])
    assert_same(set, ret)
    assert_equal(MySet[1,3], set)

    Rtc::MasterSwitch.turn_off
  end

  def ttest_plus
    Rtc::MasterSwitch.turn_on

    set = MySet[1,2,3]
    set = set.rtc_annotate("MySet<Fixnum>")

    ret = set + [2,4,6]
    assert_not_same(set, ret)
    assert_equal(MySet[1,2,3,4,6], ret)

    Rtc::MasterSwitch.turn_off
  end

  def ttest_minus
    Rtc::MasterSwitch.turn_on

    set = MySet[1,2,3]

    set = set.rtc_annotate("MySet<Fixnum>")

    ret = set - [2,4,6]
    assert_not_same(set, ret)
    assert_equal(MySet[1,3], ret)

    Rtc::MasterSwitch.turn_off
  end

  def ttest_and
    Rtc::MasterSwitch.turn_on
    set = MySet[1,2,3,4]

    set = set.rtc_anntate("MySet<Fixnum>")

    ret = set & [2,4,6]
    assert_not_same(set, ret)
    assert_equal(MySet[2,4], ret)

    Rtc::MasterSwitch.turn_off
  end

  def ttest_xor
    Rtc::MasterSwitch.turn_on
    set = MySet[1,2,3,4]
    set = set.rtc_annotate("MySet<Fixnum>")
    ret = set ^ [2,4,5,5]
    assert_not_same(set, ret)
    assert_equal(MySet[1,3,5], ret)

    Rtc::MasterSwitch.turn_off
  end

  def ttest_eq
    Rtc::MasterSwitch.turn_on

    set1 = MySet[2,3,1]
    set2 = MySet[1,2,3]

    assert_equal(set1, set1)
    assert_equal(set1, set2)
    assert_not_equal(MySet[1], [1])

    set1 = Class.new(MySet)["a", "b"]
    set2 = MySet["a", "b", set1]
    set1 = set1.add(set1.clone)

#    assert_equal(set1, set2)
#    assert_equal(set2, set1)
    assert_equal(set2, set2.clone)
    assert_equal(set1.clone, set1)

    assert_not_equal(MySet[Exception.new,nil], MySet[Exception.new,Exception.new], "[ruby-dev:26127]")

    Rtc::MasterSwitch.turn_off
  end

  # def test_hash
  # end

  # def test_eql?
  # end

  def ttest_classify
    Rtc::MasterSwitch.turn_on

    set = MySet.new(1..10)
    
    set = set.rtc_annotate("MySet<Fixnum>")

    ret = set.classify { |i| i % 3 }

    assert_equal(3, ret.size)
    assert_instance_of(Hash, ret)
    ret.each_value { |value| assert_instance_of(MySet, value) }
    assert_equal(MySet[3,6,9], ret[0])
    assert_equal(MySet[1,4,7,10], ret[1])
    assert_equal(MySet[2,5,8], ret[2])

    Rtc::MasterSwitch.turn_off
  end

  def ttest_divide
    Rtc::MasterSwitch.turn_on
    set = MySet.new(1..10)

    set = set.rtc_annotate("MySet<Fixnum>")
    ret = set.divide { |i| i % 3 }

    assert_equal(3, ret.size)
    n = 0
    ret.each { |s| n += s.size }
    assert_equal(set.size, n)
    assert_equal(set, ret.flatten)

    set = MySet[7,10,5,11,1,3,4,9,0]
    set = set.rtc_annotate("MySet<Fixnum>")
    ret = set.divide { |a,b| (a - b).abs == 1 }

    assert_equal(4, ret.size)
    n = 0
    ret.each { |s| n += s.size }
    assert_equal(set.size, n)
    assert_equal(set, ret.flatten)
    ret.each { |s|
      if s.include?(0)
        assert_equal(MySet[0,1], s)
      elsif s.include?(3)
        assert_equal(MySet[3,4,5], s)
      elsif s.include?(7)
        assert_equal(MySet[7], s)
      elsif s.include?(9)
        assert_equal(MySet[9,10,11], s)
      else
        raise "unexpected group: #{s.inspect}"
      end
    }
    Rtc::MasterSwitch.turn_off
  end

  def ttest_inspect
    Rtc::MasterSwitch.turn_on

    set1 = MySet[1]
    set1 = set1.rtc_annotate("MySet<Fixnum>")

    assert_equal('#<MySet: {1}>', set1.inspect)

    set2 = MySet[MySet[0], 1, 2, set1]
    set = set.rtc_annotate("MySet<Fixnum> or Fixnum")

    assert_equal(false, set2.inspect.include?('#<MySet: {...}>'))

    set1.add(set2)
    assert_equal(true, set1.inspect.include?('#<MySet: {...}>'))

    Rtc::MasterSwitch.turn_off
  end

  # def test_pretty_print
  # end

  # def test_pretty_print_cycle
  # end
end

class TC_SortedMySet < Test::Unit::TestCase
  def ttest_sortedset
    Rtc::MasterSwitch.turn_on

    s = SortedMySet[4,5,3,1,2]

    s = s.rtc_annotate("SortedMySet<Fixnum>")

    assert_equal([1,2,3,4,5], s.to_a)

    prev = nil
    s.each { |o| assert(prev < o) if prev; prev = o }
    assert_not_nil(prev)

    s.map! { |o| -2 * o }

    assert_equal([-10,-8,-6,-4,-2], s.to_a)

    prev = nil
    ret = s.each { |o| assert(prev < o) if prev; prev = o }
    assert_not_nil(prev)
    assert_same(s, ret)

    s = SortedMySet.new([2,1,3]) { |o| o * -2 }
    assert_equal([-6,-4,-2], s.to_a)

    s = SortedMySet.new(['one', 'two', 'three', 'four'])
    a = []
    ret = s.delete_if { |o| a << o; o.start_with?('t') }
    assert_same(s, ret)
    assert_equal(['four', 'one'], s.to_a)
    assert_equal(['four', 'one', 'three', 'two'], a)

    s = SortedMySet.new(['one', 'two', 'three', 'four'])
    a = []
    ret = s.reject! { |o| a << o; o.start_with?('t') }
    assert_same(s, ret)
    assert_equal(['four', 'one'], s.to_a)
    assert_equal(['four', 'one', 'three', 'two'], a)

    s = SortedMySet.new(['one', 'two', 'three', 'four'])
    a = []
    ret = s.reject! { |o| a << o; false }
    assert_same(nil, ret)
    assert_equal(['four', 'one', 'three', 'two'], s.to_a)
    assert_equal(['four', 'one', 'three', 'two'], a)

    Rtc::MasterSwitch.turn_off
  end
end

class TC_Enumerable < Test::Unit::TestCase
  def ttest_to_set
    Rtc::MasterSwitch.turn_on

    ary = [2,5,4,3,2,1,3]

    set = ary.to_set
    assert_instance_of(MySet, set)
    assert_equal([1,2,3,4,5], set.sort)

    set = ary.to_set { |o| o * -2 }
    assert_instance_of(MySet, set)
    assert_equal([-10,-8,-6,-4,-2], set.sort)

    set = ary.to_set(SortedMySet)
    assert_instance_of(SortedMySet, set)
    assert_equal([1,2,3,4,5], set.to_a)

    set = ary.to_set(SortedMySet) { |o| o * -2 }
    assert_instance_of(SortedMySet, set)
    assert_equal([-10,-8,-6,-4,-2], set.sort)

    Rtc::MasterSwitch.turn_off
  end
end
