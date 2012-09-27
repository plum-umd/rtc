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
    alias __rtc_%{method_name} %{method_name}
    def %{method_name}(*regular_args, &blk)
      if status = Rtc::MasterSwitch.is_on? and 
          new_invokee = self.rtc_get_proxy
        Rtc::MasterSwitch.turn_off
        begin
          method_type = new_invokee.rtc_type.get_method("%{method_name}".to_s)
          
          if method_type.is_a?(Rtc::Types::ProceduralType)
            method_types = [method_type]
          else
            method_types = method_type.types.to_a
          end
          
          chosen_type, annotated_args, unsolved_tvars = Rtc::MethodCheck.check_args(method_types, "%{method_name}", regular_args,  (not blk.nil?), self.class)
          
          unwrap_arg_pos = chosen_type.unwrap
          mutate = chosen_type.mutate

          for i in unwrap_arg_pos
            annotated_args[i] = (annotated_args[i].is_proxy_object?) ? annotated_args[i].object : annotated_args[i]
          end

          if blk
            block_proxy = Rtc::BlockProxy.new(blk, chosen_type.block_type, "%{method_name}",
                                         self, unsolved_tvars)
            wrapped_block = Rtc::MethodWrapper.wrap_block(block_proxy)
            Rtc::MasterSwitch.turn_on
            ret_value = __rtc_%{method_name}(*regular_args, &wrapped_block)
            Rtc::MasterSwitch.turn_off
          else
            Rtc::MasterSwitch.turn_on
            ret_value = __rtc_%{method_name}(*regular_args)
            Rtc::MasterSwitch.turn_off
          end
          
          unless Rtc::MethodCheck.check_return(ret_value, chosen_type.return_type)
            p ret_value.rtc_type, chosen_type.return_type, "%{method_name}", self, chosen_type
            
            raise Rtc::TypeMismatchException, "invalid return type in %{method_name}"
          end
          
          if ret_value === false || ret_value === nil ||
              ret_value.is_a?(Rtc::Types::Type)
            ret_proxy = ret_value
          else
            ret_proxy = ret_value.rtc_annotate(chosen_type.return_type.to_actual_type)
          end
          
          return ret_proxy
        ensure
          Rtc::MasterSwitch.turn_on
        end
        
      else
        if blk
          __rtc_%{method_name}(*regular_args, &blk)
        else
          __rtc_%{method_name}(*regular_args)
        end
      end
    end
