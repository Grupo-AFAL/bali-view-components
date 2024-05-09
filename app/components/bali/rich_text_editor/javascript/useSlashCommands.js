export default async (_controller, _options = {}) => {
  const { default: SlashCommands } = await import('bali/rich_text_editor/extensions/slashCommands')
  const { default: suggestion } = await import('bali/rich_text_editor/suggestions/commandsOptions')

  const SlashCommandsExtension = [SlashCommands.configure({ suggestion })]

  return { SlashCommandsExtension }
}
