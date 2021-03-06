require 'racc'

require 'rtc/logging'
require 'rtc/position'
require 'rtc/typing/types'
require 'rtc/typing/type_signatures'
require 'rtc/runtime/class_loader'
require 'rtc/runtime/native'
module Rtc
    class TypeAnnotationParser < Racc::Parser
        @logger = Logging.get_logger('TypeAnnotationParser')

        Types = Rtc::Types
        # makes up a hash that contains a method type information for convenience
        # in later use
        def construct_msig(domain, block, range)
            domain = domain ? (domain.kind_of?(Array) ? Rtc::NativeArray.new(domain) : Rtc::NativeArray[domain]) : Rtc::NativeArray.new
            return {:domain => domain, :block => block, :range => range}
        end

        def handle_btype(msig)
            msig
        end

        # FIXME(rwsims): kind is unused
        def handle_type_param(kind, text)
            return Rtc::Types::TypeParameter.new(text.to_sym)
        end
        
        def get_type(type_name)
          to_ret = @proxy.rtc_lookup_type(type_name)
          if to_ret.nil?
            raise "Type #{type_name} not defined in context #{@object}"
          end
          to_ret
        end

        def handle_type_ident(ident)
          begin
            Rtc::Types::NominalType.of(Rtc::ClassLoader.load_class(ident, @proxy))
          rescue Rtc::ClassNotFoundException => e
            Rtc::Types::LazyNominalType.new(ident, @proxy)
          end
        end

        public

        # constructs a method type (mono or poly) and coalesces type parameters
        # appearing in the method type (including the constraints)
        def handle_mtype(meth_id, parameters, msig)
            # expect msig to be result from construct_msig
            domain = msig[:domain]
            block  = msig[:block]
            range  = msig[:range]
            if block
                block = Rtc::Types::ProceduralType.new(parameters, block[:range],
                                                               block[:domain],
                                                               nil)
            end


            mtype = Types::ProceduralType.new(parameters, range, domain, block)
            type_klass = meth_id.instance_of?(Rtc::ClassMethodIdentifier) ? ClassMethodTypeSignature : MethodTypeSignature 
            return type_klass.new(pos, meth_id, mtype)
        end

        def handle_var(kind, name, type)
            r = case kind
                when :ivar
                    id = InstanceVariableIdentifier.new(name.to_sym)
                    InstanceVariableTypeSignature.new(@pos, id, type)
                when :cvar
                    id = ClassVariableIdentifier.new(name.to_sym)
                    ClassVariableTypeSignature.new(pos, id, type)
                when :gvar
                    err("Global variables not yet supported, " +
                        "found annotation for #{name}")
                else
                    fatal("Unknown variable annotation kind '#{kind.to_s}'")
                end
            return r
        end

        def handle_structural_type(list)
            field_types = {}
            method_types = {}
            list[:fields].each {|f| field_types[f.id.to_s] = f.type }
            list[:methods].each {|m| method_types[m.id.to_s] = m.type }
            t = Rtc::Types::StructuralType.new(field_types, method_types)
            return t
        end

        def warn(msg, lineno = nil)
            if(lineno != nil)
                msg += " @ line #{lineno.to_s}"
            end
            logger.warn(msg)
        end

        def err(msg, lineno = nil)
            if(lineno != nil)
                msg += " @ line #{lineno.to_s}"
            end
            logger.error(msg)
        end

        def fatal(msg, lineno = nil)
            if(lineno != nil)
                msg += " @ line #{lineno.to_s}"
            end
            raise(RuntimeError, msg)
        end

    end

    # Because Rtc's type annotation supports class/instance methods and
    # fields, it would be essential to make the identifiers of methods/fields
    # not just strings.
    class Identifier

        attr_reader :name

        def initialize(name); @name = name.to_sym end
        def eql?(other); @name == other.name end
        def hash(); @name.hash end
        def to_s(); @name.to_s end
        def to_sym(); @name end
    end

    class MethodIdentifier < Identifier
        def initialize(name) 
            super(name)
        end
    end
    
    class ClassMethodIdentifier < Identifier
        def initialize(name)
          super(name)
        end
    end

    # TODO
    class InstanceVariableIdentifier < Identifier
    end

    class ClassVariableIdentifier < Identifier
    end

    class ConstantIdentifier < Identifier
    end

end
