# Ruby runtime

GitHub Actions reads `.ruby-version` to install the latest available Ruby 3.4 patch release. The Rails test step runs `ruby -v` before the tests, so the test log shows which patch release CI used.

The production image uses the official `ruby:3.4-slim` base. The image build checks the registry for a newer base even when it can reuse cached layers. New Ruby 3.4 patches are picked up on subsequent builds once they reach the base tag, without a repository change.

Check the final-stage `ruby -v` output in the main-branch image build log for the runtime version. To check an existing application image directly, run `docker run --rm --entrypoint ruby IMAGE -v`, replacing `IMAGE` with its tag or digest.
