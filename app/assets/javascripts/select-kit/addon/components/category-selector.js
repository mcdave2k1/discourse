import { computed } from "@ember/object";
import { mapBy } from "@ember/object/computed";
import Category from "discourse/models/category";
import { makeArray } from "discourse-common/lib/helpers";
import MultiSelectComponent from "select-kit/components/multi-select";

export default MultiSelectComponent.extend({
  pluginApiIdentifiers: ["category-selector"],
  classNames: ["category-selector"],
  categories: null,
  blockedCategories: null,

  selectKitOptions: {
    filterable: true,
    allowAny: false,
    allowUncategorized: true,
    displayCategoryDescription: false,
    selectedChoiceComponent: "selected-choice-category",
  },

  init() {
    this._super(...arguments);

    if (!this.categories) {
      this.set("categories", []);
    }
    if (!this.blockedCategories) {
      this.set("blockedCategories", []);
    }
  },

  content: computed("categories.[]", "blockedCategories.[]", function () {
    const blockedCategories = makeArray(this.blockedCategories);
    return Category.list().filter((category) => {
      if (category.isUncategorizedCategory) {
        if (this.attrs.options?.allowUncategorized !== undefined) {
          return this.attrs.options.allowUncategorized;
        }

        return this.selectKit.options.allowUncategorized;
      }

      return (
        this.categories.includes(category) ||
        !blockedCategories.includes(category)
      );
    });
  }),

  value: mapBy("categories", "id"),

  modifyComponentForRow() {
    return "category-row";
  },

  async search(filter) {
    return this.siteSettings.lazy_load_categories
      ? await Category.asyncSearch(filter, {
          includeUncategorized:
            this.attrs.options?.allowUncategorized !== undefined
              ? this.attrs.options.allowUncategorized
              : this.selectKit.options.allowUncategorized,
          selectCategoryIds: this.categories
            ? this.categories.map((x) => x.id)
            : null,
          rejectCategoryIds: this.blockedCategories
            ? this.blockedCategories.map((x) => x.id)
            : null,
        })
      : this._super(filter);
  },

  select(value, item) {
    if (item.multiCategory) {
      const items = item.multiCategory.map((id) =>
        Category.findById(parseInt(id, 10))
      );

      const newValues = makeArray(this.value).concat(items.map((i) => i.id));
      const newContent = makeArray(this.selectedContent).concat(items);

      this.selectKit.change(newValues, newContent);
    } else {
      this._super(value, item);
    }
  },

  actions: {
    onChange(values) {
      this.attrs.onChange(
        values.map((v) => Category.findById(v)).filter(Boolean)
      );
      return false;
    },
  },
});
