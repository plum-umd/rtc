#
# DO NOT MODIFY!!!!
# This file is automatically generated by Racc 1.4.6
# from Racc grammer file "".
#

require 'racc/parser.rb'


require 'rtc/annot_lexer.rex'
require 'rtc/parser'
require 'rtc/typing/types.rb'

module Rtc

#  FIXME(rwsims): this is never called
#  def str_typedef(s)
#    pos = Rtc::Positioning.caller_pos(caller(), 0)
#    ctx = Rtc::ErrorReporting::Context.new(pos, s.to_s)
#    sigs = parse_typesig(s, pos, ctx)
#    sigs.each {|sig| __alias_type(@pos, sig.id, sig.type) }
#  end

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

    def token_text(x)
      x
    end

    def pragma(key)
      fail "Unknown pragma keyword: #{key}" if(key !="FIXME")
    end

  end

class TypeAnnotationParser < Racc::Parser

module_eval(<<'...end annot_parser.racc/module_eval...', 'annot_parser.racc', 436)

...end annot_parser.racc/module_eval...
##### State transition tables begin ###

racc_action_table = [
    13,    65,    14,    17,    16,    35,    77,    79,    78,    67,
    10,    65,    84,   -36,    65,    65,    80,   107,   117,    35,
   105,   118,    67,    67,    52,    34,    92,    75,    64,    65,
   -35,   -35,   -35,    35,    77,    79,    78,    67,    64,    34,
    69,    64,    64,    65,    80,   119,    35,    35,    77,    79,
    78,    67,   120,    34,    69,    75,    64,    65,    80,   121,
   100,    35,    77,    79,    78,    67,    34,    34,    84,    75,
    64,    65,    80,    96,    99,    35,    77,    79,    78,    67,
   105,    34,    69,    75,    64,    65,    80,   128,   129,    35,
    77,    79,    78,    67,    96,    34,    84,    75,    64,    65,
    80,    96,    87,    35,    77,    79,    78,    67,    65,    34,
    84,    75,    64,    65,    80,    61,    67,    35,    77,    79,
    78,    67,   -32,    34,    84,    75,    64,   135,    80,    30,
    31,    32,   136,    43,    65,    64,    65,    34,    92,    75,
    64,    65,    67,    65,    67,    35,    77,    79,    78,    67,
    46,    67,    84,   102,    65,    55,    80,   -34,   -34,   -34,
    45,    64,    67,    64,   106,    34,    92,    75,    64,    65,
    64,   137,    48,    35,    77,    79,    78,    67,   138,    96,
    84,    64,    47,    65,    80,   108,    16,    35,    77,    79,
    78,    67,    57,    34,    84,    75,    64,    65,    80,   143,
   144,    35,    77,    79,    78,    67,   145,    34,    69,    75,
    64,    65,    80,   146,    57,    35,    77,    79,    78,    67,
   134,    34,    84,    75,    64,    55,    80,   148,   149,    54,
   133,    51,    50,    49,    56,    34,    92,    75,    64,    65,
    42,   155,    41,    35,    77,    79,    78,    67,    39,    21,
    84,    20,   160,    65,    80,    19,    96,    35,    77,    79,
    78,    67,   163,    34,    69,    75,    64,    65,    80,    18,
   nil,    35,    77,    79,    78,    67,   nil,    34,    84,    75,
    64,   nil,    80,   nil,   nil,   nil,   nil,   nil,   nil,   nil,
   nil,    34,    92,    75,    64,    65,   nil,   nil,   nil,    35,
    77,    79,    78,    67,   nil,   nil,    84,   nil,   nil,    65,
    80,   nil,   nil,    35,    77,    79,    78,    67,   nil,    34,
    84,    75,    64,   nil,    80,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,   nil,    34,    92,    75,    64,    65,   nil,   nil,
   nil,    35,    77,    79,    78,    67,   nil,   nil,    84,   nil,
   nil,    65,    80,   nil,   nil,    35,    77,    79,    78,    67,
   nil,    34,    84,    75,    64,    65,    80,   nil,   nil,    35,
    77,    79,    78,    67,   nil,    34,    69,    75,    64,    65,
    80,   nil,   nil,    35,    77,    79,    78,    67,   nil,    34,
    69,    75,    64,    65,    80,   nil,   nil,    35,    77,    79,
    78,    67,   nil,    34,    84,    75,    64,    65,    80,   nil,
   nil,    35,    77,    79,    78,    67,   nil,    34,    84,    75,
    64,    65,    80,   nil,   nil,    35,    77,    79,    78,    67,
   nil,    34,    84,    75,    64,   nil,    80,   nil,   nil,   nil,
   nil,   nil,    25,   113,   nil,    34,   nil,    75,    64,    26,
   nil,    27,    28,    25,   113,   nil,   nil,    25,   nil,   nil,
    26,    24,    27,    28,    26,   nil,    27,    28,    25,   113,
   nil,   nil,   nil,   nil,   nil,    26,   nil,    27,    28 ]

