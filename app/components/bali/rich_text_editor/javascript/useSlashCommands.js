export default async (_controller, _options = {}) => {
  const { default: SlashCommands } = await import('./extensions/slashCommands')
  const { default: suggestion } = await import('./suggestions/commands_options')

  const SlashCommandsExtension = [SlashCommands.configure({ suggestion })]

  return { SlashCommandsExtension }
}
