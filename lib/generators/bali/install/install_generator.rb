# frozen_string_literal: true

require "json"

module Bali
  # Wires Bali into a host application: the Tailwind imports, the initializer, the
  # Stimulus registration and the npm dependencies.
  #
  #   bin/rails g bali:install
  #   bin/rails g bali:install --block-editor
  #
  # WHAT IT WRITES IS WHAT THE FLEET AGREES ON, and that was measured rather than
  # guessed. Across the seven applications using Bali, `application.css` shares
  # exactly three substantive lines, `config/initializers/bali.rb` shares exactly
  # one, and `controllers/index.js` shares `registerAll` + `registerCharts`.
  # Everything else diverges — the AFAL theme alone is done four different ways —
  # so this generator writes the shared part and SAYS the rest. Guessing at the
  # divergent part would only add an eighth way of doing it.
  #
  # EVERY CHUNK IS PAIRED WITH WHAT "ALREADY THERE" LOOKS LIKE IN THE WILD, never
  # with the generator's own spelling of it. That is the whole difference between
  # a generator and a snippet in a guide, and it is also where the first version
  # of this file broke six of the seven apps: the CSS half matched daisyUI's block
  # form with a regex, while the JavaScript and package.json halves searched for
  # the literal text they would have written. Five apps import `registerAll`
  # alongside a second symbol, identity imports it under an alias from an internal
  # path, and all seven keep `daisyui` in `devDependencies` — none of which the
  # literal search found, so it wrote a second `registerAll` (`The symbol
  # "registerAll" has already been declared`, `yarn build` dead) and a second
  # `daisyui` with a different range. Detection is structural now: bindings for
  # JavaScript, every dependency section for npm, a pattern for CSS.
  #
  # It targets the esbuild/bundler layout, which is what all seven use. A Vite
  # application gets the same files; an importmap one gets the Ruby and CSS halves
  # and is told what the JavaScript half needs, because Bali ships ESM source — 91
  # modules reachable from the root entry, importing their peers by bare specifier
  # (counted with an esbuild metafile) — rather than one pinnable file.
  #
  # No `templates/` directory, unlike bali_auth:install: every chunk below has to
  # serve two callers — creating the file and injecting into one the host already
  # wrote — and a template would mean keeping the same explanatory comment in two
  # places, free to drift.
  #
  # TWO `bali:install`s SHARE A PREFIX AND DO DIFFERENT THINGS:
  #
  #   bin/rails g bali:install                       this generator: CSS, initializer,
  #                                                  Stimulus registration, npm deps
  #   bin/rails bali:install:migrations              the rake tasks the Rails engine API
  #   bin/rails bali:install:migrations:saved_views  generates — all of them, or one of the
  #                                                  six per-feature ones — copying
  #                                                  db/migrate/* into the host
  #
  # The generator deliberately copies no migrations: the engine's tables belong to
  # the features that use them (saved views, content versions, dashboard widgets and
  # three more), only three of the seven apps mount the engine at all, and a
  # generator that installed tables for the other four would be writing schema
  # nobody asked for. Forgetting the `g` is not silent — measured:
  # `Unrecognized command "bali:install"` followed by
  # `Did you mean?  bali:install:migrations`.
  class InstallGenerator < Rails::Generators::Base
    desc "Wire Bali into this app: Tailwind imports, initializer, Stimulus registration, npm deps"

    CSS_PATH = "app/assets/tailwind/application.css"
    INITIALIZER_PATH = "config/initializers/bali.rb"
    JAVASCRIPT_PATHS = [ "app/javascript/controllers/index.js", "app/javascript/application.js" ].freeze

    TAILWIND_IMPORT = '@import "tailwindcss";'
    ENGINE_BRIDGE = '@import "../builds/tailwind/bali";'
    BALI_CSS_IMPORT = '@import "bali-view-components/css/bali.css";'
    FORM_BUILDER_LINE =
      'Rails.application.config.action_view.default_form_builder = "Bali::FormBuilder"'

    # The Block Editor already defaults to `false` in lib/bali.rb, so this flag
    # turns it ON — it does not, as the issue that asked for it assumed, turn off
    # something that ships enabled. There is deliberately no `--rich-text-editor`
    # twin: that editor is deprecated in v3 and gone in v4, and a flag is public
    # surface with a known expiry date. A host that still needs it writes the one
    # line the closing notes print.
    class_option :block_editor, type: :boolean, default: false,
                                desc: "Enable Bali::BlockEditor and add the @blocknote/* packages"
    class_option :skip_css, type: :boolean, default: false,
                            desc: "Leave #{CSS_PATH} alone"
    class_option :skip_initializer, type: :boolean, default: false,
                                    desc: "Leave #{INITIALIZER_PATH} alone"
    class_option :skip_javascript, type: :boolean, default: false,
                                   desc: "Leave the Stimulus index alone"
    class_option :skip_package_json, type: :boolean, default: false,
                                     desc: "Leave package.json alone"

    def add_css_imports
      return if options[:skip_css]
      return create_file(CSS_PATH, "#{TAILWIND_IMPORT}\n#{chunks_of(css_chunks)}") unless exist?(CSS_PATH)

      css = read(CSS_PATH)
      missing = chunks_of(css_chunks.reject { |present, _| css.match?(present) })
      return say_status(:identical, CSS_PATH, :blue) if missing.empty?

      if (anchor = css_anchor(css))
        inject_into_file CSS_PATH, missing, after: "#{anchor}\n"
      else
        # No `@import "tailwindcss"` to sit behind. Prepending it is the only order
        # that works — see the comment the chunk itself carries.
        prepend_to_file CSS_PATH, "#{TAILWIND_IMPORT}\n#{missing}"
      end
    end

    def create_initializer
      return if options[:skip_initializer]
      unless exist?(INITIALIZER_PATH)
        return create_file(INITIALIZER_PATH,
                           "# frozen_string_literal: true\n#{chunks_of(initializer_chunks)}")
      end

      existing = read(INITIALIZER_PATH)
      missing = chunks_of(initializer_chunks.reject { |present, _| existing.match?(present) })
      return say_status(:identical, INITIALIZER_PATH, :blue) if missing.empty?

      append_to_file INITIALIZER_PATH, missing
    end

    def register_controllers
      return if options[:skip_javascript]

      path = JAVASCRIPT_PATHS.find { |candidate| exist?(candidate) }
      return @javascript_by_hand = true unless path

      javascript = code_of(read(path))
      imports = []
      calls = []

      javascript_wiring.each do |symbol, specifier|
        locals = bali_bindings(javascript)[symbol]
        imports << %(import { #{symbol} } from "#{specifier}") if locals.empty?
        locals = [ symbol ] if locals.empty?
        calls << "#{locals.first}(application)" if locals.none? { |local| called?(javascript, local) }
      end
      return say_status(:identical, path, :blue) if imports.empty? && calls.empty?

      warn_about_missing_application(path, javascript)
      insert_imports(path, javascript, imports)
      append_to_file path, "\n#{calls.join("\n")}\n" if calls.any?
    end

    # Written, not installed: a generator that runs the package manager on the
    # host's behalf leaves the lockfile saying something the host never chose.
    def add_npm_dependencies
      return if options[:skip_package_json]
      return @javascript_by_hand = true unless exist?("package.json")

      package = JSON.parse(read("package.json"))
      warn_about_a_stale_pin(package)
      added = npm_dependencies.except(*declared_packages(package))
      return say_status(:identical, "package.json", :blue) if added.empty?

      package["dependencies"] = (package["dependencies"] || {}).merge(added).sort.to_h
      create_file "package.json", "#{JSON.pretty_generate(package)}\n", force: true
      say_status :update, "package.json — added #{added.keys.join(', ')}", :green
    end

    def print_next_steps
      say ""
      say "Bali is wired in. Two commands and a few decisions left:", :green
      say ""
      say "  1. #{package_manager} install            # the dependencies just written"
      say "  2. bin/rails tailwindcss:build"
      say ""
      say_the_javascript_lines if @javascript_by_hand
      say_what_it_deliberately_left_out
    end

    private

    def exist?(path) = File.exist?(File.join(destination_root, path))
    def read(path) = File.read(File.join(destination_root, path))

    # ---- CSS -------------------------------------------------------------

    # daisyUI first, then Bali. The plugin is not a theming nicety: the Ruby
    # components emit daisyUI class names, so without it they render UNSTYLED, not
    # merely unthemed — which is why package.json calls it a required peer. All
    # seven applications carry the directive; only the themes inside the block
    # differ, and that block is theirs to write.
    # Each chunk is paired with what "already here" looks like, rather than grepping
    # the chunk's own text for it. Six of the seven applications write the plugin as
    # `@plugin "daisyui" { themes: ... }`, which a search for the bare `@plugin
    # "daisyui";` would miss — and the generator would then add a second one.
    def css_chunks
      [
        [ /^@plugin\s+["']daisyui["']/, daisyui_chunk ],
        [ %r{^@import\s+["']\.\./builds/tailwind/bali["']}, engine_bridge_chunk ],
        [ %r{^@import\s+["']bali-view-components/css/bali\.css["']}, bali_css_chunk ]
      ]
    end

    def chunks_of(pairs) = pairs.map(&:last).join

    # THE ORDER MATTERS, and not for the reason usually given. `@import
    # "tailwindcss"` is the line that emits `@layer theme, base, components,
    # utilities`; anything of Bali's placed before it lands outside the cascade
    # Tailwind sets up. It is NOT about winning against daisyUI — daisyUI 5 emits
    # its components inside `@layer utilities` and outranks `@layer components` by
    # design, whichever order the imports are in.
    def engine_bridge_chunk
      <<~CSS

        /* Bali's Tailwind sources. This is a bridge, NOT a `@source` glob, and the
           difference is the failure mode: the gem installs outside your project, at a
           path that differs per machine, and a `@source` that matches nothing does not
           fail — it silently drops every Bali class from the build. So the gem ships
           app/assets/tailwind/bali/engine.css with its globs relative to itself, and
           tailwindcss-rails (>= 4.3) writes app/assets/builds/tailwind/bali.css pointing
           at wherever Bundler put the gem, before every tailwindcss:build,
           tailwindcss:watch and assets:precompile. One import, nothing to keep in sync,
           and never write the glob yourself.

           Without tailwindcss-rails, import the same file from the npm package instead:
           @import "bali-view-components/tailwind/engine.css";

           After `@import "tailwindcss"` because that line emits the `@layer theme, base,
           components, utilities` statement this and everything below rely on. */
        #{ENGINE_BRIDGE}
      CSS
    end

    def bali_css_chunk
      <<~CSS

        /* Bali's own CSS. One line: base styles, forms, typography and every component
           sheet come with it. */
        #{BALI_CSS_IMPORT}
      CSS
    end

    def daisyui_chunk
      <<~CSS

        /* daisyUI. Bali's components emit its class names from Ruby, so without the
           plugin they render unstyled rather than merely unthemed. Add your themes in a
           block here: @plugin "daisyui" { themes: light --default, dark; } */
        @plugin "daisyui";
      CSS
    end

    # The last `@plugin` directive (block form or not), else the Tailwind import.
    def css_anchor(css)
      plugins = css.to_enum(:scan, /^@plugin\b[^;{]*(?:\{[^}]*\}|;)/m).map { Regexp.last_match[0] }
      return plugins.last if plugins.any?

      css[/^@import\s+["']tailwindcss["'];/]
    end

    # ---- Initializer -----------------------------------------------------

    # The pattern is the ASSIGNMENT, not this generator's spelling of the whole
    # line: an app that set the builder inside a `Rails.application.configure` block
    # wrote `config.action_view.default_form_builder = ...` and already has it.
    def initializer_chunks
      chunks = [
        [ /^\s*(?:Rails\.application\.)?config\.action_view\.default_form_builder\s*=/,
          form_builder_chunk ]
      ]
      chunks << [ /^Bali\.block_editor_enabled/, block_editor_chunk ] if options[:block_editor]
      chunks
    end

    def form_builder_chunk
      <<~RUBY

        # Every form in the app is a Bali form, without `builder:` on each call. The one
        # line all seven applications using Bali already share.
        #
        # Through `config.action_view`, NOT `ActionView::Base.default_form_builder =`:
        # touching ActionView::Base from an initializer fires every `on_load(:action_view)`
        # hook before the autoloader is ready, which breaks engines that include helpers
        # there (bali-analytics does).
        #{FORM_BUILDER_LINE}
      RUBY
    end

    def block_editor_chunk
      <<~RUBY

        # Block Editor (BlockNote). Off by default because it needs the @blocknote/*
        # packages — `--block-editor` added them to package.json.
        Bali.block_editor_enabled = true

        # Uploads are DEFAULT-DENY: while this is nil the endpoint answers 403 and logs why.
        # This is the lambda both applications that enable the editor arrived at
        # independently; narrow it if your uploads need more than "signed in".
        Bali.block_editor_upload_authorize = ->(controller) { controller.current_user.present? }
      RUBY
    end

    # ---- JavaScript ------------------------------------------------------

    # A Bali entry point, however the host spells it. Six apps import the public
    # package (`bali-view-components`, `bali-view-components/charts`); identity
    # imports `bali/components`, `bali/controllers` and `bali/charts`, three esbuild
    # aliases onto paths inside the gem. Both are "already wired", and writing the
    # public import next to identity's aliases would register every controller twice.
    BALI_SPECIFIER = %r{\A(?:bali-view-components|bali)(?:/|\z)}

    # [symbol, specifier] — what a fully wired Stimulus index has.
    #
    # No `installConfirmDialog`: `registerAll` already installs it. The five
    # applications that call it anyway pass Spanish button labels, which is a
    # localisation choice no generator can make for an app it has not read.
    def javascript_wiring
      wiring = [
        [ "registerAll", "bali-view-components" ],
        [ "registerCharts", "bali-view-components/charts" ]
      ]
      wiring << [ "registerBlockEditor", "bali-view-components/block-editor" ] if options[:block_editor]
      wiring
    end

    # { imported symbol => [every name it is bound to here] }, over every named
    # import from a Bali specifier. `import { registerAll, installConfirmDialog }
    # from "bali-view-components"` (five apps) and `import { registerAll as
    # registerComponents } from "bali/components"` (identity) both answer
    # "registerAll is already imported", which a search for either literal line does
    # not. A LIST and not one name, because identity imports `registerAll` twice
    # under two aliases — components and controllers — and either call means wired.
    def bali_bindings(javascript)
      @bali_bindings ||= javascript.scan(/\bimport\s*\{([^}]*)\}\s*from\s*["']([^"']+)["']/m)
        .each_with_object(Hash.new { |bindings, key| bindings[key] = [] }) do |(clause, specifier), bindings|
          next unless BALI_SPECIFIER.match?(specifier)

          clause.split(",").each do |entry|
            symbol, local = entry.strip.split(/\s+as\s+/)
            bindings[symbol] << (local || symbol) if symbol.present?
          end
        end
    end

    # Under the host's own name for it: identity calls `registerComponents(application)`.
    def called?(javascript, local) = javascript.match?(/(?<![\w$.])#{Regexp.escape(local)}\s*\(/)

    # Comments are not code, and these files are full of prose about `registerAll`.
    def code_of(javascript)
      javascript.gsub(%r{/\*.*?\*/}m, "").lines.reject { |line| line.strip.start_with?("//") }.join
    end

    def insert_imports(path, javascript, imports)
      return if imports.empty?

      block = imports.map { |line| "#{line}\n" }.join
      anchor = javascript.scan(/^import .+$/).last

      anchor ? inject_into_file(path, block, after: "#{anchor}\n") : prepend_to_file(path, block)
    end

    def warn_about_missing_application(path, javascript)
      return if javascript.include?("application")

      say_status :warn, "#{path} never mentions `application` — point the register calls " \
                        "at your Stimulus application yourself", :yellow
    end

    # ---- npm -------------------------------------------------------------

    # Only what a bundler must resolve to build the app at all, which is exactly
    # what `peerDependencies` marks as non-optional.
    #
    # chart.js is deliberately NOT here, even though the line above wires
    # `registerCharts`: it is reached through a guarded `import()`, so the build
    # succeeds without it and the entry point still registers. An app that never
    # draws a chart should not carry it, and the closing notes say to add it the day
    # it does.
    def npm_dependencies
      bali_package.fetch("peerDependencies")
        .reject { |name, _| optional_peer?(name) }
        .merge("bali-view-components" => "github:Grupo-AFAL/bali-view-components#v#{Bali::VERSION}")
        .merge(options[:block_editor] ? peers(*BLOCK_EDITOR_PACKAGES) : {})
    end

    BLOCK_EDITOR_PACKAGES = %w[
      @blocknote/core @blocknote/mantine @blocknote/react @mantine/core @mantine/hooks
      react react-dom
    ].freeze

    # EVERY dependency section, not just `dependencies`. All seven applications keep
    # `daisyui` in `devDependencies`, which is where a build-time Tailwind plugin
    # belongs; a generator that reads only `dependencies` writes a second `daisyui`,
    # with a different range, into the same file.
    DEPENDENCY_SECTIONS = %w[
      dependencies devDependencies peerDependencies optionalDependencies
    ].freeze

    def declared_packages(package)
      DEPENDENCY_SECTIONS.flat_map { |section| (package[section] || {}).keys }
    end

    # THE ONE LINE THIS GENERATOR WILL NOT REWRITE, and the reason it can be re-run
    # after a bump without holding anything back. A pin is a decision: a tag, a
    # branch, or a `link:` to a local checkout while working on Bali itself. Moving
    # it silently would change what `yarn install` resolves on behalf of a host that
    # only asked for the wiring — so the mismatch is SAID, with both versions in it.
    # Measured against origin/main of the seven: six are pinned behind the current
    # gem (five at v3.3.0, costa-norte at v3.3.1) and only afal-apps is level.
    def warn_about_a_stale_pin(package)
      pin = DEPENDENCY_SECTIONS.filter_map { |s| package.dig(s, "bali-view-components") }.first
      return if pin.nil? || pin.start_with?("link:", "file:", "portal:")
      return if pin.include?("#v#{Bali::VERSION}")

      say_status :warn, "package.json pins bali-view-components at #{pin}, and this gem is " \
                        "v#{Bali::VERSION}. Move the pin yourself so the JavaScript and the " \
                        "Ruby are the same release", :yellow
    end

    # Version ranges come from Bali's own peerDependencies rather than being
    # invented here: they are what this version was built against, and a caret
    # guessed from a lower bound would pin a host to a major that has moved on.
    def peers(*names)
      bali_package.fetch("peerDependencies").slice(*names)
    end

    def optional_peer?(name)
      bali_package.fetch("peerDependenciesMeta").dig(name, "optional")
    end

    def bali_package
      @bali_package ||= JSON.parse(Bali::Engine.root.join("package.json").read)
    end

    def package_manager = exist?("yarn.lock") ? "yarn" : "npm"

    # ---- What it says instead of writing ---------------------------------

    def say_the_javascript_lines
      say "  No package.json or Stimulus index here: an importmap app, or a layout this", :yellow
      say "  generator does not recognise. The CSS and Ruby halves above are written; the", :yellow
      say "  JavaScript half needs a BUNDLER. Bali ships ESM source — 91 modules behind the", :yellow
      say "  root entry, importing their peers by bare specifier — not one pinnable file,", :yellow
      say "  so there is nothing for importmap to pin. Add jsbundling and re-run:", :yellow
      say ""
      say "    bundle add jsbundling-rails"
      say "    bin/rails javascript:install:esbuild"
      say "    bin/rails g bali:install"
      say ""
      say "  Vite resolves the same imports with no extra step; it may need the gem path"
      say "  allowed:  server: { fs: { allow: ['.', baliGemPath] } }  — then add by hand:"
      say ""
      javascript_wiring.each { |symbol, specifier| say %(    import { #{symbol} } from "#{specifier}") }
      javascript_wiring.each { |symbol, _| say "    #{symbol}(application)" }
      say ""
    end

    def say_what_it_deliberately_left_out
      say "Left to you, because the seven apps using Bali do these differently:"
      say ""
      say "  · The daisyUI themes, in the @plugin block:"
      say '      @plugin "daisyui" { themes: light --default, dark; }'
      say "  · The AFAL theme, if you want it:"
      say '      @import "bali-view-components/css/themes/afal.css";'
      say "  · Dark mode:"
      say "      @custom-variant dark (&:where([data-theme=dark], [data-theme=dark] *));"
      say "  · Markdown/rich text? Tailwind's typography plugin is yours, not Bali's —"
      say "    Bali only ships the patch that keeps prose-invert working under daisyUI:"
      say '      @plugin "@tailwindcss/typography";   (and yarn add -D @tailwindcss/typography)'
      say "  · Localised confirm buttons (registerAll already installs the dialog itself):"
      say '      installConfirmDialog({ acceptText: "Aceptar", cancelText: "Cancelar" })'
      say "  · Optional peers, per component you render — the build works without them and"
      say "    each one says so in the console when its component runs. Charts first:"
      say "      #{package_manager} add chart.js       # Bali::Chart, registered above"
      say "  · The TipTap rich text editor, DEPRECATED in v3 and removed in v4 (new work"
      say "    belongs on --block-editor). No flag for it; if you still need it:"
      say "      Bali.rich_text_editor_enabled = true   # in #{INITIALIZER_PATH}"
      say "  · The engine's tables, one feature at a time, only if you use them — a RAKE"
      say "    namespace that only shares the word, and the reason this generator writes"
      say "    no migrations:"
      say "      bin/rails bali:install:migrations:saved_views"
      say ""
    end
  end
end
