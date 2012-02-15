require 'racc'

require 'rtc/logging'
require 'rtc/position'
require 'rtc/typing/types'
require 'rtc/typing/type_signatures'

module Rtc

    class TypeAnnotationParser < Racc::Parser
        @logger = Logging.get_logger('TypeAnnotationParser')

        Types = Rtc::Types
        # receives a single string that may contain "::" or "." and constructs a
        # method identifier according to the content
        def handle_scoped_id(name)
            names = name.split(/::|\./)
            if names.length == 2
                meta = class << proxy; self end
            return MethodIdentifier.new(meta, names[1])
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

        # TODO
        def handle_btype(msig)
            msig
        end

        # FIXME(rwsims): kind is unused
        def handle_type_param(kind, text)
            return Rtc::Types::TypeParameter.new(text.to_sym)
        end

        def handle_type_constructor(x)
            fatal("type constructs not yet supported")
        end

        # Turn a list of type variables/type parameters into a list of strings
        # or symbols for output.
        def prepare_type_vars_for_sig(tvars)
            r = []
            case tvars
            when Array
                tvars.each do |t|
                    if (t.to_s.index('^') == 0)
                        raise(NotImplementedError,
                              "Varargs type variables (of form ^args) " +
                              "are not yet supported")
                    end
                    if t.instance_of?(Rtc::Types::TypeParameter)
                        r << t.symbol
                    else
                        r << t
                    end
                end
            when Rtc::Types::TypeParameter
                t = tvars
                if(t.to_s.index('^') == 0) #varargs
                    warn("Varargs type variables (of form ^args) are not " +
                         "yet supported")
                end
                r << t.name.to_sym
            else
                raise(ArgumentError,
                      "Unexpected type variable collection: #{tvars.inspect})")
            end
            return r
        end

        def handle_type_ident(ident)
            # cname = x.class == Array ? x.join("::") : x

            if ident.instance_of?(Array)
                curr_scope = Object
                ident.each {|id| curr_scope = curr_scope.const_get(id) }
                return curr_scope
            else
                return Object.const_get(ident)
            end
        end

        def handle_class_decl(name, ids=[])
            puts "handling class decl for #{name}, #{ids}"
            return {:kind => :class_decl,
                :name => name,
                :type_ids => ids }
        end

        private

        # obtains the module/class itself by evaluating the name at the top scope
        #--
        # TODO(rwsims): This might not handle classes defined within modules
        # correctly.
        def get_class(name, is_class=true)
            keyword = is_class ? "class" : "module"
            scope = @proxy.to_s == "main" ? "" : @proxy.name
            eval_string = "#{keyword} ::#{name}; end" # in case, declare it
            eval eval_string
            mod = Object.const_get(name) # then get the actual module/class
            return mod
        end

        # sets type parameters and constraints for the module/class.
        # NOTE: we no longer use temporary place holder
        def set_tparams(name, tparams, cons, is_class=true)
            tparams.map! do |tparam| 
                case tparam
                when Rtc::Types::TypeParameter
                    tparam
                else
                    Rtc::Types::TypeParameter.new(tparam)
                end
            end
            mod = get_class(name, is_class)
            mod.instance_variable_set(:@__class_type_params, tparams)
            mod.instance_variable_set(:@__class_type_constraints, cons)
            return [tparams, cons]
        end

        # replaces duplicate type parameters with the original type parameters
        # (that are *declared* and not being used); for example,
        #   foo<t> : t -> t 
        # the second and third t are replaced with the first t
        def coalesce_tparams(mod, tparams, type, include_class_tparams=false)
            map = {}
            if include_class_tparams
                cls_tparams = mod.instance_variable_get(:@__class_type_params)
                if cls_tparams
                    cls_tparams.each {|tparam| map[tparam.name] = tparam }
                end
            end
            tparams.each {|tparam| map[tparam.name] = tparam } if tparams
            if map.length > 0 
                return TypeParamCoalescer.visit(type, map, {})
            else 
                return type
            end
        end

        # helper method for coalescing type parameters in a single constraint
        def coalesce_tparams_in_constraint(mod, tparams, con, 
                                           include_class_tparams=false)
            new_con = con.clone
            new_con.tvar = coalesce_tparams(mod, tparams, con.tvar, 
                                            include_class_tparams)
            new_con.supertype = 
                coalesce_tparams(mod, tparams, con.supertype, include_class_tparams)
            return new_con
        end

        public

        # handles a class annotation. it does two things--setting the type
        # parameters and refined constraints to the corresponding module/class.
        def handle_class_annot(decl, subs, cons, is_class=true)
            name = decl[:name]
            ids = decl[:type_ids]
            (tparams, cons) = set_tparams(name, ids, cons, is_class)
            if cons
                cons.map! {|con|
                    mod = get_class(name, is_class)
                    coalesce_tparams_in_constraint(mod, tparams, con, false)
                }
            end
            # subs.each {|s| proxy.__subtype(name, s, @pos) } if subs != nil
            return []
        end

        # constructs a method type (mono or poly) and coalesces type parameters
        # appearing in the method type (including the constraints)
        def handle_mtype(meth_id, parameters, cons, msig)
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

        def handle_constant(name, type)
            id = ConstantIdentifier(name.to_sym)
            return ConstantTypeSignature(@pos, id, type)
        end

        def handle_structural_type(list)
            field_types = {}
            method_types = {}
            list[:fields].each {|f| field_types[f.id.to_s.to_sym] = f.type }
            list[:methods].each {|m| method_types[m.id.to_s.to_sym] = m.type }
            t = Rtc::Types::StructuralType.new(field_types, method_types)
            return t
        end

        def handle_named_type_expr(name, type)
            id = Identifier.new(name.to_sym) # XXX????
            Rtc::DynamicTyping::TypeSignature.new(pos, id, type)
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

        attr_accessor :target 

        def initialize(target, name)
            @target = target 
            super(name)
        end

        def eql?(other); (super) && @target == other.target end
        def hash(); (@target.hash + @name.hash) end
        # def to_s(); "#{@target ? "self." : ""}#{@name}" end
        def to_s(); "#{@name}" end

    end

    # TODO
    class InstanceVariableIdentifier < Identifier
    end

    class ClassVariableIdentifier < Identifier
    end

    class ConstantIdentifier < Identifier
    end

end