racc_action_check = [
     0,   119,     0,     1,     0,   119,   119,   119,   119,   119,
     0,    67,   119,    33,   143,    96,   119,    73,    81,    13,
    70,    88,   143,    96,    33,   119,   119,   119,   119,   163,
     0,     0,     0,   163,   163,   163,   163,   163,    67,    13,
   163,   143,    96,   155,   163,    90,    14,   155,   155,   155,
   155,   155,    92,   163,   155,   163,   163,   146,   155,    93,
    63,   146,   146,   146,   146,   146,    14,   155,   146,   155,
   155,   145,   146,    99,    62,   145,   145,   145,   145,   145,
   102,   146,   145,   146,   146,    78,   145,   103,   104,    78,
    78,    78,    78,    78,    59,   145,    78,   145,   145,    79,
    78,    58,    55,    79,    79,    79,    79,    79,   100,    78,
    79,    78,    78,    84,    79,    40,   100,    84,    84,    84,
    84,    84,    22,    79,    84,    79,    79,   112,    84,    12,
    12,    12,   113,    22,   133,   100,    56,    84,    84,    84,
    84,    69,   133,    45,    56,    69,    69,    69,    69,    69,
    23,    45,    69,    69,    47,    71,    69,    10,    10,    10,
    23,   133,    47,    56,    71,    69,    69,    69,    69,   144,
    45,   114,    24,   144,   144,   144,   144,   144,   115,   117,
   144,    47,    24,    61,   144,    77,    39,    61,    61,    61,
    61,    61,    38,   144,    61,   144,   144,   105,    61,   123,
   124,   105,   105,   105,   105,   105,   125,    61,   105,    61,
    61,   106,   105,   127,    37,   106,   106,   106,   106,   106,
   111,   105,   106,   105,   105,    36,   106,   130,   131,    35,
   111,    32,    31,    30,    36,   106,   106,   106,   106,   136,
    17,   139,    16,   136,   136,   136,   136,   136,    15,     9,
   136,     8,   150,   134,   136,     7,   160,   134,   134,   134,
   134,   134,   162,   136,   134,   136,   136,    57,   134,     6,
   nil,    57,    57,    57,    57,    57,   nil,   134,    57,   134,
   134,   nil,    57,   nil,   nil,   nil,   nil,   nil,   nil,   nil,
   nil,    57,    57,    57,    57,   129,   nil,   nil,   nil,   129,
   129,   129,   129,   129,   nil,   nil,   129,   nil,   nil,   121,
   129,   nil,   nil,   121,   121,   121,   121,   121,   nil,   129,
   121,   129,   129,   nil,   121,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,   nil,   121,   121,   121,   121,    51,   nil,   nil,
   nil,    51,    51,    51,    51,    51,   nil,   nil,    51,   nil,
   nil,   107,    51,   nil,   nil,   107,   107,   107,   107,   107,
   nil,    51,   107,    51,    51,    46,   107,   nil,   nil,    46,
    46,    46,    46,    46,   nil,   107,    46,   107,   107,    48,
    46,   nil,   nil,    48,    48,    48,    48,    48,   nil,    46,
    48,    46,    46,    49,    48,   nil,   nil,    49,    49,    49,
    49,    49,   nil,    48,    49,    48,    48,    50,    49,   nil,
   nil,    50,    50,    50,    50,    50,   nil,    49,    50,    49,
    49,   120,    50,   nil,   nil,   120,   120,   120,   120,   120,
   nil,    50,   120,    50,    50,   nil,   120,   nil,   nil,   nil,
   nil,   nil,   137,   137,   nil,   120,   nil,   120,   120,   137,
   nil,   137,   137,    80,    80,   nil,   nil,    11,   nil,   nil,
    80,    11,    80,    80,    11,   nil,    11,    11,   138,   138,
   nil,   nil,   nil,   nil,   nil,   138,   nil,   138,   138 ]

