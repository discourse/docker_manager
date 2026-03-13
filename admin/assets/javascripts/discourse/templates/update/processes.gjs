import Console from "../../components/docker-manager/console";

export default <template>
  <Console @output={{@controller.model.output}} />
</template>
