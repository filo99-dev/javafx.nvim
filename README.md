# javafx.nvim

A lightweight Neovim plugin that makes working on **JavaFX** projects faster. It handles the
repetitive parts of the FXML workflow: wiring controllers, generating `@FXML` boilerplate,
completing component tags, and running the app, so you can stay in the editor.

It works alongside your existing Java setup (`jdtls`, `nvim-java`, ...) and doesn't replace it.

## Features

- **FXML completion**
  - Type `<TextF` and get the matching JavaFX components. Accepting one also adds the
    `<?import ...?>` line for you.
  - Type `fx:controller="` and get fully qualified controller class names from your project.
- **Controller generation** from FXML: missing `@FXML` fields (from `fx:id`) and handler
  stubs (from `onAction="#save"`, `onMouseClicked="#..."`, and so on) are added, with the
  right event types and imports. Existing code is never duplicated.
- **Jump between FXML and controller** with one command.
- **Scaffold a new view**: creates `NameController.java` and `Name.fxml`, already linked.
- **Run the app** in a terminal split (Maven or Gradle, wrapper scripts detected).
- **Open in Scene Builder** straight from the current FXML file.

## Requirements

- Neovim **0.10+**
- A Maven or Gradle JavaFX project
  - Maven: [`javafx-maven-plugin`](https://github.com/openjfx/javafx-maven-plugin) (`javafx:run`)
  - Gradle: [`org.openjfx.javafxplugin`](https://github.com/openjfx/javafx-gradle-plugin) with `application` (`run`)
- Optional: [Scene Builder](https://gluonhq.com/products/scene-builder/), and
  [blink.cmp](https://github.com/Saghen/blink.cmp) or
  [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) for popup completion

## Installation

### lazy.nvim

```lua
{
  "YOUR_USERNAME/javafx.nvim",
  lazy = false, -- the plugin registers the .fxml filetype, so don't lazy-load on ft
  opts = {
    mappings = true, -- optional <leader>j* keymaps, see below
  },
}
```

### Completion setup

FXML completion works without any extra plugin through omnifunc (`<C-x><C-o>`). For popup
completion, enable the `javafx` source in your completion plugin.

**blink.cmp** (the LazyVim default):

```lua
{
  "saghen/blink.cmp",
  opts = function(_, opts)
    opts.sources = opts.sources or {}
    opts.sources.default = vim.list_extend(opts.sources.default or {}, { "javafx" })
    opts.sources.providers = opts.sources.providers or {}
    opts.sources.providers.javafx = { name = "JavaFX", module = "javafx.blink" }
  end,
},
```

**nvim-cmp:** add `{ name = "javafx" }` to your `sources`.

## Commands

| Command | Description |
|---|---|
| `:JavaFXRun` | Run the app: `mvnw`/`mvn javafx:run` or `gradlew`/`gradle run`, in a terminal split |
| `:JavaFXStop` | Stop the running app |
| `:JavaFXToggle` | Jump between an FXML file and its controller (via `fx:controller`) |
| `:JavaFXInject` | Add missing `@FXML` fields and handler stubs (plus imports) to the controller |
| `:JavaFXNew Name [package]` | Create `NameController.java` and `Name.fxml`; prompts for the package if omitted |
| `:JavaFXSceneBuilder [file]` | Open the FXML in Scene Builder |

### Keymaps

Disabled by default. Set `mappings = true` to get:

| Key | Command |
|---|---|
| `<leader>jr` | `:JavaFXRun` |
| `<leader>jx` | `:JavaFXStop` |
| `<leader>jt` | `:JavaFXToggle` |
| `<leader>ji` | `:JavaFXInject` |
| `<leader>js` | `:JavaFXSceneBuilder` |

## Usage

**Create a new view**

```
:JavaFXNew Login com.acme.ui
```

This creates `src/main/java/com/acme/ui/LoginController.java` and
`src/main/resources/com/acme/ui/Login.fxml`, with `fx:controller` already set.

**Build the UI, then generate the controller code**

1. In the FXML, type `<Button`, `<TextField`, `<VBox`, and accept the suggestions. Imports are added automatically.
2. Add `fx:id="loginBtn"` and `onAction="#onLogin"` to a button.
3. Run `:JavaFXInject`. The controller now contains:

```java
@FXML
private Button loginBtn;

@FXML
private void onLogin(ActionEvent event) {
    // TODO
}
```

Run it again whenever the FXML changes; only missing members are added.

## Configuration

Defaults, all optional:

```lua
require("javafx").setup({
  scene_builder = nil,              -- path to the Scene Builder executable (auto-detected if nil)
  run_split = "botright 15split",   -- how the run terminal opens
  maven_goal = "javafx:run",
  gradle_task = "run",
  source_roots = { "src/main/java" },
  resource_roots = { "src/main/resources" },
  controllers_only = true,          -- fx:controller completion: only classes ending in controller_suffix
  controller_suffix = "Controller",
  save_before_run = true,
  mappings = false,
})
```

## Limitations

- Generated fields use the raw component type (`ComboBox`, not `ComboBox<String>`), because
  FXML doesn't carry generic information.
- Component completion covers the standard JavaFX controls, layouts, shapes, charts, and a few
  effects. Custom components and third-party libraries (ControlsFX, etc.) are not suggested yet.
- Attribute and property-tag completion (`fx:id`, `onAction`, `<children>`, ...) is not
  implemented yet.
- Java language features (completion, diagnostics, refactoring) come from your Java LSP.
- Controller lookup assumes the standard Maven/Gradle layout; adjust `source_roots` and
  `resource_roots` if yours differs.

## Roadmap

- [ ] Completion for custom components found in the project
- [ ] Attribute completion (`fx:id`, event handlers, common properties)
- [ ] Property-tag completion (`<children>`, `<padding>`, `<columnConstraints>`, ...)
- [ ] Complete `onAction="#` from methods in the controller
- [ ] Diagnostics for FXML that references missing controllers or handlers
- [ ] Tests with sample FXML projects

## Contributing

Issues and pull requests are welcome. To work on the plugin locally, point your plugin manager
at your clone:

```lua
{ dir = "~/projects/javafx.nvim", name = "javafx.nvim", lazy = false, opts = {} }
```

Please format Lua code with [StyLua](https://github.com/JohnnyMorganz/StyLua) and keep pull
requests small and focused. If you're reporting a bug, including the FXML snippet that triggers
it helps a lot.

### Project layout

```
plugin/javafx.lua          filetype, omnifunc, autocmds
lua/javafx/init.lua        config and setup()
lua/javafx/commands.lua    user commands
lua/javafx/fxml.lua        FXML parser (no Neovim API, easy to test)
lua/javafx/controller.lua  toggle and inject logic
lua/javafx/complete.lua    completion engine (controllers and components)
lua/javafx/components.lua  JavaFX component list
lua/javafx/blink.lua       blink.cmp source
lua/javafx/cmp.lua         nvim-cmp source
lua/javafx/run.lua         run/stop
lua/javafx/new.lua         view scaffolding
lua/javafx/scenebuilder.lua
```

## License

MIT. See [LICENSE](LICENSE).