racc_action_pointer = [
    -6,     3,   nil,   nil,   nil,   nil,   264,   250,   246,   244,
   121,   422,    93,     0,    27,   231,   203,   240,   nil,   nil,
   nil,   nil,   117,   132,   154,   nil,   nil,   nil,   nil,   nil,
   215,   214,   213,     8,   nil,   190,   206,   180,   158,   176,
    97,   nil,   nil,   nil,   nil,   128,   350,   139,   364,   378,
   392,   322,   nil,   nil,   nil,    63,   121,   252,    84,    77,
   nil,   168,    45,    58,   nil,   nil,   nil,    -4,   nil,   126,
   -12,   136,   nil,    13,   nil,   nil,   nil,   163,    70,    84,
   418,   -11,   nil,   nil,    98,   nil,   nil,   nil,    -8,   nil,
    41,   nil,    34,    57,   nil,   nil,     0,   nil,   nil,    56,
    93,   nil,    48,    60,    85,   182,   196,   336,   nil,   nil,
   nil,   202,    96,   114,   169,   176,   nil,   162,   nil,   -14,
   406,   294,   nil,   197,   166,   188,   nil,   210,   nil,   280,
   194,   199,   nil,   119,   238,   nil,   224,   407,   433,   223,
   nil,   nil,   nil,    -1,   154,    56,    42,   nil,   nil,   nil,
   223,   nil,   nil,   nil,   nil,    28,   nil,   nil,   nil,   nil,
   239,   nil,   244,    14,   nil ]

racc_action_default = [
   -31,  -105,    -1,    -2,    -3,    -4,  -105,  -105,  -105,  -105,
   -30,  -105,  -105,  -105,  -105,  -101,  -105,  -105,   -26,   -27,
   -28,   -29,   -31,  -105,  -105,   -45,   -46,   -47,   -48,   -49,
  -105,  -105,  -105,   -35,   -60,  -105,   -86,   -83,   -83,  -105,
  -105,  -104,   165,   -30,   -33,  -105,  -105,  -105,  -105,  -105,
  -105,  -105,   -34,   -37,   -61,  -105,  -105,  -105,   -89,   -89,
  -102,  -105,  -105,   -54,   -56,   -57,   -58,  -105,   -40,  -105,
   -52,   -68,   -63,   -64,   -66,   -67,   -69,  -105,  -105,  -105,
   -99,  -105,   -42,   -22,  -105,   -23,   -24,   -62,  -105,   -76,
   -77,   -79,  -105,   -81,   -84,   -87,  -105,   -88,  -103,   -89,
  -105,   -59,   -52,  -105,  -105,  -105,  -105,  -105,   -70,   -71,
   -72,  -105,  -105,  -105,   -95,   -96,  -100,   -89,   -85,  -105,
  -105,  -105,   -90,   -91,  -105,  -105,   -55,  -105,   -75,  -105,
  -105,  -105,   -65,  -105,  -105,   -73,  -105,  -105,  -105,  -105,
   -78,   -80,   -82,  -105,  -105,  -105,  -105,   -51,   -53,   -74,
  -105,   -44,   -94,   -97,   -98,  -105,   -92,   -93,   -39,   -50,
   -89,   -41,  -105,  -105,   -43 ]

