require 'rtc/runtime/native'
require 'rtc/runtime/master_switch.rb'
require 'rtc/options'

module Rtc
  
  class TypeMismatchException < StandardError; end

  class AnnotateException < StandardError; end

  class CastException < StandardError; end

  class AmbiguousUnionException < StandardError; end

  class NoMethodException < StandardError; end

  class MethodWrapper
    @call_template = <<METHOD_TEMPLATE
    alias %{mangled_name} %{method_name}
    def %{method_name}(*regular_args, &blk)
      if Rtc::MasterSwitch.is_on?
        Rtc::MasterSwitch.turn_off
        %{invokee_fetch}
        if not new_invokee
          Rtc::MasterSwitch.turn_on
          if blk
            return %{mangled_name}(*regular_args, &blk)
          else
            return %{mangled_name}(*regular_args, &blk)
          end
        end
        begin
          $CHECK_COUNT+=1
          #puts "%{method_name}"
          #flag = false
          #debug = "%{method_name}" == "zip"
          method_type = new_invokee.rtc_type.get_method("%{method_name}".to_s)
          if method_type.is_a?(Rtc::Types::ProceduralType)
            method_types = NativeArray[method_type]
          else
            method_types = NativeArray.new(method_type.types.to_a)
          end
          #regulars_args = Rtc::NativeArray.new(regular_args)
          #puts "DEBUG: about to select arguments" if debug
          chosen_type, annotated_args, unsolved_tvars = Rtc::MethodCheck.select_and_check_args(method_types, "%{method_name}", regular_args,  (not blk.nil?), self.class)
          
          unwrap_arg_pos = chosen_type.unwrap
          mutate = chosen_type.mutate

          # if debug
          #   puts "PROXY DEBUG:"
          #   annotated_args.each {
          #     |a|
          #     puts a.is_proxy_object?
          #   }
          # end

          #puts "DEBUG: about to call native" if debug

          if blk
            block_proxy = Rtc::BlockProxy.new(blk, chosen_type.block_type, "%{method_name}",
                                         self, unsolved_tvars)
            wrapped_block = Rtc::MethodWrapper.wrap_block(block_proxy)
            Rtc::MasterSwitch.turn_on
            ret_value = %{mangled_name}(*annotated_args, &wrapped_block)
            Rtc::MasterSwitch.turn_off
          else
            Rtc::MasterSwitch.turn_on
            ret_value = %{mangled_name}(*annotated_args)
            Rtc::MasterSwitch.turn_off
          end
          
          unsolved_tvars.each {
            |t|
            t.to_actual_type
          }
          
          unless Rtc::MethodCheck.check_return(chosen_type, ret_value, unsolved_tvars)
            p ret_value.rtc_type, chosen_type.return_type, "%{method_name}", self, chosen_type
            
            raise Rtc::TypeMismatchException, "invalid return type in %{method_name}"
          end
          #puts "DEBUG: got out of return checking" if debug
          if ret_value === false || ret_value === nil ||
              ret_value.is_a?(Rtc::Types::Type) || unwrap_arg_pos.include?(-1)
            ret_proxy = ret_value
          else
            ret_proxy = ret_value.rtc_annotate(chosen_type.return_type.to_actual_type)
          end
          #flag = true
          #puts "leaving wrapper for %{method_name}"
          return ret_proxy
        ensure
          #puts "leaving wrapper for  %{method_name} due to exception" if not flag
          Rtc::MasterSwitch.turn_on
        end
      else
        if blk
          %{mangled_name}(*regular_args, &blk)
        else
          %{mangled_name}(*regular_args)
        end
      end
    end
