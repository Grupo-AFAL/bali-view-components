import SlashCommands from './extensions/slashCommands'
import suggestion from './suggestions/commands_options'

export default (_controller, _options = {}) => {
  const SlashCommandsExtension = [SlashCommands.configure({ suggestion })]

  return { SlashCommandsExtension }
}
