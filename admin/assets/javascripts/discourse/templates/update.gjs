import RouteTemplate from "ember-route-template";
import DBreadcrumbsItem from "discourse/components/d-breadcrumbs-item";
import DButton from "discourse/components/d-button";
import DPageHeader from "discourse/components/d-page-header";
import NavItem from "discourse/components/nav-item";
import htmlSafe from "discourse/helpers/html-safe";
import { i18n } from "discourse-i18n";

export default RouteTemplate(
  <template>
    <DPageHeader
      @titleLabel={{i18n "admin.docker.update_title"}}
      @descriptionLabel={{i18n "admin.docker.update_description"}}
      @shouldDisplay={{true}}
    >
      <:breadcrumbs>
        <DBreadcrumbsItem @path="/admin" @label={{i18n "admin_title"}} />
        <DBreadcrumbsItem
          @path="/admin/update"
          @label={{i18n "admin.docker.update_title"}}
        />
      </:breadcrumbs>
      <:tabs>
        <NavItem
          @route="update.index"
          @label="admin.docker.navigation.versions"
        />
        <NavItem
          @route="update.processes"
          @label="admin.docker.navigation.processes"
        />
      </:tabs>
    </DPageHeader>

    <div class="docker-manager admin-container">
      {{#if @controller.showBanner}}
        <div id="banner">
          <div id="banner-content">
            <div class="floated-buttons">
              <DButton
                @icon="xmark"
                @action={{@controller.dismiss}}
                @title="banner.close"
                class="btn btn-flat close"
              />
            </div>

            {{#each @controller.banner as |row|}}
              <p>{{htmlSafe row}}</p>
            {{/each}}
          </div>
        </div>
      {{/if}}

      {{outlet}}
    </div>
  </template>
);
