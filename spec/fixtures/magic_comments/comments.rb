#!/usr/bin/env ruby
# frozen_string_literal: true

# This is a file with a mix of valid and invalid magic comments

# valid_comment: hello
# true_comment: true
# false_comment: false
# comment_123: alpha-numeric and underscores allowed
# 123_will_not_match: will not match
# not-using-underscores: value for comment using dashes

# not_at_start_of_line: will not match

module Test
end

# after_code: will not match
