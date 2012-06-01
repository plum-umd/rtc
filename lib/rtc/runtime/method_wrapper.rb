require 'rtc/runtime/master_switch.rb'
require 'rtc/options'
module Rtc
  
  class TypeMismatchException < StandardError; end
  
  class MethodWrapper
    class NoArgument; end
    def self.make_wrapper(class_obj, method_name)
      if Rtc::Disabled
        return nil
      end
      MethodWrapper.new(class_obj, method_name)
    end

    def check_args(passed_arguments, method_type)
      pl = {}
      poly_check_args = []

      return false unless method_type.min_args <= passed_arguments.size
      return false unless passed_arguments.size <= method_type.max_args or method_type.max_args == -1
      #check the first set of required arguments
      i = 0
      parameter_layout = method_type.parameter_layout

      while i < parameter_layout[:required][0]
        mpl = {}

        b, _ = passed_arguments[i].rtc_type.match_param(method_type.arg_types[i], mpl)

        return false unless b

        mpl.each{|k, v|
          if pl[k]
            pl[k] = v + pl[k]
          else
            pl[k] = v
          end
        }

        poly_check_args.push(passed_arguments[i]) unless mpl.empty?
        i+=1
      end

      pl.each{ |k, v|
        if v.size > 1
          message = "Function #{@class_obj.name.to_s}##{@method_name.to_s}  argument POLYMORPHIC type mismatch:" +
          "   Expected function type: " + method_type.to_s
          on_error(message)
        end
        pl[k] = v.to_a[0]
      }

      @method_poly[method_type] = pl

      i = 0
      while i < parameter_layout[:required][0]
        return false unless passed_arguments[i].rtc_type.le_poly(method_type.arg_types[i], pl)
        i+=1
      end

      #check the second set of required arguments
      i = 1
      while i <= parameter_layout[:required][1]
        return false unless passed_arguments[-i].rtc_type <= method_type.arg_types[-i]
        i += 1
      end
      
      #check the optional arguments
      opt_offset = parameter_layout[:required][0]
      iter_end = passed_arguments.size - parameter_layout[:required][1]
      i = 0
      while i < parameter_layout[:opt] and opt_offset + i < iter_end
        return false unless passed_arguments[opt_offset + i].rtc_type <= method_type.arg_types[opt_offset + i].type
        i += 1
      end
      
      #we still have some left for the rest argument (which must come after the optional arguments)
      #so check that
      if i + opt_offset < iter_end
        rest_args = passed_arguments.slice(i+opt_offset, iter_end - (i+opt_offset))
        return false unless
          rest_args.rtc_type.type_of_param(0) <= method_type.arg_types[parameter_layout[:required][0] + parameter_layout[:opt]].type
      end
      return true
    end

    def invoke(invokee, arg_vector)
      regular_args = arg_vector[:args]

      method_type = invokee.rtc_typeof(@method_name, @class_obj)
      candidate_types = []
      
      if method_type.instance_of?(Rtc::Types::IntersectionType)
        possible_method_types = method_type.types
      else
        possible_method_types = [method_type]
      end

      for mt in possible_method_types
        if check_args(regular_args, mt)
          candidate_types.push(mt)
        end
      end

      if candidate_types.empty?
        #arg_types = []
        #arg_values = []
        #puts "Function " + @method_name.to_s + " argument type mismatch:"
        #puts "   Expected function type: " + method_type.to_s
        message = "Function #{@class_obj.name.to_s}##{@method_name.to_s}  argument type mismatch:" +
          "   Expected function type: " + method_type.to_s
        #for a in arg_list
        #  arg_types.push(a.rtc_type)
        #  arg_values.push(a)
        #end

        #puts "   Actual argument types: " + arg_types.to_s
        #puts "   Actual argument values: " + arg_values.to_s
        on_error(message)
      end

      blk = arg_vector[:block]

      Rtc::MasterSwitch.turn_on
      if blk
        ret_value = @original_method.bind(invokee).call(*regular_args, &blk)
      else
        ret_value = @original_method.bind(invokee).call(*regular_args)
      end
      Rtc::MasterSwitch.turn_off

      return_valid = candidate_types.any? { |ct|
        h = {}
        ret_value.rtc_type.match_param(ct.return_type, h)

        if h.empty?
          ret_value.rtc_type <= ct.return_type
        else
          h.each{ |k, v|
            if v.size > 1
              message = "Function #{@class_obj.name.to_s}##{@method_name.to_s} return POLYMORPHIC type mismatch:" +
                "   Expected function type: " + method_type.to_s
              on_error(message)
            end
            h[k] = v.to_a[0]
          }

          rm = h.all? {|k, v|
            if @method_poly[ct][k]
              if @method_poly[ct][k].eql?(v)
                true
              else
                false
              end
            else
              true
            end
          }

          if rm == false
            false
          else
            ret_value.rtc_type.le_poly(ct.return_type, h)
          end
        end
      }
      
      if not return_valid
        message = "Function #{@class_obj.name.to_s}##{@method_name.to_s} return type mismatch: " + "   Expected function type: " + method_type.to_s + 
          ", actual return type #{ret_value.rtc_type.to_s}"
        on_error(message)
      end

      ret_value
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
      @method_poly = {}
      @method_name = method_name
      @class_obj = class_obj
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
end
