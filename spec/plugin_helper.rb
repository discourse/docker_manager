# frozen_string_literal: true

Pathname.new(__dir__).glob("support/**/*.rb").each { |f| require f }
