# Typed Instance Components

Strictly typed argument builders for [React-Luau](https://github.com/jsdotlua/react-lua). Merge component props into a root Roblox instance without forwarding unrelated component fields.

```luau
return e(RobloxComponents.TextButton({
	Text = props.Label,
	[React.Event.Activated] = props.OnActivated,
}, props, {
	Corner = e(RobloxComponents.UICorner({ CornerRadius = UDim.new(0, 8) }, {})),
}))
```

The generated builders port `open-shl/scripts/util/generate-react-roblox-types.lune.luau`: a plain optional `Properties` record, a `VALID_PROPERTIES` table, an `append` function, and a builder returning **class/component, merged props, children**. There are no per-property generics, binding unions, or React-prop intersections.

## Install

The initial package version is `0.1.0`. The Wally declaration below becomes installable after the first release is published.

```toml
[dependencies]
React = "jsdotlua/react@17.2.1"
ReactRoblox = "jsdotlua/react-roblox@17.2.1"
TypedInstanceComponents = "nightcycle/typed-instance-components@0.1.0"
```

Run `wally install`, map `Packages` into your Rojo project, and run [wally-package-types](https://github.com/JohnnyMorganz/wally-package-types) against your sourcemap to expose exported type aliases through Wally's generated modules:

```sh
rojo sourcemap default.project.json --output sourcemap.json
wally-package-types --sourcemap sourcemap.json Packages
```

```luau
local Packages = game:GetService("ReplicatedStorage").Packages
local React = require(Packages.React)
local RobloxComponents = require(Packages.TypedInstanceComponents)
local TextButton = RobloxComponents.TextButton
local UICorner = RobloxComponents.UICorner

type Properties = RobloxComponents.TextButtonProperties & {
	Label: string,
	OnActivated: () -> (),
}
```

The package header requires every class module and `Custom`, then returns a frozen table containing their builders directly. Each property type is re-exported from its class module, for example `export type FrameProperties = Frame.Properties`.

Each class is a separate **private** ModuleScript under `Generated/Package/`. The only public import is the Wally header. Require that header first, then select builders from the returned API and types from its exported aliases:

```luau
local RobloxComponents = require(Packages.TypedInstanceComponents)
local Frame = RobloxComponents.Frame
local TextLabel = RobloxComponents.TextLabel

type Properties = RobloxComponents.FrameProperties & { Label: string }

return e(Frame({}, props, {
	Label = e(TextLabel({ Text = props.Label }, {})),
}))
```

See [the local-builder example](examples/Cached.luau). Wally's package header has no child modules: do not index beneath it or depend on private `_Index` paths. Abstract class property types remain available through header exports such as `RobloxComponents.GuiBase2dProperties`.

The exported table has no metatable. Normal indexing, generalized iteration, `pairs`, `next`, and `rawget` access its entries directly.

For local use before publication, run `lune run scripts/dev/setup.lune.luau` and use `dev.project.json`. It exposes a childless Wally-style forwarding header and keeps the implementation inside the private package index, with a sibling React dependency. `scripts/dev/prepare-project.lune.luau` regenerates those development headers and runs `wally-package-types` to expose their types. The package's `default.project.json` combines authored modules in `src/` with generated implementation modules in `Generated/Package/`; it is used internally by Wally. The `.rbxm` release asset likewise needs a sibling `React` dependency. Consumers use the same header-returned API in every layout.

## Builders and merging

```luau
RobloxComponents.Frame(defaults, props, children?)
-- returns: "Frame", mergedProperties, children
```

- Both `defaults` and `props` are required; use `{}` for an empty table. Defaults are copied last and **win** over props, exactly as in `open-shl`.
- Incoming props retain only keys in `VALID_PROPERTIES` and non-string React keys. Component-only fields and incoming string keys such as `ref`, `key`, and `children` are filtered out.
- Defaults are copied without filtering. Put React metadata such as `ref` or `key` there when needed. Inputs remain unchanged and values retain their identity.
- The third argument is returned unchanged. Pass children explicitly; there is no implicit `props.children` fallback.
- Use the builder as the final/only argument to `e` so Luau expands all three return values. Do not pass the builder itself as a component or wrap its call in another pair of parentheses.

Every generated property is a plain optional native type, for example `Size: UDim2?` or `Text: string?`. Public aliases such as `RobloxComponents.FrameProperties` are plain records. React bindings are not added to every property type; an application using a binding can explicitly cast that value at its call site. Enum properties use concrete enum types; asset URI properties such as `Image` are strings, while `ImageContent` uses `Content`. Non-string event/change/tag keys pass through unchanged.

## Class coverage

The checked-in [API source configuration](api/source.json) pins both the [GuiBase2d](https://robloxapi.github.io/ref/class/GuiBase2d.html) and [UIBase](https://robloxapi.github.io/ref/class/UIBase.html) trees from the [Roblox instance tree](https://robloxapi.github.io/ref/index.html): **49 property types and 33 host builders**. Generation writes the complete class list to `Generated/classes.md`.

Abstract, non-creatable, deprecated, and non-browsable classes expose property types only. Examples include `GuiBase2dProperties`, `GuiObjectProperties`, `UIBaseProperties` and `PluginGuiProperties`. There is no `RobloxComponents.GuiBase2d` constructor. Engine rollout and permissions still control availability of newer classes such as UIBlur/UIShadow.

Generation walks ancestors and excludes read-only, hidden, deprecated, non-scriptable and security-restricted properties. React owns `Parent`, so it is excluded, as are instance security controls. Unknown public property datatypes fail generation for review instead of becoming `any`.

## Custom classes and components

`RobloxComponents.Custom(component, project)` creates a builder for an unsupported host class or custom component. The `project` function defines the plain prop shape and selects the incoming fields. The builder copies defaults over that result and returns the explicit children argument unchanged.

```luau
type PartProps = {
	Color: Color3?,
	Anchored: boolean?,
}

local Part = RobloxComponents.Custom("Part", function(props: PartProps): PartProps
	return {
		Color = props.Color,
		Anchored = props.Anchored,
	}
end)

local element = e(Part({ Anchored = true }, {
	Color = Color3.fromRGB(255, 100, 80),
}))
```

For a custom component, pass the component instead of a class name:

```luau
type BadgeProps = { Title: string?, children: React.ReactNode? }

local function Badge(props: BadgeProps)
	return e(RobloxComponents.TextLabel({ Text = props.Title or "Badge" }, {}, props.children))
end

local CustomBadge = RobloxComponents.Custom(Badge, function(props: BadgeProps): BadgeProps
	return { Title = props.Title, children = props.children }
end)

local element = e(CustomBadge({ Title = "Ready" }, {}))
```

The projector selects incoming fields. Use an identity projector only when every incoming field belongs to the wrapped component. Keep mergeable fields optional; required fields must be present in both supplied tables. Pass children explicitly. A custom host name uses your declared property shape, and Roblox validates the actual class at render time.

See [the typed examples](examples) for both patterns.

## Development and validation

Install [Rokit](https://github.com/rojo-rbx/rokit), then run:

```sh
rokit install
lune run scripts/dev/setup.lune.luau
lune run scripts/checks/run.lune.luau
lune run scripts/build/run.lune.luau
```

Runnable Lune entry points use `.lune.luau`; imported helper modules use `.luau`. Scripts are grouped by purpose:

| Directory | Purpose |
| --- | --- |
| `scripts/build/` | Build and verify Rojo models and the Wally archive |
| `scripts/checks/` | Run formatting, regression tests and strict type checks |
| `scripts/codegen/` | Generate package modules, API snapshots and class coverage |
| `scripts/dev/` | Install dependencies, initialize the editor and serve Studio test data |
| `scripts/release/` | Validate tags and publish Wally releases |
| `scripts/shared/` | Shared command runner and package metadata helpers |

To check edited Luau files, run `lune run scripts/checks/files.lune.luau src/Merge.luau` (multiple file paths are supported). It runs `luau-lsp` and Selene, refreshes `Generated/sourcemap.json` for Roblox modules, and uses the Lune environment for tooling scripts. Intentional negative fixtures remain covered by the full check suite. Selene's generated Roblox standard library lives in `Generated/Selene/`; setup also installs Lune's editor definitions. The analyzer uses its default formatter because the pinned version's plain formatter can return success despite type errors.

Setup installs locked React dependencies, generates the package and development headers, fixes Wally type exports, and downloads pinned Roblox type definitions. Builds and checks also run generation first, so generated files need not exist in a fresh checkout. Checks verify deterministic generation, eager module loading, direct header exports, merge/filter behavior across every generated host, API mapping/restrictions, release validation, formatting, strict analysis, and nine fixtures that must fail type checking. One fixture rejects indexing below the public header. Build verifies the flat internal module hierarchy, childless public header, compiled package modules, internal require paths and Wally archive contents. Artifacts are written to `Generated/build/`:

- `typed-instance-components-0.1.0.zip`: Wally package.
- `typed-instance-components.rbxm`: package module; requires a sibling React module.
- `typed-instance-components-tests.rbxl`: test place with React, ReactRoblox, examples and integration tests.

All repository-generated outputs live under the gitignored `Generated/` directory: package modules in `Package/`, development forwarding headers in `Dev/`, API snapshots in `Api/`, class coverage in `classes.md`, the editor sourcemap in `sourcemap.json`, and release artifacts in `build/`. Only the runtime files in `Generated/Package/` are included in the Wally archive, alongside the authored runtime modules. Keep `api/source.json` and the generator scripts in version control.

The workspace includes a VS Code-compatible **Generate package on folder open** task and a default **Build package** task. Folder-open generation also refreshes the sourcemap when dependencies are installed. The workspace enables automatic tasks; VS Code still requires a trusted workspace. If your editor has disabled automatic tasks, use **Tasks: Manage Automatic Tasks** or run `lune run scripts/dev/editor-open.lune.luau` manually. See [VS Code's automatic-task behavior](https://code.visualstudio.com/docs/debugtest/tasks#_control-automatic-task-execution). Install the pinned Rokit tools before opening the workspace for the first time.

For the real renderer test, open the test place in Studio and run this in the command bar **before requiring React/ReactRoblox**:

```luau
_G.__DEV__ = true
_G.__ROACT_17_MOCK_SCHEDULER__ = true
print(require(game.ReplicatedStorage.Tests.Integration)())
```

This checks mounting, binding updates, change events, refs, nested UI instances, custom components and unmount cleanup. The test uses a detached container. CI runs the Lune/static/build checks; it does not claim to run Roblox Studio.

To refresh API coverage, update `api/source.json` to an immutable API-dump commit/URL, then run `lune run scripts/codegen/generate.lune.luau`. A missing snapshot is downloaded from that pinned URL and reduced into `Generated/Api/`; its cache key includes the commit and selected roots. Later generation runs use the cached snapshot without network access. Generation removes obsolete files bearing this generator's marker, including the former `Hosts.luau` and `Properties.luau` bundles; `--check` rejects stale or obsolete output. To seed the cache offline, run `lune run scripts/codegen/snapshot-api.lune.luau path/to/API-Dump.json` first. Update the pinned type-definition revision in `scripts/dev/setup.lune.luau`, `scripts/checks/run.lune.luau` and `scripts/checks/files.lune.luau` when the new API needs it. Review the generated API snapshot, modules and coverage locally; commit their inputs and generator changes.

## CI and releases

GitHub Actions runs workflow linting, setup, all checks and artifact builds on main-branch pushes and pull requests. Action revisions and tool versions are pinned; Dependabot maintains action pins.

To publish:

1. Configure the repository secret `WALLY_AUTH_TOKEN` for an account allowed to publish under `nightcycle`.
2. Set `wally.toml` to the release version, update `wally.lock` with `wally install`, and commit/push the validated changes.
3. Push the matching stable tag, for example `v0.1.0`, or manually dispatch Release with that existing tag.

Release checks the exact tag commit and manifest version, reruns validation, publishes Wally, then creates/uploads the GitHub release artifacts. Missing credentials and rejected Wally publication fail the release. Published Wally versions are immutable: use a new version for changed code. If Wally succeeded but GitHub asset publication failed, rerun the manual workflow for the same tag with `publish_wally` disabled. No publishing occurs during ordinary CI.

## License

Apache-2.0. The generator pattern originated in the author's open-shl project; the pinned API data is derived from the Roblox engine API dump tracked by [Roblox-Client-Tracker](https://github.com/MaximumADHD/Roblox-Client-Tracker).
