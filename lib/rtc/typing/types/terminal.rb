module Rtc::Types
  module TerminalType
    def replace_parameters(_t_vars)
      self
    end

    def _to_actual_type
      self
    end

    def each
      yield self
    end

    def is_terminal; true; end
  end
end
