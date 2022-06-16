# frozen_string_literal: true

module Yarp
  # Internal: ServiceCallbacks implements basic mechanisms allowing handlers to
  # be composed and service its incoming request and headers, along with a
  # pre-registered logger and response headers.
  module ServiceCallbacks
    def self.extended(base)
      base.include InstanceMethods
    end

    def before_any(*args, &block)
      @before_callbacks ||= Hash.new { [] }

      met = if args.length == 1
              args.first
            else
              block
            end

      if met.is_a? Symbol
        met_n = met
        met = proc { |n| send(met_n, n) }
      end

      if met.arity != 1
        raise ArgumentError, "Invalid arity for #before_any block. " \
                             "Must receive 1 argument (method_name)"
      end

      @before_callbacks[:__any] = @before_callbacks[:__any] + [met]
    end

    def after_any(*args, &block)
      @after_callbacks ||= Hash.new { [] }

      met = if args.length == 1
              args.first
            else
              block
            end

      if met.is_a? Symbol
        met_n = met
        met = proc { |n| send(met_n, n) }
      end

      if met.arity != 1
        raise ArgumentError, "Invalid arity for #after_any block. " \
                             "Must receive 1 argument (method_name)"
      end

      @after_callbacks[:__any] = @after_callbacks[:__any] + [met]
    end

    def before(method_name, *args, &block)
      @before_callbacks ||= Hash.new { [] }

      met = if args.length == 1
              args.first
            else
              block
            end

      if met.is_a? Symbol
        met_n = met
        met = proc { send(met_n) }
      end

      if met.arity != 0
        raise ArgumentError, "Invalid arity for #before block. " \
                             "Must receive no arguments"
      end

      @before_callbacks[method_name] = @before_callbacks[method_name] + [met]
    end

    def after(method_name, *args, &block)
      @after_callbacks ||= Hash.new { [] }

      met = if args.length == 1
              args.first
            else
              block
            end

      if met.is_a? Symbol
        met_n = met
        met = proc { send(met_n) }
      end

      if met.arity != 0
        raise ArgumentError, "Invalid arity for #after block. " \
                             "Must receive no arguments"
      end

      @after_callbacks[method_name] = @after_callbacks[method_name] + [met]
    end

    # InstanceMethods provides internal instance methods for services
    module InstanceMethods
      def invoke_callbacks(which, method, req)
        cbs_source = which == :before ? :@before_callbacks : :@after_callbacks
        cbs = self.class.instance_variable_get(cbs_source) || Hash.new { [] }
        inst = self
        cbs = if which == :before
                (cbs[:__any] + cbs[method])
              else
                (cbs[method] + cbs[:__any])
              end
        cbs.each { |cb| inst.instance_exec(req, &cb) }
      end
    end
  end
end
