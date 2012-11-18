require_relative './type'
require 'rtc/tools/hash-builder.rb'

module Rtc::Types
    # A type defined by a collection of named fields and methods. Supertype of all objects
    class StructuralType < Type
        # Create a new StructuralType.
        #
        # [+field_types+] Map from field names as symbols to their types.
        # [+method_types+] Map from method names as symbols to their types.
        def initialize(field_types, method_types)
            @field_types = field_types
            @method_types = method_types
            super()
        end

        def map
          new_fields = {}
          new_methods = {}
          @field_types.each_pair {
            |field_name,field_type|
            new_fields[field_name] = yield field_type
          }
          @method_types.each_pair {
            |method_name, method_type|
            new_methods[method_name] = yield method_type
          }
          StructuralType.new(new_fields, new_methods)
        end
        
        def is_terminal
          false
        end

        def each
          @method_types.each_value {
            |m|
            yield m
          }
          @field_types.each_value {
            |f|
            yield f
          }
        end

        def field_names
          @field_types.keys
        end
        
        def method_names
          @method_types.keys
        end

        def has_method?(name)
          @method_types.has_key?(name)
        end

        def any?
          yield self
        end

        # Return +true+ if +self+ is a subtype of +other+. This follows the
        # usual semantics of BottomType and TopType; if +other+ is another
        # StructralType, all of the following must be true:
        # 1. +self+ has at least all the fields and methods in +other+.
        # 2. Corresponding field types in +self+ and +other+ must be the same
        #    type.
        # 3. The method types in +self+ and +other+ are covariant (the types in
        #    +self+ are subtypes of the types with the same key in +other+).
        def <=(other)
            case other
            when TupleType
                false
            when StructuralType
                other.method_names.each do |m_name|
                  return false unless method_names.include?(m_name)
                  mine = get_method(m_name)
                  theirs = other.get_method(m_name)
                  return false unless mine <= theirs
                end
                return true
            else
                super(other)
            end
        end

        def to_s  # :nodoc:
            fields = map_to_string(@field_types)
            methods = map_to_string(@method_types)
            "{ #{fields} | #{methods} }"
        end

        def eql?(other)  # :nodoc:
            return false unless other.instance_of?(StructuralType)

            return false unless type_map_eql?(@field_types, other.field_types)
            return false unless type_map_eql?(@method_types, other.method_types)
            true
        end

        def hash  # :nodoc:
            hash = type_map_hash(@field_types)
            hash += 23 * type_map_hash(@method_types)
        end
        
        # can be overriden in subclasses
        def get_method(name)
          return @method_types[name]
        end
        
        # can be overriden in subclasses
        def get_field(name)
          return @field_types[name]
        end
        
        protected

        def can_subtype?(other)
            (other.instance_of?(StructuralType) or
                    other.instance_of?(NominalType))
        end
        
        
        private

        # Compute a hash code for a symbol-to-type map.
        def type_map_hash(map)
            builder = Rtc::HashBuilder.new(19, 313)
            map.each_pair do |sym, type|
                builder.include(sym)
                builder.include(type)
            end
            builder.get_hash
        end

        # Return +true+ if +left+ and +right+ have the same set of symbols and
        # have equal types for corresponding symbols.
        def type_map_eql?(left, right)
            return false unless left.size == right.size
            left.each_pair do |sym, left_type|
                return false unless right.has_key?(sym)
                 right_type = right[sym]
                return false unless right_type == left_type
            end
        end

        # Return a string representation of a symbol-to-type map.
        def map_to_string(type_map)
            if type_map.empty?
                return ""
            end
            pairs = type_map.each_pair.map do |symbol, type|
                "#{symbol}: #{type}"
            end
            pairs.join(", ")
        end
    end
end