racc_goto_table = [
    68,    94,    82,    95,    97,    63,    62,    63,    81,    83,
    85,    86,   116,     8,    91,     7,    63,    88,    98,   122,
     6,   104,    58,    59,    37,    38,    91,    36,    36,     1,
    23,    22,   101,    33,   132,   109,   110,    29,   112,     9,
   140,    91,    44,     5,   125,     4,     3,     2,    53,    40,
   131,   nil,    60,   127,   nil,   nil,   124,   nil,   nil,   130,
    63,   126,   139,    91,   nil,   142,   156,   nil,   nil,   153,
   154,   nil,   nil,   nil,   nil,   nil,    91,   141,    91,   nil,
   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   151,   147,
   nil,   nil,   nil,    63,   150,   nil,   152,   nil,   nil,   158,
   nil,   nil,   nil,   124,   157,   162,   159,   nil,   nil,   161,
   nil,   nil,   nil,   nil,   nil,   nil,   nil,   164 ]

racc_goto_check = [
    30,    39,    30,    29,    29,    32,    28,    32,    28,    19,
    19,    19,    48,    23,    36,    22,    32,    28,    36,    45,
    21,    31,    43,    43,    44,    44,    36,    34,    34,     1,
    27,    25,    33,    17,    35,    36,    36,    15,    38,    12,
    41,    36,    21,     5,    29,     4,     3,     2,    22,    50,
    39,   nil,    23,    31,   nil,   nil,    32,   nil,   nil,    30,
    32,    28,    29,    36,   nil,    39,    45,   nil,   nil,    48,
    48,   nil,   nil,   nil,   nil,   nil,    36,    36,    36,   nil,
   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,    30,    19,
   nil,   nil,   nil,    32,    28,   nil,    19,   nil,   nil,    30,
   nil,   nil,   nil,    32,    19,    29,    19,   nil,   nil,    30,
   nil,   nil,   nil,   nil,   nil,   nil,   nil,    30 ]

racc_goto_pointer = [
   nil,    29,    47,    46,    45,    43,   nil,   nil,   nil,   nil,
   nil,   nil,    39,   nil,   nil,    26,   nil,    21,   nil,   -40,
   nil,    20,    15,    13,   nil,    20,   nil,    19,   -39,   -55,
   -46,   -49,   -40,   -35,    14,   -73,   -43,   nil,   -42,   -56,
   nil,   -79,   nil,   -15,    11,   -77,   nil,   nil,   -68,   nil,
    33 ]

racc_goto_default = [
   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,   nil,   nil,   nil,   111,   115,   nil,   nil,    70,
   nil,   nil,   nil,   nil,    11,   nil,    12,   nil,   nil,   nil,
   nil,   nil,    74,    66,    71,    72,    73,    76,   nil,   103,
    93,    89,    90,   nil,   nil,   nil,   123,   114,   nil,    15,
   nil ]

