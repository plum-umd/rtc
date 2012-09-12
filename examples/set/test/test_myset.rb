require 'test/unit'
require 'myset'

class TC_MySet < Test::Unit::TestCase
  def test_aref
    assert_nothing_raised {
      MySet[]
      MySet[nil]
      MySet[1,2,3]
    }

    assert_equal(0, MySet[].size)
    assert_equal(1, MySet[nil].size)
    assert_equal(1, MySet[[]].size)
    assert_equal(1, MySet[[nil]].size)

    set = MySet[2,4,6,4]
    assert_equal(MySet.new([2,4,6]), set)
  end

  def test_s_new
    assert_nothing_raised {
      MySet.new()
      MySet.new(nil)
      MySet.new([])
      MySet.new([1,2])
      MySet.new('a'..'c')
    }
    assert_raises(ArgumentError) {
      MySet.new(false)
    }
    assert_raises(ArgumentError) {
      MySet.new(1)
    }
    assert_raises(ArgumentError) {
      MySet.new(1,2)
    }

    assert_equal(0, MySet.new().size)
    assert_equal(0, MySet.new(nil).size)
    assert_equal(0, MySet.new([]).size)
    assert_equal(1, MySet.new([nil]).size)

    ary = [2,4,6,4]
    set = MySet.new(ary)
    ary.clear
    assert_equal(false, set.empty?)
    assert_equal(3, set.size)

    ary = [1,2,3]

    s = MySet.new(ary) { |o| o * 2 }
    assert_equal([2,4,6], s.sort)
  end

  def test_clone
    set1 = MySet.new
    set2 = set1.clone
    set1 << 'abc'
    assert_equal(MySet.new, set2)
  end

  def test_dup
    set1 = MySet[1,2]
    set2 = set1.dup

    assert_not_same(set1, set2)

    assert_equal(set1, set2)

    set1.add(3)

    assert_not_equal(set1, set2)
  end

  def test_size
    assert_equal(0, MySet[].size)
    assert_equal(2, MySet[1,2].size)
    assert_equal(2, MySet[1,2,1].size)
  end

  def test_empty?
    assert_equal(true, MySet[].empty?)
    assert_equal(false, MySet[1, 2].empty?)
  end

  def test_clear
    set = MySet[1,2]
    ret = set.clear

    assert_same(set, ret)
    assert_equal(true, set.empty?)
  end

  def test_replace
    set = MySet[1,2]
    ret = set.replace('a'..'c')

    assert_same(set, ret)
    assert_equal(MySet['a','b','c'], set)
  end

  def test_to_a
    set = MySet[1,2,3,2]
    ary = set.to_a

    assert_equal([1,2,3], ary.sort)
  end

  def test_flatten
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

    set2 = set1.flatten
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
    set2 = MySet[set1, MySet[set1, 4], 3]

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

    assert_nothing_raised {
      set.flatten
    }

    set1 = empty.merge(MySet["no_more", set])

    assert_nil(MySet.new(0..31).flatten!)

    x = MySet[MySet[],MySet[1,2]].flatten!
    y = MySet[1,2]

    assert_equal(x, y)
  end

  def test_include?
    set = MySet[1,2,3]

    assert_equal(true, set.include?(1))
    assert_equal(true, set.include?(2))
    assert_equal(true, set.include?(3))
    assert_equal(false, set.include?(0))
    assert_equal(false, set.include?(nil))

    set = MySet["1",nil,"2",nil,"0","1",false]
    assert_equal(true, set.include?(nil))
    assert_equal(true, set.include?(false))
    assert_equal(true, set.include?("1"))
    assert_equal(false, set.include?(0))
    assert_equal(false, set.include?(true))
  end

  def test_superset?
    set = MySet[1,2,3]

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
  end

  def test_proper_superset?
    set = MySet[1,2,3]

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
  end

  def test_subset?
    set = MySet[1,2,3]

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
  end

  def test_proper_subset?
    set = MySet[1,2,3]

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
  end

  def test_each
    ary = [1,3,5,7,10,20]
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
  end

  def test_add
    set = MySet[1,2,3]

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
  end

  def test_delete
    set = MySet[1,2,3]

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
  end

  def test_delete_if
    set = MySet.new(1..10)
    ret = set.delete_if { |i| i > 10 }
    assert_same(set, ret)
    assert_equal(MySet.new(1..10), set)

    set = MySet.new(1..10)
    ret = set.delete_if { |i| i % 3 == 0 }
    assert_same(set, ret)
    assert_equal(MySet[1,2,4,5,7,8,10], set)
  end

  def test_collect!
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
  end

  def test_reject!
    set = MySet.new(1..10)

    ret = set.reject! { |i| i > 10 }
    assert_nil(ret)
    assert_equal(MySet.new(1..10), set)

    ret = set.reject! { |i| i % 3 == 0 }
    assert_same(set, ret)
    assert_equal(MySet[1,2,4,5,7,8,10], set)
  end

  def test_merge
    set = MySet[1,2,3]

    ret = set.merge([2,4,6])
    assert_same(set, ret)
    assert_equal(MySet[1,2,3,4,6], set)
  end

  def test_subtract
    set = MySet[1,2,3]

    ret = set.subtract([2,4,6])
    assert_same(set, ret)
    assert_equal(MySet[1,3], set)
  end

  def test_plus
    set = MySet[1,2,3]

    ret = set + [2,4,6]
    assert_not_same(set, ret)
    assert_equal(MySet[1,2,3,4,6], ret)
  end

  def test_minus
    set = MySet[1,2,3]

    ret = set - [2,4,6]
    assert_not_same(set, ret)
    assert_equal(MySet[1,3], ret)
  end

  def test_and
    set = MySet[1,2,3,4]

    ret = set & [2,4,6]
    assert_not_same(set, ret)
    assert_equal(MySet[2,4], ret)
  end

  def test_xor
    set = MySet[1,2,3,4]
    ret = set ^ [2,4,5,5]
    assert_not_same(set, ret)
    assert_equal(MySet[1,3,5], ret)
  end

  def test_eq
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
  end

  # def test_hash
  # end

  # def test_eql?
  # end

  def test_classify
    set = MySet.new(1..10)
    ret = set.classify { |i| i % 3 }

    assert_equal(3, ret.size)
    assert_instance_of(Hash, ret)
    ret.each_value { |value| assert_instance_of(MySet, value) }
    assert_equal(MySet[3,6,9], ret[0])
    assert_equal(MySet[1,4,7,10], ret[1])
    assert_equal(MySet[2,5,8], ret[2])
  end

  def test_divide
    set = MySet.new(1..10)
    ret = set.divide { |i| i % 3 }

    assert_equal(3, ret.size)
    n = 0
    ret.each { |s| n += s.size }
    assert_equal(set.size, n)
    assert_equal(set, ret.flatten)

    set = MySet[7,10,5,11,1,3,4,9,0]
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
  end

  def test_inspect
    set1 = MySet[1]

    assert_equal('#<MySet: {1}>', set1.inspect)

    set2 = MySet[MySet[0], 1, 2, set1]
    assert_equal(false, set2.inspect.include?('#<MySet: {...}>'))

    set1.add(set2)
    assert_equal(true, set1.inspect.include?('#<MySet: {...}>'))
  end

  # def test_pretty_print
  # end

  # def test_pretty_print_cycle
  # end
end

class TC_SortedMySet < Test::Unit::TestCase
  def test_sortedset
    s = SortedMySet[4,5,3,1,2]

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
  end
end

class TC_Enumerable < Test::Unit::TestCase
  def test_to_set
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
  end
end
