#!/usr/bin/env ruby
#
#  Created by Martin-Louis Bright on 2007-04-10.
#  Copyright (c) 2007. All rights reserved.

require 'ruby-prof'
require 'sudokusolver'

puzzle = "4.....8.5.3..........7......2.....6.....8.4......1.......6.3.7.5..2.....1.4......"
Rtc::MasterSwitch.turn_off
RubyProf.start
Rtc::MasterSwitch.turn_on
s  = SudokuSolver.new.rtc_annotate("SudokuSolver")
s.print_grid(s.search(s.parse_grid(puzzle)))
Rtc::MasterSwitch.turn_off
result = RubyProf.stop

printer = RubyProf::GraphPrinter.new(result)
printer.print(STDOUT)