racc_reduce_table = [
  0, 0, :racc_error,
  1, 47, :_reduce_1,
  1, 47, :_reduce_2,
  1, 47, :_reduce_3,
  1, 47, :_reduce_4,
  3, 52, :_reduce_5,
  0, 53, :_reduce_6,
  2, 53, :_reduce_7,
  2, 55, :_reduce_8,
  0, 54, :_reduce_9,
  2, 54, :_reduce_10,
  3, 56, :_reduce_11,
  4, 56, :_reduce_12,
  4, 56, :_reduce_13,
  0, 57, :_reduce_14,
  2, 57, :_reduce_15,
  1, 60, :_reduce_16,
  3, 59, :_reduce_17,
  1, 59, :_reduce_18,
  1, 59, :_reduce_19,
  1, 59, :_reduce_20,
  1, 59, :_reduce_21,
  3, 63, :_reduce_22,
  3, 63, :_reduce_23,
  3, 63, :_reduce_24,
  2, 66, :_reduce_25,
  2, 48, :_reduce_26,
  2, 49, :_reduce_27,
  2, 50, :_reduce_28,
  2, 51, :_reduce_29,
  1, 70, :_reduce_30,
  0, 70, :_reduce_31,
  2, 67, :_reduce_32,
  3, 67, :_reduce_33,
  1, 72, :_reduce_34,
  0, 72, :_reduce_35,
  2, 68, :_reduce_36,
  3, 68, :_reduce_37,
  3, 64, :_reduce_38,
  7, 71, :_reduce_39,
  3, 71, :_reduce_40,
  7, 71, :_reduce_41,
  3, 71, :_reduce_42,
  7, 62, :_reduce_43,
  3, 62, :_reduce_44,
  1, 61, :_reduce_45,
  1, 61, :_reduce_46,
  1, 61, :_reduce_47,
  1, 61, :_reduce_48,
  1, 73, :_reduce_49,
  5, 76, :_reduce_50,
  4, 76, :_reduce_51,
  0, 77, :_reduce_52,
  3, 77, :_reduce_53,
  1, 74, :_reduce_54,
  3, 74, :_reduce_55,
  1, 79, :_reduce_56,
  1, 79, :_reduce_57,
  1, 78, :_reduce_58,
  2, 78, :_reduce_59,
  1, 80, :_reduce_60,
  2, 80, :_reduce_61,
  3, 80, :_reduce_62,
  1, 65, :_reduce_63,
  1, 81, :_reduce_64,
  3, 81, :_reduce_65,
  1, 82, :_reduce_66,
  1, 82, :_reduce_67,
  1, 82, :_reduce_68,
  1, 82, :_reduce_69,
  2, 82, :_reduce_70,
  2, 82, :_reduce_71,
  2, 82, :_reduce_72,
  3, 82, :_reduce_73,
  4, 82, :_reduce_74,
  3, 83, :_reduce_75,
  1, 86, :_reduce_76,
  1, 87, :_reduce_77,
  3, 87, :_reduce_78,
  1, 88, :_reduce_79,
  3, 88, :_reduce_80,
  1, 85, :_reduce_81,
  3, 85, :_reduce_82,
  0, 89, :_reduce_83,
  2, 89, :_reduce_84,
  4, 90, :_reduce_85,
  1, 90, :_reduce_86,
  4, 58, :_reduce_87,
  4, 58, :_reduce_88,
  0, 75, :_reduce_89,
  2, 75, :_reduce_90,
  1, 91, :_reduce_91,
  3, 91, :_reduce_92,
  3, 92, :_reduce_93,
  3, 93, :_reduce_94,
  1, 94, :_reduce_95,
  1, 94, :_reduce_96,
  3, 94, :_reduce_97,
  3, 94, :_reduce_98,
  0, 84, :_reduce_99,
  1, 84, :_reduce_100,
  1, 69, :_reduce_101,
  3, 69, :_reduce_102,
  4, 95, :_reduce_103,
  1, 96, :_reduce_104 ]

racc_reduce_n = 105

racc_shift_n = 165

racc_token_table = {
  false => 0,
  :error => 1,
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
  :T_SCOPED_ID => 45 }

racc_nt_base = 46

racc_use_result_var = true

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
  "$end",
  "error",
  "T_COMMA",
  "T_RARROW",
  "K_OR",
  "T_EOF",
  "K_CLASS",
  "K_METACLASS",
  "K_MODULE",
  "K_INTERFACE",
  "K_TYPE",
  "K_TYPEVAR",
  "K_ALIAS",
  "K_REQUIRE",
  "K_END",
  "K_SELF",
  "T_BEGIN_LINE",
  "T_SEMICOLON",
  "T_COLON",
  "T_DOUBLE_COLON",
  "T_DOT",
  "T_STAR",
  "T_QUESTION",
  "T_CARROT",
  "T_BANG",
  "T_EQUAL",
  "T_LPAREN",
  "T_RPAREN",
  "T_LESS",
  "T_GREATER",
  "T_LBRACKET",
  "T_RBRACKET",
  "T_LBRACE",
  "T_RBRACE",
  "T_SUBTYPE",
  "T_STRING",
  "T_IVAR",
  "T_CVAR",
  "T_GVAR",
  "T_CONST_ID",
  "T_TYPE_ID",
  "T_SYMBOL",
  "T_LOCAL_ID",
  "T_TICKED_ID",
  "T_SUFFIXED_ID",
  "T_SCOPED_ID",
  "$start",
  "entry",
  "e_method",
  "e_field",
  "e_named",
  "e_class",
  "interface_file",
  "require_list",
  "class_def_list",
  "require_stmt",
  "class_def",
  "class_elem_list",
  "class_annotation",
  "class_elem",
  "alias_name",
  "relative_method_name",
  "method_type",
  "field_sig",
  "const_expr",
  "type_expr",
  "e_expr",
  "method_annotation_list",
  "field_annotation_list",
  "named_type_list",
  "method_start",
  "const_method_type",
  "field_start",
  "method_name",
  "type_id_list",
  "constraint_list",
  "method_sig",
  "block",
  "type_var",
  "simple_type_var",
  "type_ident",
  "or_type_list",
  "single_type_expr",
  "tuple",
  "field_or_method_list",
  "type_expr_comma_list",
  "named_type_expr",
  "named_or_type_list",
  "single_named_type_expr",
  "declared_subtypes",
  "class_decl",
  "bounded_quantifier_list",
  "bounded_quantifier",
  "field_type",
  "field_or_method_nonempty_list",
  "named_type",
  "type_name" ]

