# frozen_string_literal: true

module Yarp
  # Public: Service is a base module for all Yarp services, and implements all
  # required mechanisms for handling requests.
  module Service
    def self.included(base)
      base.attr_reader :request, :headers, :logger, :response_headers
      base.include Yarp::CommonResponses
      base.include Yarp::Responseable
    end
  end
end
