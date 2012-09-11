#!/usr/bin/env ruby
#
#  Created by Martin-Louis Bright on 2007-03-21.
#  Copyright (c) 2007. All rights reserved.

require File.join(File.dirname(__FILE__), '..', 'lib', 'sudokusolver')
require 'test/unit'

class SudokuTest < Test::Unit::TestCase
  
  def setup
    @path = File.join(File.dirname(__FILE__), '..')
    @easy = File.read(@path + '/test/easy_puzzles.txt').split("\n")
    @hard = File.read(@path + '/test/top95.txt').split("\n")
    @s = SudokuSolver.new
  end
  
  def test_empty_puzzle
    e = "................................................................................."
    sol = @s.string_solution(@s.search(@s.parse_grid(e)))
#    puts sol
    assert(@s.check_solution(sol))
  end
  
  def test_sanity
    #puts "Easy puzzle (constraint satisfaction only): "
    #puts
    #@s.print_grid(@s.search(@s.parse_grid(@easy[0])))
    @s.search(@s.parse_grid(@easy[0]))
    #puts "Hard puzzle (constraint satisfaction + search): "
    #puts
    #@s.print_grid(@s.search(@s.parse_grid(@hard[0])))
    @s.search(@s.parse_grid(@hard[0]))
  end
  
  def test_easy
    multiple(@easy)
  end
  
  def test_hard
    multiple(@hard)
  end

  def test_bmark_hard
    @hard.each do |g|
      @s.string_solution(@s.search(@s.parse_grid(g)))
    end
  end
  
  def multiple(puzzles)
    puzzles.each do |g|
      assert(@s.check_solution(@s.string_solution(@s.search(@s.parse_grid(g)))))
    end
  end
end
