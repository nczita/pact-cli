require 'faraday'

module Pact
  module ProviderVerifier

    class TearDownProviderStateError < StandardError; end

    class TearDownProviderState

      def initialize provider_state, consumer, options
        @provider_state = provider_state
        @consumer = consumer
        @options = options
        @params = (options && options[:params]) || {}
      end

      def self.call provider_state, consumer, options
        new(provider_state, consumer, options).call
      end

      def call
        if provider_states_setup_url.nil?
          warn_if_provider_state_set
          return
        end

        if skip_tear_down
          return
        end

        log_request
        response = delete_to_provider_state
        check_for_error response
      end

      private

      attr_reader :provider_state, :consumer, :params

      def delete_to_provider_state
        verbose = verbose?
        options = {url: provider_states_setup_url}

        if provider_states_setup_url.start_with?("https:")
          options[:ssl] = {verify: false}
        end

        connection = Faraday.new(options) do | faraday |
          # Have encountered flakiness on windows build for pact-go
          # Using retries as a hacky solution to try and get around this
          # until/if we can work out what the underlying cause is.
          # https://github.com/pact-foundation/pact-go/issues/42
          # eg. https://ci.appveyor.com/project/mefellows/pact-go/build/25#L1202

          faraday.request :retry, max: 2, interval: 0.05,
            interval_randomness: 0.5, backoff_factor: 2,
            methods:[:post],
            exceptions: [Faraday::ConnectionFailed]

          faraday.response :logger if verbose
          faraday.adapter Faraday.default_adapter
        end

        connection.delete do |req|
          req.headers["Content-Type"] = "application/json"
          req.body = {
            consumer: consumer,
            state: provider_state,
            states: [provider_state],
            params: params
          }.to_json
        end
      end

      def provider_states_setup_url
        ENV['PROVIDER_STATES_SETUP_URL']
      end

      def skip_tear_down
        ENV['PROVIDER_STATES_SKIP_TEARDOWN']
      end

      def verbose?
        ENV['VERBOSE_LOGGING']
      end

      def check_for_error response
        if response.status >= 300
          raise TearDownProviderStateError.new("Error tear down provider state '#{provider_state}' for consumer '#{consumer}' at #{provider_states_setup_url}. response status=#{response.status} response body=#{response.body}")
        end
      end

      def log_request
        if verbose?
          $stdout.puts "DEBUG: Tear down provider state '#{provider_state}' for consumer '#{consumer}' using provider state set up URL #{provider_states_setup_url}"
        end
      end

      def warn_if_provider_state_set
        if provider_state
          $stderr.puts "WARN: Skipping tear down for provider state '#{provider_state}' for consumer '#{consumer}' as there is no --provider-states-setup-url specified."
        end
      end
    end
  end
end