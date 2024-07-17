import Component from "@glimmer/component";
import { hash } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import PluginOutlet from "discourse/components/plugin-outlet";
import i18n from "discourse-common/helpers/i18n";
import ChatModalNewMessage from "discourse/plugins/chat/discourse/components/chat/modal/new-message";
import EmptyChannelsList from "discourse/plugins/chat/discourse/components/empty-channels-list";
import ChatChannelRow from "./chat-channel-row";

export default class ChannelsListDirect extends Component {
  @service chat;
  @service chatChannelsManager;
  @service site;
  @service modal;

  get inSidebar() {
    return this.args.inSidebar ?? false;
  }

  get createDirectMessageChannelLabel() {
    if (!this.canCreateDirectMessageChannel) {
      return "chat.direct_messages.cannot_create";
    }

    return "chat.direct_messages.new";
  }

  get showDirectMessageChannels() {
    return (
      this.canCreateDirectMessageChannel || !this.directMessageChannelsEmpty
    );
  }

  get canCreateDirectMessageChannel() {
    return this.chat.userCanDirectMessage;
  }

  get directMessageChannelClasses() {
    return `channels-list-container direct-message-channels ${
      this.inSidebar ? "collapsible-sidebar-section" : ""
    }`;
  }

  get directMessageChannelsEmpty() {
    return this.chatChannelsManager.directMessageChannels?.length === 0;
  }

  @action
  toggleChannelSection(section) {
    this.args.toggleSection(section);
  }

  @action
  openNewMessageModal() {
    this.modal.show(ChatModalNewMessage);
  }

  <template>
    <PluginOutlet
      @name="below-direct-chat-channels"
      @tagName=""
      @outletArgs={{hash inSidebar=this.inSidebar}}
    />

    <div
      id="direct-message-channels"
      class={{this.directMessageChannelClasses}}
    >
      {{#if this.directMessageChannelsEmpty}}
        <EmptyChannelsList
          @title={{i18n "chat.no_direct_message_channels"}}
          @ctaTitle={{i18n "chat.no_direct_message_channels_cta"}}
          @ctaAction={{this.openNewMessageModal}}
          @showCTA={{this.canCreateDirectMessageChannel}}
        />
      {{else}}
        {{#each
          this.chatChannelsManager.truncatedDirectMessageChannels
          as |channel|
        }}
          <ChatChannelRow
            @channel={{channel}}
            @options={{hash leaveButton=true}}
          />
        {{/each}}
      {{/if}}
    </div>
  </template>
}
