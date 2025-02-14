import Component from "@glimmer/component";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { inject as service } from "@ember/service";
import DInlineFloat from "float-kit/components/d-inline-float";
import { TOOLTIP } from "float-kit/lib/constants";
import and from "truth-helpers/helpers/and";

export default class DInlineTooltip extends Component {
  @service tooltip;

  <template>
    {{! template-lint-disable modifier-name-case }}
    <div
      id={{TOOLTIP.portalOutletId}}
      {{didInsert this.tooltip.registerPortalOutletElement}}
    ></div>

    <DInlineFloat
      @instance={{this.tooltip.activeTooltip}}
      @portalOutletElement={{this.tooltip.portalOutletElement}}
      @trapTab={{and
        this.tooltip.activeTooltip.options.interactive
        this.tooltip.activeTooltip.options.trapTab
      }}
      @mainClass="fk-d-tooltip"
      @innerClass="fk-d-tooltip__inner-content"
      @role="tooltip"
      @inline={{@inline}}
    />
  </template>
}