METHOD_TEMPLATE
    @mangled = {
      "+" => "__rtc_rtc_op_plus",
      "[]=" => "__rtc_rtc_op_elem_set",
      "[]" => "__rtc_rtc_op_elem_get",
      "**" => "__rtc_rtc_op_exp",
      "!" => "__rtc_rtc_op_not",
      "!" => "__rtc_rtc_op_complement",
      "+@" => "__rtc_rtc_op_un_plus",
      "-@" => "__rtc_rtc_op_un_minus",
      "*" => "__rtc_rtc_op_mult",
      "/" => "__rtc_rtc_op_div",
      "%" => "__rtc_rtc_op_mod",
      "+" => "__rtc_rtc_op_plus",
      "-" => "__rtc_rtc_op_minus",
      ("<" + "<") => "__rtc_rtc_op_ls",
      ">>"=> "__rtc_rtc_op_rs",
      "^" => "__rtc_rtc_op_bitxor",
      "|" => "__rtc_rtc_op_bitor",
      "<=" => "__rtc_rtc_op_lte",
      "<" => "__rtc_rtc_op_lt",
      ">" => "__rtc_rtc_op_gt",
      ">=" => "__rtc_rtc_op_gte",
      "<=>" => "__rtc_rtc_op_3comp",
      "==" => "__rtc_rtc_op_eq",
      "===" => "__rtc_rtc_op_strict_eq",
      '&' => "__rtc_rtc_op_bitand",
    }
    def self.mangle_name(method_name)
      if @mangled.has_key?(method_name.to_s)
        @mangled[method_name.to_s]
      elsif method_name.to_s =~ /^(.+)=$/
        "__rtc_rtc_set_" + $1
      else
        "__rtc_" + method_name.to_s
      end
    end
    
    def self.make_wrapper(class_obj, method_name, is_class = false)
      return nil if Rtc::Disabled
      mangled_name = self.mangle_name(method_name)
      if is_class
        invokee_fetch = "new_invokee = self"
      else
        invokee_fetch = "new_invokee = self.rtc_get_proxy"
      end
      class_obj.module_eval(@call_template % { :method_name => method_name.to_s,
                              :mangled_name => mangled_name,
                              :invokee_fetch => invokee_fetch
                            }, "method_wrapper.rb", 17)
      return true
    end

    def self.wrap_block(x)
      Proc.new {|*v| x.call(*v)}
    end

    private
    
    def on_error(message)
      case Rtc::Options[:on_type_error]
      when :ignore
        ;
      when :exception
        raise TypeMismatchException,message
      when :file
        Rtc::Options[:type_error_config].write(message)
      when :callback
        Rtc::Options[:type_error_config].call(message)
      when :exit
        exit -1
      end
    end
    
    def initialize(class_obj,method_name)
      raise "We should never be here"
    end
  end

  class BlockProxy
    attr_reader :proc
    attr_accessor :block_type
    attr_reader :method_type
    attr_reader :method_name
    attr_reader :class_obj

    def initialize(proc, type, method_name, class_obj,
        unsolved_tvars)
      @proc = proc
      @block_type = type
      @method_name = method_name
      @class_obj = class_obj
      @unsolved_type_variables = unsolved_tvars
    end

    def call(*args)
      $CHECK_COUNT+=1
      args = Rtc::NativeArray.new(args)
      Rtc::MasterSwitch.turn_off
      check_result = Rtc::MethodCheck.check_args(@block_type, args,
                              @unsolved_type_variables)
      if not check_result
        raise Rtc::TypeMismatchException "Block arg failed!"
      end
      annotated_args, @unsolved_type_variables = check_result
      Rtc::MasterSwitch.turn_on
      ret = @proc.call(*annotated_args)
      Rtc::MasterSwitch.turn_off
      return_valid = Rtc::MethodCheck.check_return(@block_type, ret, @unsolved_type_variables)
      raise Rtc::TypeMismatchException, "Block return type mismatch" unless return_valid
      begin
        if ret === false or ret === nil or ret.is_a?(Rtc::Types::Type)
          ret
        else
          ret.rtc_annotate(block_type.return_type.to_actual_type)
        end
      ensure
        Rtc::MasterSwitch.turn_on
      end
    end
    
  end
end
