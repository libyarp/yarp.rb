# frozen_string_literal: true

module Yarp
  # Internal: Responseable implements basic mechanisms allowing handlers to
  # be composed and service its incoming request and headers, along with a
  # pre-registered logger and response headers.
  module Responseable
    # Internal: Initialises a new instance with a given Driver and Request.
    def initialize(driver, request)
      @driver = driver
      @request = request
      @headers = request.headers
      @response_headers = {}
      @logger = driver.logger
      @can_stream = driver.handler_can_stream?
    end

    # Public: Adds one or more headers to the response header set. Calling this
    # method on streameable handlers after sending the first item has no effect.
    # Providing an already-registered header replaces its previous value with
    # the one provided here.
    #
    # Returns nothing.
    def add_headers(**headers)
      if @streaming
        logger.warn "#{self.class.name}: #add_headers called after streaming data. " \
                    "Headers must be set before streaming."
        return
      end

      @response_headers.merge! headers
    end

    alias add_header add_headers

    # Public: Replaces all response headers with the set provided to this
    # method. To incrementally add/replace specific headers, use #add_headers.
    # Calling this method on streameable handlers after sending the first item
    # has no effect.
    #
    # Returns nothing.
    def set_headers(**headers)
      if @streaming
        logger.warn "#{self.class.name}: #set_headers called after streaming data. " \
                    "Headers must be set before streaming."
        return
      end

      @response_headers = headers
    end

    # Deprecated: Use yield from within a method handler instead of invoking this method.
    def stream(value)
      raise NonStreamableResponseError, "method being invoked does not stream responses" unless @can_stream

      unless @streaming
        @driver.begin_streaming(@response_headers)
        @streaming = true
      end
      @driver.push_stream(value)
    end
  end
end
