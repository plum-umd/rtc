require 'racc'

require 'rtc/logging'
require 'rtc/position'
require 'rtc/typing/types'
require 'rtc/typing/type_signatures'

module Rtc

    class DeferredClasses
      @@cache = {}
      def self.cache
        @@cache
      end
    end
    
    class TypeAnnotationParser < Racc::Parser
        @logger = Logging.get_logger('TypeAnnotationParser')

        Types = Rtc::Types
        # receives a single string that may contain "::" or "." and constructs a
        # method identifier according to the content
        def handle_scoped_id(name)
            names = name.split(/::|\./)
            if names.length == 2
              meta = class << proxy; self end
              return MethodIdentifier.new(names[1])
            else
                fail "Internal error. Only A.foo is allowed"
            end
        end

        # makes up a hash that contains a method type information for convenience
        # in later use
        def construct_msig(domain, block, range)
            domain = domain ? (domain.kind_of?(Array) ? domain : [domain]) : []
            return {:domain => domain, :block => block, :range => range}
        end

        def handle_btype(msig)
            msig
        end

        # FIXME(rwsims): kind is unused
        def handle_type_param(kind, text)
            return Rtc::Types::TypeParameter.new(text.to_sym)
        end

        def ident_exists(name_list,scope)
          find_type_ident(name_list,scope) != nil
        end

        def find_type_ident(name_list, scope)
            # cname = x.class == Array ? x.join("::") : x
            curr_scope = scope
            name_list.each {|id|
              if curr_scope.const_defined?(id)
                curr_scope = curr_scope.const_get(id)
              else
                return nil
              end }
            return curr_scope
        end
        
        def handle_type_ident(ident)
          if ident[:type] == :absolute or @proxy.instance_of?(Object)
            eval(ident[:name_list].join("::"))
          else
            scopes = @proxy.name.split("::")
            while scopes.size != 0
              curr_scope = eval(scopes.join("::"))
              obj = find_type_ident(ident[:name_list], curr_scope)
              return obj if obj != nil
              scopes.pop()
            end
            return find_type_ident(ident[:name_list], Object)
          end
        end

        def handle_class_decl(ident, ids=[])
          if ident[:type] == :absolute
            qualified_name = ident[:name_list].join("::")
          else
            qualified_name = (@proxy.instance_of?(Object)? "" : (@proxy.name + "::")) + ident[:name_list].join("::")
          end
          begin
            the_obj = eval(qualified_name)
            Rtc::Types::NominalType.of(the_obj).type_parameters = ids
            the_obj
          rescue => e
            Rtc::DeferredClasses.cache[qualified_name] = ids
            nil
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
                block = Rtc::Types::ProceduralType.new(block[:range],
                                                               block[:domain],
                                                               nil)
            end
            if parameters
                mtype = Types::ParameterizedProceduralType.new(range,
                                                               domain,
                                                               block,
                                                               parameters)
            else
                mtype = Types::ProceduralType.new(range, domain, block)
            end
            return MethodTypeSignature.new(pos, meth_id, mtype)
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
            list[:fields].each {|f| field_types[f.id.to_sym] = f.type }
            list[:methods].each {|m| method_types[m.id.to_sym] = m.type }
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

    end

    class MethodIdentifier < Identifier
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
