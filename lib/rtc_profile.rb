require 'rtc_profiler'

RubyVM::InstructionSequence.compile_option = {
  :trace_instruction => true,
  :specialized_instruction => false
}
END {
  Rtc_Profiler__::print_profile(STDERR)
}
Rtc_Profiler__::start_profile