Racc_debug_parser = false

##### State transition tables end #####

# reduce 0 omitted

module_eval(<<'.,.,', 'annot_parser.racc', 47)
  def _reduce_1(val, _values, result)
     result = val[0] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 48)
  def _reduce_2(val, _values, result)
     result = val[0] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 49)
  def _reduce_3(val, _values, result)
     result = val[0] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 50)
  def _reduce_4(val, _values, result)
     result = val[0] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 56)
  def _reduce_5(val, _values, result)
            fatal("Interface parsing not yet implemented")
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 60)
  def _reduce_6(val, _values, result)
     [] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 61)
  def _reduce_7(val, _values, result)
     result = [val[0]] + val[1] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 64)
  def _reduce_8(val, _values, result)
     result = strip_quotes(token_text(val[1])) 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 67)
  def _reduce_9(val, _values, result)
     [] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 68)
  def _reduce_10(val, _values, result)
     result = [val[0]] + val[1] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 72)
  def _reduce_11(val, _values, result)
            fatal("Metaclass type annotations not yet supported")
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 75)
  def _reduce_12(val, _values, result)
            fatal("Class type annotations not yet supported")
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 78)
  def _reduce_13(val, _values, result)
            fatal("Module type annotations not yet supported")
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 82)
  def _reduce_14(val, _values, result)
     result = [] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 83)
  def _reduce_15(val, _values, result)
     result = [val[0]] + val[1] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 86)
  def _reduce_16(val, _values, result)
     result = token_text(val[0]) 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 89)
  def _reduce_17(val, _values, result)
     fatal("Alias not yet implemented") 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 90)
  def _reduce_18(val, _values, result)
     result = val[0] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 91)
  def _reduce_19(val, _values, result)
     result = val[0] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 92)
  def _reduce_20(val, _values, result)
     result = val[0] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 93)
  def _reduce_21(val, _values, result)
     result = val[0] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 97)
  def _reduce_22(val, _values, result)
            result = handle_var(:ivar, token_text(val[0]), val[2]) 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 99)
  def _reduce_23(val, _values, result)
            result = handle_var(:cvar, token_text(val[0]), val[2]) 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 101)
  def _reduce_24(val, _values, result)
            result = handle_var(:gvar, token_text(val[0]), val[2]) 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 105)
  def _reduce_25(val, _values, result)
     fatal("Expr parsing not yet implemented") 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 111)
  def _reduce_26(val, _values, result)
     result = val[0] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 114)
  def _reduce_27(val, _values, result)
     result = val[0] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 117)
  def _reduce_28(val, _values, result)
     result = val[0] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 120)
  def _reduce_29(val, _values, result)
     result = val[0] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 123)
  def _reduce_30(val, _values, result)
     result = nil 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 124)
  def _reduce_31(val, _values, result)
     result = nil 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 127)
  def _reduce_32(val, _values, result)
     result = [val[1]] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 129)
  def _reduce_33(val, _values, result)
            result = [val[1]] + val[2]
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 133)
  def _reduce_34(val, _values, result)
     result = nil 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 134)
  def _reduce_35(val, _values, result)
     result = nil 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 137)
  def _reduce_36(val, _values, result)
     result = [val[1]] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 138)
  def _reduce_37(val, _values, result)
     result = [val[1]] + val[2] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 144)
  def _reduce_38(val, _values, result)
            result = handle_constant(token_text(val[0]).to_sym, val[2])
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 149)
  def _reduce_39(val, _values, result)
     result = handle_mtype(val[0], val[2], val[4], val[6]) 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 151)
  def _reduce_40(val, _values, result)
     result = handle_mtype(val[0], nil, nil, val[2]); 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 153)
  def _reduce_41(val, _values, result)
     result = handle_mtype(token_text(val[0]).to_sym,
                              val[2], val[4], val[6]) 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 157)
  def _reduce_42(val, _values, result)
            result = handle_mtype(token_text(val[0]).to_sym, nil, nil, val[2]) 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 161)
  def _reduce_43(val, _values, result)
     result = handle_mtype(val[0], val[2], val[4], val[6]) 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 163)
  def _reduce_44(val, _values, result)
     result = handle_mtype(val[0], nil, nil, val[2]) 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 167)
  def _reduce_45(val, _values, result)
     result = MethodIdentifier.new(proxy, token_text(val[0])) 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 169)
  def _reduce_46(val, _values, result)
     result = MethodIdentifier.new(proxy, token_text(val[0])) 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 171)
  def _reduce_47(val, _values, result)
     result = MethodIdentifier.new(proxy, token_text(val[0])) 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 174)
  def _reduce_48(val, _values, result)
            result = handle_scoped_id(token_text(val[0])) 
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 178)
  def _reduce_49(val, _values, result)
     result = val[0] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 186)
  def _reduce_50(val, _values, result)
            result = construct_msig([], val[2], val[4])
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 189)
  def _reduce_51(val, _values, result)
            result = construct_msig(val[0], val[1], val[3])
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 193)
  def _reduce_52(val, _values, result)
     result = nil 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 194)
  def _reduce_53(val, _values, result)
     result = handle_btype(val[1]) 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 197)
  def _reduce_54(val, _values, result)
     result = [val[0]] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 198)
  def _reduce_55(val, _values, result)
     result = [val[0]] + val[2] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 201)
  def _reduce_56(val, _values, result)
     result = handle_type_param(:id, token_text(val[0])) 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 203)
  def _reduce_57(val, _values, result)
     result = handle_type_param(:self, token_text(val[0])) 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 207)
  def _reduce_58(val, _values, result)
     result = val[0] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 209)
  def _reduce_59(val, _values, result)
            result = handle_type_param(:varargs, token_text(val[1])) 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 214)
  def _reduce_60(val, _values, result)
     token_text(val[0]) 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 216)
  def _reduce_61(val, _values, result)
            result = token_text(val[1])
