#!/usr/bin/env ruby
#
#  Created by Martin-Louis Bright on 2007-03-21.
#  Copyright (c) 2007. All rights reserved.

require File.join(File.dirname(__FILE__), '..', 'lib', 'sudokusolver')
Rtc::MasterSwitch.turn_off
require 'test/unit'

class SudokuTest < Test::Unit::TestCase
  
  def setup
    @path = File.join(File.dirname(__FILE__), '..')
    @easy = File.read(@path + '/test/easy_puzzles.txt').split("\n")
    @hard = File.read(@path + '/test/top95.txt').split("\n")
    Rtc::MasterSwitch.turn_on
    @s = SudokuSolver.new
    Rtc::MasterSwitch.turn_off
  end
  
  # All the test cases just fed the results of SudokuSolver.search
  # into SudokuSolver.string_solution, even though the former _could_
  # return false.

  def test_empty_puzzle
    Rtc::MasterSwitch.turn_on
    e = "................................................................................."
    hash = @s.search(@s.parse_grid(e)).rtc_cast("Hash<String, String>")
    sol = @s.string_solution(hash)
#    puts sol
    assert(@s.check_solution(sol))
    Rtc::MasterSwitch.turn_off
  end
  
  def test_sanity
    Rtc::MasterSwitch.turn_on
    #puts "Easy puzzle (constraint satisfaction only): "
    #puts
    #@s.print_grid(@s.search(@s.parse_grid(@easy[0])))
    @s.search(@s.parse_grid(@easy[0]))
    #puts "Hard puzzle (constraint satisfaction + search): "
    #puts
    #@s.print_grid(@s.search(@s.parse_grid(@hard[0])))
    @s.search(@s.parse_grid(@hard[0]))
    Rtc::MasterSwitch.turn_off
  end
  
  def test_easy
    Rtc::MasterSwitch.turn_on
    multiple(@easy)
    Rtc::MasterSwitch.turn_off
  end
  
  def test_hard
    Rtc::MasterSwitch.turn_on
    multiple(@hard)
    Rtc::MasterSwitch.turn_off
  end

  def test_bmark_hard
    Rtc::MasterSwitch.turn_on
    @hard.each do |g|
      hash = @s.search(@s.parse_grid(g)).rtc_cast("Hash<String, String>")
      @s.string_solution(hash)
    end
    Rtc::MasterSwitch.turn_off
  end
  
  def multiple(puzzles)
    Rtc::MasterSwitch.turn_on
    puzzles.each do |g|
      hash = @s.search(@s.parse_grid(g)).rtc_cast("Hash<String, String>")
      assert(@s.check_solution(@s.string_solution(hash)))
    end
    Rtc::MasterSwitch.turn_off
  end
end
