# Common code for creating loggers, verbosity and logging levels should be called here.
#
# The ruby 'logger' library does not seem to have the concept of a root logger,
# from which all other loggers descend. Rather than having to set up the output
# stream, name and verbosity level everywhere we want a logger, this method can
# be used to get alread-configured Logger instances.
#
# Author:: Ryan W Sims (rwsims@umd.edu)

require 'logger'

module Rtc
    module Logging
        @verbose = false

        # Convenience method for wrapping Logger creation. Returns a logger that
        # outputs to STDERR and which has its level set per commandline options
        # and its progname set to the given name.
        def self.get_logger(progname)
            logger = Logger.new(STDERR)
            logger.progname = progname
            if @verbose
                logger.level = Logger::DEBUG
            else
                logger.level = Logger::WARN
            end
            return logger
        end

        # Set the loggers generated by this module to be verbose. Should only be
        # called once during initialization.
        def self.make_verbose
            @verbose = true
        end
    end
end
