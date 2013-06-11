require 'dsl'

class Dsl::Spec
  def inspect(*events, &blk)
    trace = TracePoint.new(*events, &blk)
    pre_task { trace.enable }
    post_task { trace.disable }
  end
end
