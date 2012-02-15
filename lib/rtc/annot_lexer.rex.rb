# ######################################################################
# ######################################################################
# VERY IMPORTANT:
# DO NOT RE-RUN REX!!!!
# The generated lexer contains some important manual modifications
# that will be destroyed if it is regenerated
# ######################################################################
# ######################################################################

require 'racc/parser'
# ######################################################################
# DRuby annotation language parser
# Adapted directly from DRuby source file typeAnnotationLexer.mll
# Version of GitHub DRuby repo commit 0cda0264851bcdf6b301c3d7f564e9a3ee220e45
# ######################################################################

require 'rtc/position'

module Rtc

class TypeAnnotationParser < Racc::Parser
  require 'strscan'

  class ScanError < StandardError ; end

  attr_reader   :lineno
  attr_reader   :filename
  attr_accessor :state, :pos, :ctx

  def scan_setup(str)
    @ss = StringScanner.new(str)
    @lineno =  1
    @state  = nil
  end

  def action(&block)
    yield
  end

  def load_file( filename )
    @filename = filename
    open(filename, "r") do |f|
      scan_setup(f.read)
    end
  end

  def scan_file( filename )
    load_file(filename)
    do_parse
  end

  def set_pos_ctx(this_pos, this_ctx)
    @pos = this_pos
    @ctx = this_ctx
  end

  def unset_pos_ctx
    @pos = nil
    @ctx = nil
  end

  def scan_str(str)
    scan_setup(str)
    @yydebug = true
    begin
      r = do_parse
    rescue => e
      fail e
    end
    r
  end

  def next_token
    # MANUAL HACK: the rex(ical)-generated lexer returns nil if a
    # token comes back empty, despite the facts that nil tokens are
    # perfectly valid (i.e. for ignored characters/whitespace) and
    # that it does specific error checking for cases when no match can
    # be found.
    #
    # With this fix, when the token is nil we keep consuming text
    # until we find something.  This definitely seems like the correct
    # behavior.
    token = nil
    while(token == nil) # begin big loop

    return if @state == :END

    text = @ss.peek(1)
    @lineno  +=  1  if text == "\n"
    token = case @state
    when nil
      case
      when (text = @ss.scan(/[\t ]+/))
        ;

      when (text = @ss.scan(/\n[\t ]*\=begin/))
         action { state = :COMMENT }

      when (text = @ss.scan(/class /))
         action { [:K_CLASS, text] }

      when (text = @ss.scan(/metaclass /))
         action { [:K_METACLASS, text]}

      when (text = @ss.scan(/module /))
         action { [:K_MODULE, text] }

      when (text = @ss.scan(/alias /))
         action { [:K_ALIAS, text] }

      # when (text = @ss.scan(/require/))
      #   action { [:K_REQUIRE, text] }

      when (text = @ss.scan(/end /))
         action { [:K_END, text] }

      when (text = @ss.scan(/type /))
         action { [:K_TYPE, text] }

      when (text = @ss.scan(/typevar /))
         action { [:K_TYPEVAR, text] }

      when (text = @ss.scan(/\*/))
         action { [:T_STAR, text] }

      when (text = @ss.scan(/\^/))
         action { [:T_CARROT, text] }

      when (text = @ss.scan(/\@FIXME/))
         action {fail "ERROR at line #{lineno}: " +
                                        "deprecated @@FIXME in '#{text}', " +
                                        "use !FIXME"}

      when (text = @ss.scan(/'[^']*'/))
         action { [:T_STRING, text.gsub("'", "")] }

      when (text = @ss.scan(/\<\=/))
         action { [:T_SUBTYPE, text] }

      when (text = @ss.scan(/@[A-Za-z_]+\w*/))
         action { [:T_IVAR, text] }

      when (text = @ss.scan(/@@[A-Za-z_]+\w*/))
         action { [:T_CVAR, text] }

      when (text = @ss.scan(/\$[A-Za-z_]+\w*/))
         action { [:T_GVAR, text] }

      when (text = @ss.scan(/\!/))
         action { [:T_BANG, text] }

      when (text = @ss.scan(/\::/))
         action { [:T_DOUBLE_COLON, text] }

      when (text = @ss.scan(/\:/))
         action { [:T_COLON, text] }

      when (text = @ss.scan(/\./))
         action { [:T_DOT, text] }

      when (text = @ss.scan(/->/))
         action { [:T_RARROW, text] }

      when (text = @ss.scan(/\(/))
         action { [:T_LPAREN, text] }

      when (text = @ss.scan(/\)/))
         action { [:T_RPAREN, text] }

      when (text = @ss.scan(/\[/))
         action { [:T_LBRACKET, text] }

      when (text = @ss.scan(/\]/))
         action { [:T_RBRACKET, text] }

      when (text = @ss.scan(/,/))
         action { [:T_COMMA, text] }

      when (text = @ss.scan(/\{/))
         action { [:T_LBRACE, text] }

      when (text = @ss.scan(/\}/))
         action { [:T_RBRACE, text] }

      when (text = @ss.scan(/</))
         action { [:T_LESS, text] }

      when (text = @ss.scan(/>/))
         action { [:T_GREATER, text] }

      when (text = @ss.scan(/;/))
         action { [:T_SEMICOLON, text]}

      when (text = @ss.scan(/\n/))
         action { }

      when (text = @ss.scan(/or/))
         action { [:K_OR, text] }

      when (text = @ss.scan(/self/))
         action { [:K_SELF, text] }

      when (text = @ss.scan(/([A-Za-z_]+\w*|self)\.(\w|\[|\]|=)+[\?\!\=]?/))
         action { [:T_SCOPED_ID, text] }

      when (text = @ss.scan(/[A-Za-z_]+\w*[\?\!\=]/))
         action { [:T_SUFFIXED_ID, text] }

      when (text = @ss.scan(/[A-Z]+\w*/))
         action { [:T_CONST_ID, text] }

      when (text = @ss.scan(/[a-z_]+\w*\'*/))
         action { [:T_LOCAL_ID, text] }

      # when (text = @ss.scan(/[a-z_]+\w\'+/))
      #    action { [:T_TICKED_ID, text] }

      # when (text = @ss.scan(/[A-Za-z_]+\w*[?!=]?/))
      #    action { [:T_METHOD_NAME, text] }

      # when (text = @ss.scan(/[a-z_]+\w*\'?/))
      #    action { [:T_TYPE_ID, text] }

      when (text = @ss.scan(/\?/))
         action { [:T_QUESTION, text] }

      when (text = @ss.scan(/\<\=/))
         action { [:T_SUBTYPE, text] }

      when (text = @ss.scan(/=/))
         action { [:T_EQUAL, text]}

      when (text = @ss.eos?)
         action { @state = :END; [:T_EOF, ""] }

      else
        text = @ss.string[@ss.pos .. -1]
        raise  ScanError, "can not match: '" + text + "'"
      end  # if

    when :COMMENT
      case
      when (text = @ss.scan(/[\t ]*\=end[^\n]*\n/))
         action { state = nil }

      when (text = @ss.scan(/[^\n]*\n/))
        ;

      else
        text = @ss.string[@ss.pos .. -1]
        raise  ScanError, "can not match: '" + text + "'"
      end  # if

    else
      raise  ScanError, "undefined state: '" + state.to_s + "'"
    end  # case state

    end # big loop
    token
  end  # def next_token

end # class

end #module
