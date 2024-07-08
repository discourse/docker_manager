# frozen_string_literal: true

module PageObjects
  module Pages
    class AdminUpdate < PageObjects::Pages::Base
      def visit
        page.visit("/admin/update")
        self
      end

      def displayed?
        has_css?("h3", text: "Updates")
      end

      def has_repo?(repo)
        has_css?("tr.repo .repo__name", text: repo[:name]) &&
          (!repo[:url] || has_css?("tr.repo .repo__about a[href='#{repo[:url]}']"))
      end
    end
  end
end
