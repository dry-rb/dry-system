# frozen_string_literal: true

require "dry/system"

Dry::System.register_source_providers Pathname(__dir__).join("provider_sources").realpath
