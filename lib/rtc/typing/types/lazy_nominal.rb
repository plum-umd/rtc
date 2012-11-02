require_relative './nominal'

module Rtc::Types
      #this class still has a lot of limitations. For a list of the limitations
    # see the comment on commit a8c57329554a8616f2f1a742275d66bbc6424923
    class LazyNominalType < NominalType
      proxied_methods = (NominalType.instance_methods(false) + [:method_names, :field_names]) - [:to_s, :inspect, :eql?, :==, :hash]
      proxied_methods.each do
        |proxied_mname|
        define_method(proxied_mname, lambda {
          |*args|
          concrete_obj.send(proxied_mname, *args)
        })
      end
      
      def to_s
        if @concrete_obj
          @concrete_obj.to_s
        else
          internal_repr
        end
      end
      
      def inspect
        if @concrete_obj
          @concrete_obj.inspect
        else
          internal_repr
        end
      end
      
      def eql?(other)
        if other.instance_of?(NominalType)
          return @concrete_obj == other if has_obj
          false
        elsif other.instance_of?(LazyNominalType)
          if other.has_obj and self.has_obj
            @concrete_obj == other.concrete_obj
          elsif not other.has_obj and not self.has_obj
            @context == other.context and @ident == other.ident
          else
            false
          end
        else
          false
        end
      end
      
      def hash
        hash_builder = Rtc::HashBuilder.new(1009,1601)
        hash_builder.include(@context)
        hash_builder.include(@ident)
        hash_builder.get_hash
      end
      
      def initialize(ident, context)
        @ident = ident
        @context = context
        @concrete_obj = nil
        super(nil)
      end
      
      protected
      
      def has_obj
        @concrete_obj != nil
      end
      
      attr_reader :ident, :context
      
      def internal_repr
        "LazyNominalClass(#{id})<#{Rtc::ClassLoader.ident_to_s(@ident)},#{@context}"
      end
      
      def concrete_obj
        if @concrete_obj
          @concrete_obj
        else
          @concrete_obj = NominalType.of(Rtc::ClassLoader.load_class(@ident, @context))
        end
      end
    end
end
