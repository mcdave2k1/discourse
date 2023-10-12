import { click, fillIn, visit } from "@ember/test-helpers";
import { toggleCheckDraftPopup } from "discourse/services/composer";
import { cloneJSON } from "discourse-common/lib/object";
import TopicFixtures from "discourse/tests/fixtures/topic";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import selectKit from "discourse/tests/helpers/select-kit-helper";
import { test } from "qunit";

acceptance("Composer Form Template", function (needs) {
  needs.user({
    id: 5,
    username: "kris",
    whisperer: true,
  });
  needs.settings({
    experimental_form_templates: true,
    general_category_id: 1,
    default_composer_category: 1,
  });
  needs.site({
    can_tag_topics: true,
    categories: [
      {
        id: 1,
        name: "General",
        slug: "general",
        permission: 1,
        topic_template: null,
        form_template_ids: [1],
      },
      {
        id: 2,
        name: "test too",
        slug: "test-too",
        permission: 1,
        topic_template: "",
      },
    ],
  });
  needs.pretender((server, helper) => {
    server.put("/u/kris.json", () => helper.response({ user: {} }));

    server.get("/form-templates/1.json", () => {
      return helper.response({
        form_template: {
          name: "Testing",
          template: `- type: input
  id: full-name
  attributes:
    label: "Full name"
  description: "What is your full name?"
- type: textarea
  id: description
  attributes:
    label: "Description"`,
        },
      });
    });

    server.get("/posts/419", () => {
      return helper.response({ id: 419 });
    });
    server.get("/composer/mentions", () => {
      return helper.response({
        users: [],
        user_reasons: {},
        groups: { staff: { user_count: 30 } },
        group_reasons: {},
        max_users_notified_per_group_mention: 100,
      });
    });
    server.get("/t/960.json", () => {
      const topicList = cloneJSON(TopicFixtures["/t/9/1.json"]);
      topicList.post_stream.posts[2].post_type = 4;
      return helper.response(topicList);
    });
  });

  needs.hooks.afterEach(() => toggleCheckDraftPopup(false));

  test("Composer Form Template is shrank and reopened", async function (assert) {
    await visit("/");
    await click("#create-topic");

    assert.strictEqual(selectKit(".category-chooser").header().value(), "1");

    assert.ok(
      document.querySelector("#reply-control").classList.contains("open"),
      "reply control is open"
    );

    await fillIn(".form-template-field__input[name='full-name']", "John Smith");

    await fillIn(
      ".form-template-field__textarea[name='description']",
      "Community manager"
    );

    await click(".toggle-minimize");

    assert.ok(
      document.querySelector("#reply-control").classList.contains("draft"),
      "reply control is minimized into draft mode"
    );

    await click(".toggle-fullscreen");

    assert.ok(
      document.querySelector("#reply-control").classList.contains("open"),
      "reply control is opened from draft mode"
    );

    assert.strictEqual(
      document.querySelector(".form-template-field__input[name='full-name']")
        .value,
      "John Smith",
      "keeps the value of the input field when composer is re-opened from draft mode"
    );

    assert.strictEqual(
      document.querySelector(
        ".form-template-field__textarea[name='description']"
      ).value,
      "Community manager",
      "keeps the value of the textarea field when composer is re-opened from draft mode"
    );
  });
});
