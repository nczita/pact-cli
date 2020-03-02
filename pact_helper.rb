require 'pact/provider/configuration'
require 'pact/provider_verifier/set_up_provider_state'
require_relative 'tear_down_provider_state'

Pact.configure do | config |
  config.provider_state_set_up = Pact::ProviderVerifier::SetUpProviderState
  config.provider_state_tear_down = Pact::ProviderVerifier::TearDownProviderState
end
