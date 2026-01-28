export default async (_controller, _options = {}) => {
  const { default: SlashCommands } = await import('./extensions/slashCommands.js')
  const { default: suggestion } = await import('./suggestions/commands_options.js')

  const SlashCommandsExtension = [SlashCommands.configure({ suggestion })]

  return { SlashCommandsExtension }
}
