# frozen_string_literal: true

require "dry/system"

Dry::System.register_provider_sources Pathname(__dir__).join("provider_sources").realpath
