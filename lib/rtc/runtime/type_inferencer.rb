
module Rtc
  class TypeInferencer
    def self.infer_type(it)
        curr_type = Set.new
        has_parameterized_type = false
        it.each {
          |elem|
          elem_type = elem.rtc_type
          super_count = 0
          if curr_type.size == 0 
            curr_type << elem_type
            next
          end
          was_subtype = curr_type.any? {
            |seen_type|
            if elem_type <= seen_type
              true
            elsif seen_type <= elem_type
              super_count = super_count + 1
              false
            end
          }
          if was_subtype
            next
          elsif super_count == curr_type.size
            curr_type = Set.new([elem_type])
          else
            curr_type << elem_type
          end
        }
        if curr_type.size == 0
          Rtc::Types::BottomType.instance
        elsif curr_type.size == 1
          curr_type.to_a[0]
        else
          Rtc::Types::UnionType.of(self.unify_param_types(curr_type))
        end
      end
      
      private
      
      #FIXME(jtoman): see if we can lift this step into the gen_type step
      def self.unify_param_types(type_set)
        non_param_classes = []
        parameterized_classes = {}
        type_set.each {
          |member_type|
          if member_type.parameterized?
            nominal_type = member_type.nominal
            tparam_set = parameterized_classes.fetch(nominal_type) {
              |n_type|
              [].fill([], 0, n_type.type_parameters.size)
            }
            ((0..(nominal_type.type_parameters.size - 1)).map {
              |tparam_index|
              extract_types(member_type.parameters[tparam_index])
            }).each_with_index {
              |type_parameter,index|
              tparam_set[index]+=type_parameter
            }
            parameterized_classes[nominal_type] = tparam_set
          else
            non_param_classes << member_type
          end
        }
        parameterized_classes.each {
          |nominal,type_set|
          non_param_classes << ParameterizedType.new(nominal,
          type_set.map {
            |unioned_type_parameter|
            TypeVariable.new(Rtc::Types::UnionType.of(unify_param_types(unioned_type_parameter)),true)
          })
        }
        non_param_classes
      end

  end
end