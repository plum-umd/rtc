#!/usr/bin/env ruby
#
#  Created by Martin-Louis Bright on 2007-04-10.
#  Copyright (c) 2007. All rights reserved.

require 'sudokusolver'

puzzle = "4.....8.5.3..........7......2.....6.....8.4......1.......6.3.7.5..2.....1.4......"
s  = SudokuSolver.new
s.print_grid(s.search(s.parse_grid(puzzle)))
