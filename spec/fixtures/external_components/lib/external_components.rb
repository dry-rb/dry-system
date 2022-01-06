# frozen_string_literal: true

require "dry/system"

Dry::System.register_source_providers Pathname(__dir__).join("../components").realpath
Dry::System.register_source_providers Pathname(__dir__).join("../alt-components").realpath
