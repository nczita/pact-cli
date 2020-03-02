FROM pactfoundation/pact-cli

ADD pact_helper.rb .
ADD tear_down_provider_state.rb .

ENV MONKEYPATCH $HOME/pact_helper.rb