METHOD_TEMPLATE
    def self.make_wrapper(class_obj, method_name)
      return nil if Rtc::Disabled
      #      MethodWrapper.new(class_obj, method_name)
      if method_name =~ /[-+!\/*%|&]|<<|>>|\[\]/
        MethodWrapper.new(class_obj, method_name)
      else
        #puts @call_template % { :method_name => method_name.to_s }
        class_obj.module_eval(@call_template % { :method_name => method_name.to_s },
                              "method_wrapper.rb", 17)
        return true
      end
    end

    def self.wrap_block(x)
      Proc.new {|v| x.call(v)}
    end

    def invoke(invokee, arg_vector)
      regular_args = arg_vector[:args]
      blk = arg_vector[:block]
      from_proxy = false

      last_arg = regular_args[-1]
      if last_arg.is_a?(Hash) and last_arg['__rtc_special']
        regular_args.pop
        new_invokee = last_arg['self_proxy']
        from_proxy = true
      elsif invokee.rtc_get_proxy
        new_invokee = invokee.rtc_get_proxy
      else
        # no type context, do not type check
        if blk
          Rtc::MasterSwitch::turn_on
          to_ret = @original_method.bind(invokee).call(*regular_args, &blk)
          Rtc::MasterSwitch::turn_off
        else
          Rtc::MasterSwitch::turn_on
          to_ret = @original_method.bind(invokee).call(*regular_args)
          Rtc::MasterSwitch::turn_off
        end
        return to_ret
      end

      method_type = new_invokee.rtc_type.get_method(@method_name.to_s)

      if method_type.is_a?(Rtc::Types::ProceduralType)
        method_types = [method_type]
      else
        method_types = method_type.types.to_a
      end

      chosen_type = Rtc::MethodCheck.check_args(method_types, @method_name, regular_args,  (not blk.nil?), @class_obj)
      
      unwrap_arg_pos = chosen_type.unwrap
      mutate = chosen_type.mutate
      unsolved_type_variables = []
      
      chosen_type.type_variables.each {
        |tvar|
        if tvar.solvable?
          tvar.solve
        else
          unsolved_type_variables << tvar
        end
      }
      

      i = 0
      chosen_type.arg_types.each { |arg_type|
        #TODO(jtoman): detect this error at the parser level
        #if arg_type.has_parameterized
        #  raise Rtc::TypeMismatchException, "Unbound parameter in method #{invokee.class}##{@method_name}"
        #end
        
        if arg_type.instance_of?(Rtc::Types::ProceduralType)
          regular_args[i] = BlockProxy.new(regular_args[i], arg_type, @method_name, invokee,
            unsolved_type_variables)
        else
          if unwrap_arg_pos.include?(i)
            if regular_args[i].is_proxy_object?
              regular_args[i] = regular_args[i].object
            end
          else
            regular_args[i] = regular_args[i].rtc_annotate(arg_type.to_actual_type)
          end
        end
        
        i += 1
      }

      if blk
        block_proxy = BlockProxy.new(blk, chosen_type.block_type,@method_name,
          invokee, unsolved_type_variables)
        wrapped_block = wrap_block(block_proxy)
        Rtc::MasterSwitch.turn_on
        ret_value = @original_method.bind(invokee).call(*regular_args, &wrapped_block)
        Rtc::MasterSwitch.turn_off
      else
        Rtc::MasterSwitch.turn_on
        ret_value = @original_method.bind(invokee).call(*regular_args)
        Rtc::MasterSwitch.turn_off
      end
      
      trailing_tvar = nil
      
      unsolved_type_variables.each {
        |tvar|
        if tvar.solvable? 
          tvar.solve
        # this type variable was solved in a block
        elsif tvar.instantiated
          next
        else
          raise "Invalid tsig" unless trailing_tvar.nil?
          trailing_tvar = tvar
        end
      }


      unless Rtc::MethodCheck.check_type(ret_value, chosen_type.return_type)
        p ret_value.rtc_type, chosen_type.return_type, @method_name, invokee, chosen_type
        
        raise TypeMismatchException, "invalid return type in " + @method_name.to_s
      end
      
      trailing_var.instantiate unless trailing_tvar.nil?
      if ret_value === false || ret_value === nil ||
          ret_value.is_a?(Rtc::Types::Type)
        ret_proxy = ret_value
      else
        ret_proxy = ret_value.rtc_annotate(chosen_type.return_type.to_actual_type)
      end

      return ret_proxy
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
      @method_name = method_name
      @class_obj = class_obj

      class_obj = @class_obj

      this_obj = self
      original_method = @original_method = class_obj.instance_method(method_name)
      wrapper_lambda = lambda {
        |*__rtc_args, &__rtc_block|
        if Rtc::MasterSwitch.is_on?
          Rtc::MasterSwitch.turn_off 
          args = {:args => __rtc_args, :block => __rtc_block }

          begin
            this_obj.invoke(self, args)
          ensure
            Rtc::MasterSwitch.turn_on
          end
        else
          if __rtc_block.nil?
            return original_method.bind(self).call(*__rtc_args)
          else
            return original_method.bind(self).call(*__rtc_args, &__rtc_block)
          end
        end
      }

      class_obj.send(:define_method, method_name, wrapper_lambda)
    end
  end

  class BlockProxy < MethodWrapper
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
      Rtc::MasterSwitch.turn_off
      
      #TODO(jtoman): arg number check 
      check_result = Rtc::MethodCheck.check_args(@block_type, args,
                              @unsolved_type_variables)
      if not annotated_args
        raise Rtc::TypeMismatchException "Block arg failed!"
      end
      annotated_args, @unsolved_type_variables = annotated_args

      Rtc::MasterSwitch.turn_on
      ret = @proc.call(*annotated_args)
      Rtc::MasterSwitch.turn_off

      return_valid = Rtc::MethodCheck.check_return(@block_type, ret, @unsolved_type_variables)

      raise Rtc::TypeMismatchException, "Block return type mismatch" unless return_valid
      if ret === false or ret === nil or ret.is_a?(Rtc::Types::Type)
        ret
      else
        ret.rtc_annotate(block_type.return_type.to_actual_type)
      end
    end
    
  end
end
