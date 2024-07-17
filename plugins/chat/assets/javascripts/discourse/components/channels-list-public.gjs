import Component from "@glimmer/component";
import { hash } from "@ember/helper";
import { action } from "@ember/object";
import { LinkTo } from "@ember/routing";
import { service } from "@ember/service";
import { and } from "truth-helpers";
import PluginOutlet from "discourse/components/plugin-outlet";
import concatClass from "discourse/helpers/concat-class";
import dIcon from "discourse-common/helpers/d-icon";
import i18n from "discourse-common/helpers/i18n";
import EmptyChannelsList from "discourse/plugins/chat/discourse/components/empty-channels-list";
import ChatChannelRow from "./chat-channel-row";

export default class ChannelsListPublic extends Component {
  @service chatChannelsManager;
  @service chatStateManager;
  @service chatTrackingStateManager;
  @service site;
  @service siteSettings;
  @service currentUser;
  @service router;

  get inSidebar() {
    return this.args.inSidebar ?? false;
  }

  get publicMessageChannelsEmpty() {
    return (
      this.chatChannelsManager.publicMessageChannels?.length === 0 &&
      this.chatStateManager.hasPreloadedChannels
    );
  }

  get displayPublicChannels() {
    if (!this.siteSettings.enable_public_channels) {
      return false;
    }

    if (!this.chatStateManager.hasPreloadedChannels) {
      return false;
    }

    if (this.publicMessageChannelsEmpty) {
      return (
        this.currentUser?.staff ||
        this.currentUser?.has_joinable_public_channels
      );
    }

    return true;
  }

  get hasUnreadThreads() {
    return this.chatTrackingStateManager.hasUnreadThreads;
  }

  get hasThreadedChannels() {
    return this.chatChannelsManager.hasThreadedChannels;
  }

  @action
  toggleChannelSection(section) {
    this.args.toggleSection(section);
  }

  @action
  openBrowseChannels() {
    this.router.transitionTo("chat.browse");
  }

  <template>
    {{#if (and this.site.desktopView this.inSidebar this.hasThreadedChannels)}}
      <LinkTo @route="chat.threads" class="chat-channel-row --threads">
        <span class="chat-channel-title">
          {{dIcon "discourse-threads" class="chat-user-threads__icon"}}
          {{i18n "chat.my_threads.title"}}
        </span>
        {{#if this.hasUnreadThreads}}
          <div class="c-unread-indicator">
            <div class="c-unread-indicator__number">&nbsp;</div>
          </div>
        {{/if}}
      </LinkTo>
    {{/if}}

    <div
      id="public-channels"
      class={{concatClass
        "channels-list-container"
        "public-channels"
        (if this.inSidebar "collapsible-sidebar-section")
      }}
    >
      {{#if this.publicMessageChannelsEmpty}}
        <EmptyChannelsList
          @title={{i18n "chat.no_public_channels"}}
          @ctaTitle={{i18n "chat.no_public_channels_cta"}}
          @ctaAction={{this.openBrowseChannels}}
          @showCTA={{this.displayPublicChannels}}
        />
      {{else}}
        {{#each this.chatChannelsManager.publicMessageChannels as |channel|}}
          <ChatChannelRow
            @channel={{channel}}
            @options={{hash settingsButton=true}}
          />
        {{/each}}
      {{/if}}
    </div>

    <PluginOutlet
      @name="below-public-chat-channels"
      @tagName=""
      @outletArgs={{hash inSidebar=this.inSidebar}}
    />
  </template>
}
