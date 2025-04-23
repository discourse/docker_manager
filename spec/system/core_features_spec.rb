# frozen_string_literal: true

RSpec.describe "Core features", type: :system do
  # TODO: Stop skipping when shared example is available in stable
  next if Discourse.git_branch == "stable"

  before { enable_current_plugin }

  it_behaves_like "having working core features"
end
