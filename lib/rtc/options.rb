#contains the options for controlling the behavior of Rtc
# Note that the Options hash is not for public manipulation, instead
# all options must be set through the provided api
module Rtc
  Options = {
    :on_type_error => :exception,
    :type_error_config => nil,
    :ignore_bad_typesig => false,
    :no_lazy_loading => false,
  }
  def self.on_type_error=(behavior)
    if behavior == :exception
      Options[:on_type_error] = :exception
    elsif behavior == nil or behavior == :ignore
      Options[:on_type_error] = :ignore
    elsif behavior == :exit
      Options[:on_type_error] = :exit
    elsif behavior.respond_to?(:call)
      Options[:on_type_error] = :callback
      Options[:type_error_config] = behavior
    elsif behavior.respond_to?(:write)
      Options[:on_type_error] = :file
      Options[:type_error_config] = behavior
    elsif behavior == :console
      Options[:on_type_error] = :file
      Options[:type_error_config] = STDOUT
    else
      raise "#{behavior} is an invalid error response."
    end
  end
end
