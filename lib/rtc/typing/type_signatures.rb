# Type signature classes.

module Rtc
    class TypeSignature

        attr_accessor :pos
        attr_accessor :id
        attr_accessor :type

        def initialize(pos, id, type)
            @pos = pos
            @id = id
            @type = type
        end

        def to_s()
            mname = @id.to_s 
            mname = "'#{mname}'" unless mname =~ /^\w.*$/
                "#{mname}: #{type}" 
        end

        def format(ppf)
            ppf.text("typesig(\"")
            ppf.group(5) do
                mname = @id.to_s 
                mname = "'#{mname}'" unless mname =~ /^\w.*$/
                    ppf.text("#{mname} :")
                # ppf.group(mname.to_s.length+3) do
                ppf.group(2) do
                    ppf.breakable("")
                    type.format(ppf)
                end
                ppf.breakable("")
                ppf.text("\")")
            end
            ppf.breakable("")
        end 

    end

    class AbstractMethodTypeSignature < TypeSignature

        # intersection type and polymorphic type are special cases
        def to_s()
            str = 
                if type.instance_of? Rtc::Types::IntersectionType
                    then intertype_to_s()
                #TODO(jtoman): add in support for polymorphism
                #elsif type.instance_of? PolyMethodType
                #    then polytype_to_s()
                else super() # otherwise same
                end 
            return str
        end

        def format(ppf)
            if type.instance_of? Rtc::Types::IntersectionType
                format_intertypes(ppf, @id)
            #TODO(jtoman): add in support for polymorphism    
            #elsif type.instance_of? PolyMethodType
            #    format_polytypes(ppf, @type)
            else
                super
            end
        end 

        private

        # TODO
        def format_intertypes(ppf, id)
            type.types.each do |type|
                ppf.breakable()
                ppf.text "#{id.to_s} :"
                ppf.group(id.to_s.length + 3) do
                    @type.format(ppf)
                end
            end
        end

        # TODO
        def format_polytypes(ppf, sig)
            ppf.breakable()
            ppf.text polytype_to_s()
        end

        # TODO
        def intertype_to_s()
            strs = @type.types.map do |type|
                (
                #TODO(jtoman): add back in for polymorphism
                #type.kind_of?(PolyMethodType) ? polytype_to_s() : 
                "#{@id.to_s} : #{@type}")
            end
            return strs.join("\n")
        end

        def polytype_to_s()
            "#{@id.to_s}<#{@type.tparams.join(',')}> : #{@type}"
        end 

    end
    class MethodTypeSignature < AbstractMethodTypeSignature; end
    class ClassMethodTypeSignature < AbstractMethodTypeSignature; end

    # no need to do anything different; the name should be starting with @
    # TODO: maybe add this name checking code?
    class InstanceVariableTypeSignature < TypeSignature
    end

    # no need to do anything different; the name should be starting with @@
    # TODO: maybe add this name checking code?
    class ClassVariableTypeSignature < TypeSignature
    end

    # no need to do anything different; the name should be starting with a
    # captial letter
    # TODO: maybe add this name checking code?
    class ConstantTypeSignature < TypeSignature
    end

end  # module Rtc

