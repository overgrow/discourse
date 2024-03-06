import Component from "@glimmer/component";
import { cached, tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { popupAjaxError } from "discourse/lib/ajax-error";
import TopicTimer from "discourse/models/topic-timer";
import I18n from "discourse-i18n";
import { FORMAT } from "select-kit/components/future-date-input-selector";

export const CLOSE_STATUS_TYPE = "close";
export const CLOSE_AFTER_LAST_POST_STATUS_TYPE = "close_after_last_post";
export const OPEN_STATUS_TYPE = "open";
export const PUBLISH_TO_CATEGORY_STATUS_TYPE = "publish_to_category";
export const DELETE_STATUS_TYPE = "delete";
export const BUMP_TYPE = "bump";
export const DELETE_REPLIES_TYPE = "delete_replies";

export default class EditTopicTimer extends Component {
  @service currentUser;

  @tracked loading = false;
  @tracked flash;

  constructor() {
    super(...arguments);

    // if (!this.topicTimer) {
    //   this.createDefaultTimer();
    // }
  }

  get topic() {
    return this.args.model.topic;
  }

  get topicTimer() {
    return this.topic.topic_timer;
  }

  @cached
  get publicTimerTypes() {
    const types = [];

    if (this.topic.closed) {
      types.push({
        id: OPEN_STATUS_TYPE,
        name: I18n.t("topic.auto_reopen.title"),
      });
    } else {
      types.push({
        id: CLOSE_STATUS_TYPE,
        name: I18n.t("topic.auto_close.title"),
      });
      types.push({
        id: CLOSE_AFTER_LAST_POST_STATUS_TYPE,
        name: I18n.t("topic.auto_close_after_last_post.title"),
      });
    }

    if (this.topic.details.can_delete) {
      types.push({
        id: DELETE_STATUS_TYPE,
        name: I18n.t("topic.auto_delete.title"),
      });
    }

    types.push({
      id: BUMP_TYPE,
      name: I18n.t("topic.auto_bump.title"),
    });

    if (this.topic.details.can_delete) {
      types.push({
        id: DELETE_REPLIES_TYPE,
        name: I18n.t("topic.auto_delete_replies.title"),
      });
    }

    if (this.topic.closed) {
      types.push({
        id: CLOSE_STATUS_TYPE,
        name: I18n.t("topic.temp_open.title"),
      });
    } else {
      types.push({
        id: OPEN_STATUS_TYPE,
        name: I18n.t("topic.temp_close.title"),
      });
    }

    if (
      this.topic.category?.read_restricted ||
      this.topic.isPrivateMessage ||
      this.topic.invisible
    ) {
      types.push({
        id: PUBLISH_TO_CATEGORY_STATUS_TYPE,
        name: I18n.t("topic.publish_to_category.title"),
      });
    }

    return types;
  }

  async setTimer(
    statusType,
    time,
    durationMinutes,
    basedOnLastPost,
    categoryId
  ) {
    this.loading = true;

    try {
      const result = await TopicTimer.update(
        this.topic.id,
        time,
        basedOnLastPost,
        statusType,
        categoryId,
        durationMinutes
      );

      if (time || durationMinutes) {
        this.topicTimer.setProperties({
          execute_at: result.execute_at,
          duration_minutes: result.duration_minutes,
          category_id: result.category_id,
          closed: result.closed,
        });
        this.args.closeModal();
      } else {
        this.createDefaultTimer();
        this.topicTimer.set("time", null);
      }
    } catch (e) {
      popupAjaxError(e);
    } finally {
      this.loading = false;
    }
  }

  createDefaultTimer() {
    const defaultTimer = TopicTimer.create({
      status_type: this.publicTimerTypes[0].id,
    });
    this.topic.set("topic_timer", defaultTimer);
    return defaultTimer;
  }

  @action
  onChangeStatusType(value) {
    const basedOnLastPost = CLOSE_AFTER_LAST_POST_STATUS_TYPE === value;
    this.topicTimer.based_on_last_post = basedOnLastPost;
    this.topicTimer.set("based_on_last_post", basedOnLastPost);
    this.topicTimer.status_type = value;
    this.topicTimer.set("status_type", value);
  }

  @action
  onChangeInput(_, time) {
    this.topicTimer.set(
      "time",
      moment.isMoment(time) ? time.format(FORMAT) : time
    );
  }

  @action
  async saveTimer() {
    this.flash = null;

    if (!this.topicTimer.time && !this.topicTimer.duration_minutes) {
      this.flash = I18n.t("topic.topic_status_update.time_frame_required");
      return;
    }

    if (this.topicTimer.duration_minutes && !this.topicTimer.time) {
      if (this.topicTimer.duration_minutes <= 0) {
        this.flash = I18n.t("topic.topic_status_update.min_duration");
        return;
      }

      // cannot be more than 20 years
      if (this.topicTimer.duration_minutes > 20 * 365 * 1440) {
        this.flash = I18n.t("topic.topic_status_update.max_duration");
        return;
      }
    }

    let statusType = this.topicTimer.status_type;
    if (statusType === CLOSE_AFTER_LAST_POST_STATUS_TYPE) {
      statusType = CLOSE_STATUS_TYPE;
    }

    await this.setTimer(
      statusType,
      this.topicTimer.time,
      this.topicTimer.duration_minutes,
      this.topicTimer.based_on_last_post,
      this.topicTimer.category_id
    );
  }

  @action
  async removeTimer() {
    let statusType = this.topicTimer.status_type;
    if (statusType === CLOSE_AFTER_LAST_POST_STATUS_TYPE) {
      statusType = CLOSE_STATUS_TYPE;
    }
    await this.setTimer(statusType);
    // timer has been removed and we are removing `execute_at`
    // which will hide the remove timer button from the modal
    this.topicTimer.execute_at = null;
  }
}
