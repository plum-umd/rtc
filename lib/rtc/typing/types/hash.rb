require_relative './type'
require 'rtc/runtime/native'

module Rtc::Types
  class HashType < Type
    attr_reader :optional, :required, :num_required
    def initialize(type_mapping)
      @type_map = type_mapping
      @num_required = 0
      @required = Rtc::NativeHash.new
      @optional = Rtc::NativeHash.new
      type_mapping.each {
        |k,t|
        if t.is_a?(OptionalArg)
          @optional[k] = t.type
        else
          @required[k] = t
          @num_required += 1
        end
      }
    end

    def each
      @num_required.each {
        |k,t|
        yield t
      }
    end
    def map
      mapped_types = Rtc::NativeHash.new
      @type_map.each {
        |k,t|
        mapped_types[k] = yield t
      }
      HashType.new(mapped_types)
    end
    
    def has_member?(name)
      return @type_map.has_key?(name)
    end
    
    def get_member_type(name)
      return @required[name] if @required.has_key?(name)
      return @optional[name] if @optional.has_key?(name)
      return nil
    end

    def <=(other)
      case other
      when HashType
        other.required.each {
          |k,v|
          return false unless @required.has_key?(k)
          return false unless @required[k] <= v
        }
        # optional members in the lhs can be "filled" by either
        # optional or required members, but we have to make sure we
        # don't have a type mismatch
        other.optional.each {
          |k,v|
          next unless has_member?(k)
          return false unless get_member_type(k) <= v
        }
      else
        super
      end
    end
    
    def to_s
      components = Rtc::NativeArray.new
      @type_map.each {
        |k,v|
        components << "#{k.inspect} => #{v.to_s}"
      }
      return "{"+components.join(", ")+"}"
    end

    def ==(other)
      return false unless other.is_a?(HashType)
      return other.instance_variable_get(:@type_map) == @type_map
    end
    
    def eql?(other)
      self == other
    end

    # in the interest of correctness, this is actually pretty involved
    # unfortunately
    def hash
      if not defined?(@cached_hash)
        # this is really a specialized version of the hash
        # builder. Code duplication? Yes. That big a deal? Not really.
        current_hash = 269
        @optional.each {
          |k,t|
          current_hash += 503 * ((431 + k.hash * 443) + t.hash * 443)
        }
        @require.each {
          |k,t|
          req_builder = HashBuilder.new(497,419)
          current_hash += 503 * ((497 + k.hash * 419) + t.hash * 419)
        }
        @cached_hash = current_hash
      end
      @cached_hash
    end
  end
end
