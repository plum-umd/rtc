#
# DO NOT MODIFY!!!!
# This file is automatically generated by racc 1.4.5
# from racc grammer file "lib/rtc/annot_parser.racc".
#

require 'racc/parser'



require 'rtc/annot_lexer.rex'
require 'rtc/parser'
require 'rtc/typing/types.rb'

module Rtc

  class TypeAnnotationParser < Racc::Parser

    attr_accessor :pos, :proxy

    # FIXME(rwsims): it's not clear what proxy is for, it's used when defining
    # class constants for doing class type signatures.
    def initialize(proxy)
        @proxy = proxy
    end

    def strip_quotes(arg)
      arg.strip.gsub(/^\"/, "").gsub(/\"$/, "")
    end

    # ####################
    # helper methods for type constructors from ML parser
    # ####################

    
    def pragma(key)
      fail "Unknown pragma keyword: #{key}" if(key !="FIXME")
    end

  end


class TypeAnnotationParser < Racc::Parser

##### racc 1.4.5 generates ###

racc_reduce_table = [
 0, 0, :racc_error,
 1, 48, :_reduce_1,
 1, 48, :_reduce_2,
 1, 48, :_reduce_3,
 1, 48, :_reduce_4,
 3, 53, :_reduce_5,
 3, 53, :_reduce_6,
 3, 53, :_reduce_7,
 2, 49, :_reduce_8,
 2, 50, :_reduce_9,
 2, 51, :_reduce_10,
 6, 52, :_reduce_11,
 1, 60, :_reduce_12,
 0, 60, :_reduce_13,
 2, 55, :_reduce_14,
 3, 55, :_reduce_15,
 1, 62, :_reduce_16,
 0, 62, :_reduce_17,
 2, 56, :_reduce_18,
 3, 56, :_reduce_19,
 6, 63, :_reduce_20,
 3, 63, :_reduce_21,
 6, 61, :_reduce_22,
 3, 61, :_reduce_23,
 6, 61, :_reduce_24,
 3, 61, :_reduce_25,
 5, 61, :_reduce_26,
 8, 61, :_reduce_27,
 1, 61, :_reduce_28,
 1, 67, :_reduce_29,
 1, 67, :_reduce_30,
 1, 67, :_reduce_31,
 1, 64, :_reduce_32,
 3, 64, :_reduce_33,
 5, 66, :_reduce_34,
 6, 66, :_reduce_35,
 4, 66, :_reduce_36,
 3, 66, :_reduce_37,
 0, 68, :_reduce_38,
 3, 68, :_reduce_39,
 1, 65, :_reduce_40,
 3, 65, :_reduce_41,
 1, 70, :_reduce_42,
 1, 70, :_reduce_43,
 1, 69, :_reduce_44,
 2, 69, :_reduce_45,
 1, 71, :_reduce_46,
 3, 71, :_reduce_47,
 2, 58, :_reduce_48,
 1, 58, :_reduce_49,
 1, 54, :_reduce_50,
 1, 72, :_reduce_51,
 3, 72, :_reduce_52,
 1, 73, :_reduce_53,
 1, 73, :_reduce_54,
 1, 73, :_reduce_55,
 1, 73, :_reduce_56,
 2, 73, :_reduce_57,
 2, 73, :_reduce_58,
 2, 73, :_reduce_59,
 3, 73, :_reduce_60,
 4, 73, :_reduce_61,
 1, 73, :_reduce_62,
 5, 73, :_reduce_63,
 3, 74, :_reduce_64,
 1, 59, :_reduce_65,
 3, 59, :_reduce_66,
 4, 76, :_reduce_67,
 1, 76, :_reduce_68,
 2, 57, :_reduce_69,
 2, 57, :_reduce_70,
 3, 77, :_reduce_71,
 1, 78, :_reduce_72,
 1, 78, :_reduce_73,
 3, 78, :_reduce_74,
 3, 78, :_reduce_75,
 0, 75, :_reduce_76,
 1, 75, :_reduce_77 ]

racc_reduce_n = 78

racc_shift_n = 154

racc_action_table = [
     9,    51,    13,    19,   131,    19,    94,    19,    27,    51,
     7,    51,   120,    19,    59,    62,    44,    45,   -18,    45,
    49,    93,   119,    18,    56,    18,    51,    18,    60,    75,
   -17,   -17,   -17,    18,    45,    58,    60,    51,    60,     2,
    46,    19,    59,    62,    44,    45,    85,    84,    49,   -14,
    82,    51,    56,    60,   107,    19,    59,    62,    44,    45,
    67,    18,    49,    58,    60,    51,    56,    80,    46,    19,
    59,    62,    44,    45,   109,    18,    49,    58,    60,    51,
    56,    84,    46,    19,    59,    62,    44,    45,   111,    18,
    49,    58,    60,    51,    56,    27,    46,    19,    59,    62,
    44,    45,    18,    18,    49,    58,    60,    51,    56,   114,
    46,    19,    59,    62,    44,    45,   115,    18,    49,    58,
    60,    51,    56,   116,    46,    19,    59,    62,    44,    45,
   117,    18,    49,    58,    60,    51,    56,   118,    46,    19,
    59,    62,    44,    45,    73,    18,    49,    58,    60,    51,
    56,    72,    46,    19,    59,    62,    44,    45,    71,    18,
    49,    58,    60,    51,    56,   124,    46,    19,    59,    62,
    44,    45,   125,    18,    49,    58,    60,    51,    56,   126,
    46,    19,    59,    62,    44,    45,    69,    18,    49,    58,
    60,    51,    56,    26,    46,   127,    68,    65,   128,    45,
    31,    18,    23,    58,    60,    51,   129,    64,    46,    19,
    59,    62,    44,    45,   130,    27,    49,    53,    60,    51,
    56,    70,   133,    19,    59,    62,    44,    45,    63,    18,
    49,    58,    60,    51,    56,    43,    46,    19,    59,    62,
    44,    45,    89,    18,    49,    58,    60,    89,    56,    18,
    46,    41,    40,    51,    27,    28,    22,    18,    27,    58,
    60,    45,    26,    88,    46,    89,    27,    26,    88,    31,
    51,    23,    21,    51,    31,    26,    23,   123,    45,    29,
    60,    45,    31,   142,    23,    26,    88,   122,   143,    26,
    20,    15,    31,    97,    23,   146,    31,    60,    23,   147,
    60,    35,    36,    37,   -16,   -16,   -16,    27,    27,   150,
   151,    27,    27 ]

racc_action_check = [
     0,    45,     0,     2,   110,    13,    61,     9,    69,   131,
     0,    64,    92,   131,   131,   131,   131,   131,    38,    64,
   131,    59,    92,     2,   131,    13,   124,     9,    45,    38,
     0,     0,     0,   131,   124,   131,   131,    62,    64,     0,
   131,    62,    62,    62,    62,    62,    55,    53,    62,    30,
    52,   130,    62,   124,    76,   130,   130,   130,   130,   130,
    30,    62,   130,    62,    62,    71,   130,    47,    62,    71,
    71,    71,    71,    71,    81,   130,    71,   130,   130,    72,
    71,    82,   130,    72,    72,    72,    72,    72,    83,    71,
    72,    71,    71,    73,    72,    84,    71,    73,    73,    73,
    73,    73,    41,    72,    73,    72,    72,    49,    73,    86,
    72,    49,    49,    49,    49,    49,    88,    73,    49,    73,
    73,    80,    49,    89,    73,    80,    80,    80,    80,    80,
    90,    49,    80,    49,    49,    44,    80,    91,    49,    44,
    44,    44,    44,    44,    37,    80,    44,    80,    80,    85,
    44,    36,    80,    85,    85,    85,    85,    85,    35,    44,
    85,    44,    44,    40,    85,    98,    44,    40,    40,    40,
    40,    40,    99,    85,    40,    85,    85,    94,    40,   101,
    85,    94,    94,    94,    94,    94,    32,    40,    94,    40,
    40,   122,    94,   116,    40,   103,    32,    29,   107,   122,
   116,    94,   116,    94,    94,    27,   108,    29,    94,    27,
    27,    27,    27,    27,   109,    65,    27,    27,   122,   115,
    27,    33,   112,   115,   115,   115,   115,   115,    28,    27,
   115,    27,    27,   111,   115,    22,    27,   111,   111,   111,
   111,   111,   114,   115,   111,   115,   115,    56,   111,    19,
   115,    18,    16,    70,   120,     6,     5,   111,   123,   111,
   111,    70,   114,   114,   111,   117,     6,    56,    56,   114,
   119,   114,     4,    68,    56,     6,    56,    97,   119,     6,
    70,    68,     6,   125,     6,   117,   117,    97,   126,    63,
     3,     1,   117,    63,   117,   137,    63,   119,    63,   139,
    68,    11,    11,    11,     7,     7,     7,   142,   143,   146,
   147,   150,   151 ]

racc_action_pointer = [
    -6,   286,   -16,   285,   267,   256,   240,   268,   nil,   -12,
   nil,   265,   nil,   -14,   nil,   nil,   224,   nil,   232,   210,
   nil,   nil,   235,   nil,   nil,   nil,   nil,   190,   208,   179,
    44,   nil,   168,   193,   nil,   140,   133,   126,    13,   nil,
   148,    63,   nil,   nil,   120,   -14,   nil,    39,   nil,    92,
   nil,   nil,    23,    15,   nil,    42,   232,   nil,   nil,    -1,
   nil,     4,    22,   254,    -4,   189,   nil,   nil,   258,   -18,
   238,    50,    64,    78,   nil,   nil,    25,   nil,   nil,   nil,
   106,    47,    49,    85,    69,   134,   107,   nil,    98,   103,
   128,   106,    -6,   nil,   162,   nil,   nil,   259,   163,   143,
   nil,   150,   nil,   166,   nil,   nil,   nil,   193,   177,   211,
     1,   218,   189,   nil,   227,   204,   158,   250,   nil,   255,
   228,   nil,   176,   232,    11,   265,   270,   nil,   nil,   nil,
    36,    -6,   nil,   nil,   nil,   nil,   nil,   266,   nil,   270,
   nil,   nil,   281,   282,   nil,   nil,   291,   292,   nil,   nil,
   285,   286,   nil,   nil ]

racc_action_default = [
   -13,   -78,   -78,   -78,   -78,   -78,   -78,   -12,    -1,   -78,
    -2,   -78,    -3,   -78,    -4,    -8,   -78,   -49,   -46,   -78,
    -9,   -10,   -78,   -31,   -28,   -32,   -29,   -78,   -78,   -78,
   -13,   -30,   -78,   -68,   -69,   -78,   -78,   -78,   -17,   -70,
   -78,   -78,   -48,   154,   -78,   -78,   -62,   -55,   -53,   -78,
   -44,   -43,   -78,   -38,   -50,   -51,   -76,   -56,   -54,   -78,
   -42,   -65,   -78,   -78,   -78,   -78,   -15,   -12,   -78,   -78,
   -78,   -78,   -78,   -78,   -19,   -16,   -78,   -47,   -58,   -45,
   -78,   -78,   -38,   -37,   -78,   -78,   -72,   -77,   -78,   -78,
   -73,   -78,   -78,   -57,   -78,   -59,   -33,   -78,   -40,   -78,
   -25,   -78,   -23,   -78,    -5,    -6,    -7,   -78,   -78,   -64,
   -36,   -78,   -78,   -52,   -78,   -78,   -78,   -78,   -60,   -78,
   -78,   -66,   -78,   -78,   -78,   -78,   -78,   -67,   -11,   -61,
   -78,   -78,   -34,   -39,   -74,   -71,   -75,   -78,   -21,   -78,
   -26,   -41,   -78,   -78,   -63,   -35,   -78,   -78,   -24,   -22,
   -78,   -78,   -20,   -27 ]

racc_goto_table = [
    24,    78,    52,    87,    96,     3,     1,    98,   104,   105,
   106,    98,    83,    98,    16,    76,    99,    42,    32,    95,
   101,    33,   103,    34,    81,    33,    30,    39,     4,    38,
    14,    79,    12,   113,    10,    91,    66,     8,     5,    77,
   nil,   110,   nil,    74,   nil,   nil,   nil,   nil,   132,   nil,
   nil,   nil,   135,   nil,   nil,   108,   nil,    96,   nil,   100,
   nil,   134,    98,   102,   136,    98,   nil,    98,   145,   121,
   nil,   137,   nil,   nil,   139,   nil,   141,   nil,   112,   nil,
   nil,   nil,   nil,   nil,   nil,   nil,   nil,   144,   nil,   nil,
   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,   nil,   nil,   138,   nil,   nil,   140,   nil,   nil,
   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,   nil,   nil,   nil,   nil,   148,   149,   nil,   nil,
   nil,   nil,   nil,   nil,   152,   153 ]

racc_goto_check = [
    19,    26,    12,    31,    20,     9,     8,    22,     7,     7,
     7,    22,    21,    22,    11,    12,    18,    24,    17,    26,
    18,    11,    18,    29,    12,    11,    14,    29,    10,     6,
     5,    23,     4,    25,     3,    28,     8,     2,     1,    24,
   nil,    21,   nil,     9,   nil,   nil,   nil,   nil,     7,   nil,
   nil,   nil,     7,   nil,   nil,    12,   nil,    20,   nil,    19,
   nil,    31,    22,    19,    31,    22,   nil,    22,     7,    12,
   nil,    18,   nil,   nil,    18,   nil,    18,   nil,    19,   nil,
   nil,   nil,   nil,   nil,   nil,   nil,   nil,    26,   nil,   nil,
   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,   nil,   nil,    19,   nil,   nil,    19,   nil,   nil,
   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,   nil,   nil,   nil,   nil,    19,    19,   nil,   nil,
   nil,   nil,   nil,   nil,    19,    19 ]

racc_goto_pointer = [
   nil,    38,    37,    34,    32,    30,    18,   -63,     6,     5,
    28,    12,   -25,   nil,    20,   nil,   nil,    12,   -48,    -6,
   -59,   -41,   -57,   -14,    -2,   -52,   -43,   nil,   -21,    14,
   nil,   -53 ]

racc_goto_default = [
   nil,   nil,   nil,   nil,   nil,   nil,   nil,    61,   nil,   nil,
   nil,    47,   nil,     6,   nil,    11,    90,    92,   nil,   nil,
    25,   nil,    48,    50,    17,    54,    55,    57,   nil,   nil,
    86,   nil ]

racc_token_table = {
 false => 0,
 Object.new => 1,
 :T_COMMA => 2,
 :T_RARROW => 3,
 :K_OR => 4,
 :T_EOF => 5,
 :K_CLASS => 6,
 :K_METACLASS => 7,
 :K_MODULE => 8,
 :K_INTERFACE => 9,
 :K_TYPE => 10,
 :K_TYPEVAR => 11,
 :K_ALIAS => 12,
 :K_REQUIRE => 13,
 :K_END => 14,
 :K_SELF => 15,
 :T_BEGIN_LINE => 16,
 :T_SEMICOLON => 17,
 :T_COLON => 18,
 :T_DOUBLE_COLON => 19,
 :T_DOT => 20,
 :T_STAR => 21,
 :T_QUESTION => 22,
 :T_CARROT => 23,
 :T_BANG => 24,
 :T_EQUAL => 25,
 :T_LPAREN => 26,
 :T_RPAREN => 27,
 :T_LESS => 28,
 :T_GREATER => 29,
 :T_LBRACKET => 30,
 :T_RBRACKET => 31,
 :T_LBRACE => 32,
 :T_RBRACE => 33,
 :T_SUBTYPE => 34,
 :T_STRING => 35,
 :T_IVAR => 36,
 :T_CVAR => 37,
 :T_GVAR => 38,
 :T_CONST_ID => 39,
 :T_TYPE_ID => 40,
 :T_SYMBOL => 41,
 :T_LOCAL_ID => 42,
 :T_TICKED_ID => 43,
 :T_SUFFIXED_ID => 44,
 :T_DOUBLE_HASH => 45,
 :K_NIL => 46 }

racc_use_result_var = true

racc_nt_base = 47

Racc_arg = [
 racc_action_table,
 racc_action_check,
 racc_action_default,
 racc_action_pointer,
 racc_goto_table,
 racc_goto_check,
 racc_goto_default,
 racc_goto_pointer,
 racc_nt_base,
 racc_reduce_table,
 racc_token_table,
 racc_shift_n,
 racc_reduce_n,
 racc_use_result_var ]

Racc_token_to_s_table = [
'$end',
'error',
'T_COMMA',
'T_RARROW',
'K_OR',
'T_EOF',
'K_CLASS',
'K_METACLASS',
'K_MODULE',
'K_INTERFACE',
'K_TYPE',
'K_TYPEVAR',
'K_ALIAS',
'K_REQUIRE',
'K_END',
'K_SELF',
'T_BEGIN_LINE',
'T_SEMICOLON',
'T_COLON',
'T_DOUBLE_COLON',
'T_DOT',
'T_STAR',
'T_QUESTION',
'T_CARROT',
'T_BANG',
'T_EQUAL',
'T_LPAREN',
'T_RPAREN',
'T_LESS',
'T_GREATER',
'T_LBRACKET',
'T_RBRACKET',
'T_LBRACE',
'T_RBRACE',
'T_SUBTYPE',
'T_STRING',
'T_IVAR',
'T_CVAR',
'T_GVAR',
'T_CONST_ID',
'T_TYPE_ID',
'T_SYMBOL',
'T_LOCAL_ID',
'T_TICKED_ID',
'T_SUFFIXED_ID',
'T_DOUBLE_HASH',
'K_NIL',
'$start',
'entry',
'e_method',
'e_field',
'e_class',
'e_annotation',
'field_sig',
'type_expr',
'method_annotation_list',
'field_annotation_list',
'class_annotation',
'type_ident',
'type_expr_comma_list',
'method_start',
'const_method_type',
'field_start',
'method_type',
'method_name',
'type_id_list',
'method_sig',
'relative_method_name',
'block',
'type_var',
'simple_type_var',
'type_ident_list',
'or_type_list',
'single_type_expr',
'tuple',
'field_or_method_list',
'class_decl',
'field_type',
'field_or_method_nonempty_list']

Racc_debug_parser = false

##### racc system variables end #####

 # reduce 0 omitted

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 49
  def _reduce_1( val, _values, result )
 result = val[0]
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 50
  def _reduce_2( val, _values, result )
 result = val[0]
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 51
  def _reduce_3( val, _values, result )
 result = val[0]
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 52
  def _reduce_4( val, _values, result )
 result = val[0]
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 58
  def _reduce_5( val, _values, result )
        result = handle_var(:ivar, val[0], val[2])
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 60
  def _reduce_6( val, _values, result )
        result = handle_var(:cvar, val[0], val[2])
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 62
  def _reduce_7( val, _values, result )
        result = handle_var(:gvar, val[0], val[2])
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 69
  def _reduce_8( val, _values, result )
 result = val[0]
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 72
  def _reduce_9( val, _values, result )
 result = val[0]
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 75
  def _reduce_10( val, _values, result )
 result = val[0]
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 81
  def _reduce_11( val, _values, result )
  	  	result = Rtc::Types::ParameterizedType.new(handle_type_ident(val[1]), val[3])
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 83
  def _reduce_12( val, _values, result )
 result = nil
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 84
  def _reduce_13( val, _values, result )
 result = nil
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 87
  def _reduce_14( val, _values, result )
 result = [val[1]]
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 91
  def _reduce_15( val, _values, result )
        result = [val[1]] + val[2]
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 93
  def _reduce_16( val, _values, result )
 result = nil
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 94
  def _reduce_17( val, _values, result )
 result = nil
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 97
  def _reduce_18( val, _values, result )
 result = [val[1]]
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 98
  def _reduce_19( val, _values, result )
 result = [val[1]] + val[2]
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 103
  def _reduce_20( val, _values, result )
 result = handle_mtype(val[0], val[2], val[6])
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 105
  def _reduce_21( val, _values, result )
 result = handle_mtype(val[0], nil, val[2])
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 110
  def _reduce_22( val, _values, result )
 result = handle_mtype(val[0], val[2], val[6])
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 112
  def _reduce_23( val, _values, result )
 result = handle_mtype(val[0], nil, val[2])
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 114
  def _reduce_24( val, _values, result )
 result = handle_mtype(val[0], val[2], val[6])
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 116
  def _reduce_25( val, _values, result )
 result = handle_mtype(val[0], nil, val[2])
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 120
  def _reduce_26( val, _values, result )
    	result = handle_mtype(ClassMethodIdentifier.new(val[2]), nil, val[4])
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 121
  def _reduce_27( val, _values, result )
 result = handle_mtype(ClassMethodIdentifier.new(val[2]), val[4], val[7])
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 125
  def _reduce_28( val, _values, result )
       result = handle_mtype(MethodIdentifier.new("__rtc_next_method"), nil, val[0])
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 128
  def _reduce_29( val, _values, result )
 result = val[0]
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 130
  def _reduce_30( val, _values, result )
 result = val[0]
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 132
  def _reduce_31( val, _values, result )
 result = val[0]
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 135
  def _reduce_32( val, _values, result )
 result = MethodIdentifier.new(val[0])
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 136
  def _reduce_33( val, _values, result )
 result = ClassMethodIdentifier.new(val[2])
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 142
  def _reduce_34( val, _values, result )
        result = construct_msig([], val[2], val[4])
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 145
  def _reduce_35( val, _values, result )
        result = construct_msig(val[1], val[3], val[5])
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 148
  def _reduce_36( val, _values, result )
    	result = construct_msig(val[1], val[3], Rtc::Types::TopType.instance)
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 151
  def _reduce_37( val, _values, result )
        result = construct_msig([], val[2], Rtc::Types::TopType.instance)
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 154
  def _reduce_38( val, _values, result )
 result = nil
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 155
  def _reduce_39( val, _values, result )
 result = handle_btype(val[1])
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 158
  def _reduce_40( val, _values, result )
 result = [val[0]]
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 159
  def _reduce_41( val, _values, result )
 result = [val[0]] + val[2]
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 162
  def _reduce_42( val, _values, result )
 result = handle_type_param(:id, val[0])
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 163
  def _reduce_43( val, _values, result )
 result = handle_type_param(:self, val[0])
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 166
  def _reduce_44( val, _values, result )
 result = val[0]
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 169
  def _reduce_45( val, _values, result )
        result = handle_type_param(:varargs, val[1])
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 172
  def _reduce_46( val, _values, result )
 result = [val[0]]
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 176
  def _reduce_47( val, _values, result )
      result = [val[0]] + val[2]
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 184
  def _reduce_48( val, _values, result )
   	  	result = {
   	  		:type => :absolute,
   	  		:name_list => val[1]
   	  	}
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 190
  def _reduce_49( val, _values, result )
        result = {
        	:type => :relative,
        	:name_list => val[0]
        }
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 200
  def _reduce_50( val, _values, result )
        list = val[0][:or_list]
        if(list.length > 1)
          result = Rtc::Types::UnionType.new(list)
        else
          # flatten if there is no union
          result = list[0]
        end
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 202
  def _reduce_51( val, _values, result )
 result = {:or_list => [val[0]]}
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 208
  def _reduce_52( val, _values, result )
        # need to differientiate OR lists from tuples (which are just arrays)
        val[2][:or_list] = [val[0]] + val[2][:or_list]
        result = val[2]
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 210
  def _reduce_53( val, _values, result )
 result = val[0]
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 215
  def _reduce_54( val, _values, result )
    	result = Rtc::Types::SymbolType.new(eval(val[0]))
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 218
  def _reduce_55( val, _values, result )
        result = handle_type_ident(val[0])
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 218
  def _reduce_56( val, _values, result )
 result = val[0]
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 222
  def _reduce_57( val, _values, result )
        result = Rtc::Types::TopType.instance
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 225
  def _reduce_58( val, _values, result )
        result = Rtc::Types::OptionalArg.new(val[1])
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 228
  def _reduce_59( val, _values, result )
        result = Rtc::Types::Vararg.new(val[1])
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 231
  def _reduce_60( val, _values, result )
        result = handle_structural_type(val[1])
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 235
  def _reduce_61( val, _values, result )
        nominal = handle_type_ident(val[0])
        result = Rtc::Types::ParameterizedType.new(nominal, val[2])
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 238
  def _reduce_62( val, _values, result )
    	result = Rtc::Types::NominalType.of(NilClass)
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 242
  def _reduce_63( val, _values, result )
       result = Rtc::Types::ProceduralType.new(val[4], val[1], nil)
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 244
  def _reduce_64( val, _values, result )
 result = val[1]
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 247
  def _reduce_65( val, _values, result )
 result = [val[0]]
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 250
  def _reduce_66( val, _values, result )
        result = [val[0]] + val[2]
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 258
  def _reduce_67( val, _values, result )
        id = val[0]
        type_vars = val[2]
        result = handle_class_decl(id, type_vars)
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 262
  def _reduce_68( val, _values, result )
        id = val[0]
        result = handle_class_decl(id)
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 267
  def _reduce_69( val, _values, result )
        result = val[1]
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 270
  def _reduce_70( val, _values, result )
        result = val[1]
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 276
  def _reduce_71( val, _values, result )
        result = handle_var(:ivar, val[0], val[2])
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 280
  def _reduce_72( val, _values, result )
        result = {:fields => [val[0]], :methods => []}
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 282
  def _reduce_73( val, _values, result )
        result = {:fields => [],       :methods => [val[0]]}
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 287
  def _reduce_74( val, _values, result )
        field_method_hash = val[2]
        field_method_hash[:fields] += [val[0]]
        result = field_method_hash
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 292
  def _reduce_75( val, _values, result )
        field_method_hash = val[2]
        field_method_hash[:methods] += [val[0]]
        result = field_method_hash
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 294
  def _reduce_76( val, _values, result )
 result = {:fields => [], :methods => []}
   result
  end
.,.,

module_eval <<'.,.,', 'lib/rtc/annot_parser.racc', 295
  def _reduce_77( val, _values, result )
 result = val[0]
   result
  end
.,.,

 def _reduce_none( val, _values, result )
  result
 end

end   # class TypeAnnotationParser


end
