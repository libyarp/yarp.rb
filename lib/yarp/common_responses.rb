# frozen_string_literal: true

module Yarp
  # Internal: CommonResponses implements common error utilities for clients;
  # methods defined here are present on Responseable.
  module CommonResponses
    # Public: Raises an Internal Error exception with an optional identifier and
    # user data.
    def internal_error!(identifier: nil, user_data: nil)
      raise Proto::Error.internal_error(headers: @response_headers, identifier: identifier, user_data: user_data)
    end

    # Public: Raises an Request Timeout exception with an optional identifier
    # and user data.
    def request_timeout!(identifier: nil, user_data: nil)
      raise Proto::Error.request_timeout(headers: @response_headers, identifier: identifier, user_data: user_data)
    end

    # Public: Raises an Unimplemented Method exception with an optional
    # identifier and user data.
    def unimplemented_method!(identifier: nil, user_data: nil)
      raise Proto::Error.unimplemented_method(headers: @response_headers, identifier: identifier, user_data: user_data)
    end

    # Public: Raises n Type Mismatch exception with an optional identifier and
    # user data.
    def type_mismatch!(identifier: nil, user_data: nil)
      raise Proto::Error.type_mismatch(headers: @response_headers, identifier: identifier, user_data: user_data)
    end

    # Public: Raises an Unauthorized exception with an optional identifier and
    # user data.
    def unauthorized!(identifier: nil, user_data: nil)
      raise Proto::Error.unauthorized.call(headers: @response_headers, identifier: identifier, user_data: user_data)
    end

    # Public: Raises a Bad Request exception with an optional identifier and user
    # data.
    def bad_request!(identifier: nil, user_data: nil)
      raise Proto::Error.bad_request(headers: @response_headers, identifier: identifier, user_data: user_data)
    end

    # Public: Raises a generic error with a given identifier and optional
    # user data.
    def error!(identifier, user_data: nil)
      raise Proto::Error.generic(headers: @response_headers, identifier: identifier, user_data: user_data)
    end
  end
end
