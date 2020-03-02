Teardown send `delete` request to `provider_states_setup_url` to allow tear down state in Provider.
It also fails verification if cleanup wasn't successful which is marked by 4XX or 5XX status code.
Can be skipped if `PROVIDER_STATES_SKIP_TEARDOWN` environment variable is set.

The basic use case is when provider itself use pact-mock to interact with other apps.
This allows to have chain of contract tests.