# token_text(val[0]) + token_text(val[1]) 
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 220)
  def _reduce_62(val, _values, result)
            result =
          if val[0].class == Array 
            val[0] << token_text(val[2]) 
          else 
            [val[0], token_text(val[2])]
          end 
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 230)
  def _reduce_63(val, _values, result)
            list = val[0][:or_list]
        if(list.length > 1)
          # args = list + [pos]
          result = # proxy.utype(*args)
                   Rtc::Types::UnionType.new(list)
        else
          # flatten if there is no union
          result = list[0]
        end
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 242)
  def _reduce_64(val, _values, result)
     result = {:or_list => [val[0]]} 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 244)
  def _reduce_65(val, _values, result)
            # need to differientiate OR lists from tuples (which are just arrays)
        val[2][:or_list] = [val[0]] + val[2][:or_list]
        result = val[2]
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 250)
  def _reduce_66(val, _values, result)
     result = val[0] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 252)
  def _reduce_67(val, _values, result)
        	result = Rtc::Types::SymbolType.new(eval(val[0]))
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 255)
  def _reduce_68(val, _values, result)
            id = handle_type_ident(val[0])
        if(id.class == Class)
          result = Rtc::Types::NominalType.of(id)
        else
          result = id
        end
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 262)
  def _reduce_69(val, _values, result)
     result = val[0] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 264)
  def _reduce_70(val, _values, result)
            result = Rtc::Types::TopType.instance
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 267)
  def _reduce_71(val, _values, result)
            result = Rtc::Types::OptionalArg.new(val[1])
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 270)
  def _reduce_72(val, _values, result)
            result = Rtc::Types::Vararg.new(val[1])
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 273)
  def _reduce_73(val, _values, result)
            result = handle_structural_type(val[1])
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 276)
  def _reduce_74(val, _values, result)
            id = handle_type_ident(val[0])
        nominal = Rtc::Types::NominalType.of(id)
        result = Rtc::Types::ParameterizedType.new(nominal, val[2])
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 282)
  def _reduce_75(val, _values, result)
     result = val[1] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 287)
  def _reduce_76(val, _values, result)
            list = val[0][:or_list]
        if(list.length > 1)
          result = Rtc::Types::UnionType.new(list)
        else
          result = list[0]
        end
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 296)
  def _reduce_77(val, _values, result)
     result = {:or_list => [val[0]]} 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 298)
  def _reduce_78(val, _values, result)
            val[2][:or_list] = [val[0]] + val[2][:or_list]
        result = val[2]
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 303)
  def _reduce_79(val, _values, result)
     result = val[0] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 305)
  def _reduce_80(val, _values, result)
            result = {:name => token_text(val[0]),
                  :type => val[2]}
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 310)
  def _reduce_81(val, _values, result)
     result = [val[0]] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 312)
  def _reduce_82(val, _values, result)
            result = [val[0]] + val[2] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 315)
  def _reduce_83(val, _values, result)
     result = [] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 316)
  def _reduce_84(val, _values, result)
     result = val[1] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 320)
  def _reduce_85(val, _values, result)
            id = val[0].to_sym
        type_vars = prepare_type_vars_for_sig(val[2])
        result = handle_class_decl(id, type_vars)
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 325)
  def _reduce_86(val, _values, result)
            id = val[0].to_sym
        result = handle_class_decl(id)
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 331)
  def _reduce_87(val, _values, result)
            result = handle_class_annot(val[1], val[2], val[3], true)
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 334)
  def _reduce_88(val, _values, result)
            result = handle_class_annot(val[1], val[2], val[3], false)
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 338)
  def _reduce_89(val, _values, result)
     [] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 339)
  def _reduce_90(val, _values, result)
     result = val[1] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 342)
  def _reduce_91(val, _values, result)
     result = [val[0]] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 344)
  def _reduce_92(val, _values, result)
            result = [val[0]] + val[2]
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 348)
  def _reduce_93(val, _values, result)
            result = TypeConstraint.new(pos, val[0], val[2])
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 353)
  def _reduce_94(val, _values, result)
            result = handle_var(:ivar, token_text(val[0]), val[2])
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 358)
  def _reduce_95(val, _values, result)
            result = {:fields => [val[0]], :methods => []}       
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 360)
  def _reduce_96(val, _values, result)
            result = {:fields => [],       :methods => [val[0]]} 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 362)
  def _reduce_97(val, _values, result)
            field_method_hash = val[2]
        field_method_hash[:fields] += [val[0]]
        result = field_method_hash
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 367)
  def _reduce_98(val, _values, result)
            field_method_hash = val[2]
        field_method_hash[:methods] += [val[0]]
        result = field_method_hash
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 373)
  def _reduce_99(val, _values, result)
     result = {:fields => [], :methods => []} 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 374)
  def _reduce_100(val, _values, result)
     result = val[0] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 377)
  def _reduce_101(val, _values, result)
     result = [val[0]] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 378)
  def _reduce_102(val, _values, result)
     result = [val[0]] + val[2] 
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 382)
  def _reduce_103(val, _values, result)
            result = handle_named_type_expr(val[1], val[3])
      
    result
  end
.,.,

module_eval(<<'.,.,', 'annot_parser.racc', 386)
  def _reduce_104(val, _values, result)
     token_text(val[0]) 
    result
  end
.,.,

def _reduce_none(val, _values, result)
  val[0]
end

end   # class TypeAnnotationParser


end