#!/bin/bash

exit_if_error() {
  if [ $1 -ne 0 ]; then
    exit 1
  fi
}

export CI_NAME="heroku"
export GIT_COMMITTED_AT="$(date +%s)"

ruby_filename="coverage/codeclimate.rb.json"
# js_filename="coverage/codeclimate.js.json"

# ruby test suite
bundle exec rspec
exit_if_error $?

./cc-test-reporter format-coverage --output $ruby_filename

# JS linting and test suite
# yarn test
# exit_if_error $?

# ./cc-test-reporter format-coverage --input-type lcov --output $js_filename coverage/karma/lcov.info

# sum code coverage and send to codeclimate
./cc-test-reporter sum-coverage $ruby_filename #$js_filename
./cc-test-reporter upload-coverage