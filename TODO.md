# Zig Headwind - Comprehensive TODO List

A high-performance Tailwind CSS alternative built with Zig, targeting feature parity with Tailwind 4.1.

## 🎉 Recently Completed (Session 2025-10-24)

### CLI & Build System
- ✅ Implemented full CLI with commands: init, build, watch (stub), check, clean, info, help, version
- ✅ Added command-line argument parsing with options support
- ✅ Created user-friendly help and error messages
- ✅ Implemented verbose and quiet modes

### Dark Mode Support (COMPLETED)
- ✅ **Full dark mode implementation with configurable strategies**
- ✅ Class strategy: `.dark` parent selector (default)
- ✅ Media query strategy: `@media (prefers-color-scheme: dark)`
- ✅ Configurable dark mode class name in config
- ✅ Works with all utility classes (e.g., `dark:bg-black`, `dark:text-white`)
- ✅ Supports combined variants (e.g., `dark:hover:bg-gray-800`)

### Core Architecture
- ✅ Cascade layers (@layer base, components, utilities) fully integrated
- ✅ CSS custom properties (CSS variables) for theme values
- ✅ Responsive breakpoints (sm, md, lg, xl, 2xl) with min-width and max-width variants
- ✅ Plugin system architecture with base, components, and utilities layers

### What's Working Now
- Full CSS generation pipeline with layers
- File scanning and class extraction
- Configuration loading
- Plugin system with typography and forms plugins
- Minification support
- Complete variant system (pseudo-classes, pseudo-elements, media queries)
- Extensive utility coverage (spacing, typography, colors, layout, flexbox, grid, sizing, borders, backgrounds, shadows, transforms, filters, transitions, animations, interactivity)

## 🎯 HIGH PRIORITY - Next Implementation Tasks

### Phase A: Essential Missing Features (Highest Priority)
1. ~~**Dark Mode Support**~~ - ✅ COMPLETED
   - ✅ Implement `dark:` variant with class strategy (.dark parent)
   - ✅ Add media query strategy (@media (prefers-color-scheme: dark))
   - ✅ Support configurable dark mode selector

2. **Watch Mode** - Essential for development workflow
   - [ ] Implement file watcher (FSEvents for macOS, inotify for Linux)
   - [ ] Add debouncing for rapid file changes
   - [ ] Incremental rebuild on file changes
   - [ ] Live reload integration hooks

3. **Remaining Core Layout Utilities**
   - [ ] Container utilities with breakpoints
   - [ ] Overflow utilities (overflow-x/y variants)
   - [ ] Visibility utilities (visible, invisible, collapse)
   - [ ] Z-index utilities
   - [ ] Object-fit and object-position
   - [ ] Isolation utilities

4. **Background Utilities (Remaining)**
   - [ ] Background attachment (bg-fixed, bg-local, bg-scroll)
   - [ ] Background clip (bg-clip-text, etc.)
   - [ ] Background position utilities
   - [ ] Background repeat utilities
   - [ ] Background size utilities
   - [ ] Background image gradients

### Phase B: Advanced Features (Medium Priority)
5. **Group & Peer Variants** - Common pattern for interactive UIs
   - [ ] Implement group variant (group-hover, group-focus, etc.)
   - [ ] Named groups support (group/name)
   - [ ] Peer variant implementation
   - [ ] Named peer support

6. **Container Queries** - Modern CSS feature
   - [ ] @container rule generation
   - [ ] container-type utilities
   - [ ] Container query variants (@sm, @md, @lg, etc.)
   - [ ] Named container queries

7. **Modern CSS Enhancements**
   - [ ] OKLCH color space support
   - [ ] color-mix() function support
   - ✅ Scroll utilities (scroll-margin, scroll-padding, scroll-snap-*, touch-action) - COMPLETED
   - ✅ Additional transform utilities (perspective, transform-style, backface-visibility) - COMPLETED
   - ✅ Text-shadow utilities - COMPLETED
   - ✅ Custom animation properties (iteration-count, direction, fill-mode, play-state) - COMPLETED

### Phase C: Advanced Directives & Tooling (Lower Priority)
8. **CSS Directives**
   - [ ] @utility directive for custom utilities
   - [ ] @variant directive for custom variants
   - [ ] @source directive for content paths
   - [ ] @import directive with proper resolution
   - [ ] @plugin directive for plugin loading
   - [ ] @config directive for inline configuration

9. **Performance Optimizations**
   - [ ] Multi-threading for parallel file scanning
   - [ ] Lock-free data structures for cache
   - [ ] SIMD optimizations for string scanning
   - [ ] Memory pool allocators

10. **Developer Experience**
    - [ ] Source maps generation
    - [ ] Better error messages with suggestions
    - [ ] VS Code extension skeleton
    - [ ] Documentation site
    - [ ] Example projects

---

## Phase 1: Project Setup & Core Architecture

### Project Structure
- [ ] Initialize Zig project with `build.zig`
- [ ] Create `src/main.zig` entry point
- [ ] Set up directory structure (`src/core/`, `src/parser/`, `src/generator/`, `src/cli/`)
- [ ] Create `src/config/` directory for configuration management
- [ ] Create `src/scanner/` directory for file scanning
- [ ] Create `src/cache/` directory for caching system
- [ ] Create `src/utils/` directory for shared utilities
- [ ] Set up `test/` directory with test structure
- [ ] Create `.gitignore` file
- [ ] Create `README.md` with project overview
- [ ] Create `LICENSE` file

### Build System
- [ ] Configure `build.zig` with proper Zig version (0.12+)
- [ ] Add executable target for CLI
- [ ] Add library target for programmatic usage
- [ ] Set up test runner in `build.zig`
- [ ] Configure release modes (Debug, ReleaseSafe, ReleaseFast, ReleaseSmall)
- [ ] Add cross-compilation targets (Linux x86_64, macOS arm64/x86_64, Windows x86_64)
- [ ] Set up benchmark build step

### Configuration System
- [ ] Integrate `~/Code/zig-config` library as dependency
- [ ] Create `src/config/schema.zig` for config structure
- [ ] Define default configuration values
- [ ] Implement config file discovery (headwind.config.json, headwind.config.toml)
- [ ] Add support for JSON config parsing
- [ ] Add support for TOML config parsing (if zig-config supports it)
- [ ] Create config validation system
- [ ] Implement config merging (defaults + user config)
- [ ] Add config hot-reloading support
- [ ] Create config serialization for caching
- [ ] Add environment variable overrides
- [ ] Implement configuration API for plugins

### Core Architecture
- [ ] Design memory allocation strategy (arena allocators)
- [ ] Create `src/core/types.zig` with fundamental types
- [ ] Implement string interning system for class names
- [ ] Create error handling types and utilities
- [ ] Design module interfaces and contracts
- [ ] Create `src/core/allocator.zig` for allocator management
- [ ] Implement logging system with levels (debug, info, warn, error)
- [ ] Create thread pool abstraction for parallel processing
- [ ] Design event system for file changes
- [ ] Create plugin architecture foundation

### String Utilities
- [ ] Implement fast string hashing (FNV-1a, xxHash)
- [ ] Create string builder with efficient concatenation
- [ ] Implement string splitting utilities
- [ ] Create regex-like pattern matching (or FFI to PCRE)
- [ ] Build string pool for deduplication
- [ ] Implement case conversion utilities (camelCase, kebab-case, etc.)
- [ ] Create string escaping utilities for CSS
- [ ] Implement Unicode-aware string handling
- [ ] Build string comparison utilities (case-sensitive/insensitive)

---

## Phase 2: CSS Scanning & Parsing

### File System Scanner
- [ ] Implement recursive directory traversal
- [ ] Create file type detection (by extension)
- [ ] Build glob pattern matching system
- [ ] Implement file filtering by extension
- [ ] Add support for `.gitignore` pattern exclusion
- [ ] Create include/exclude pattern system
- [ ] Implement symlink handling
- [ ] Add max depth limiting for traversal
- [ ] Build parallel directory scanning
- [ ] Implement incremental scanning (only changed files)
- [ ] Create file metadata caching
- [ ] Add support for virtual file systems (for bundler integration)

### Content Extraction
- [ ] Implement HTML class attribute extraction
- [ ] Create JSX/TSX className extraction
- [ ] Build Vue template class extraction
- [ ] Implement Svelte class extraction
- [ ] Add support for Angular template extraction
- [ ] Create template literal extraction (e.g., cn(`flex ${...}`))
- [ ] Implement arbitrary value extraction (w-[100px])
- [ ] Build variant extraction (hover:, focus:, etc.)
- [ ] Create responsive modifier extraction (md:, lg:, etc.)
- [ ] Implement group/peer variant extraction
- [ ] Add support for custom extraction patterns (regex)
- [ ] Build extraction plugin API

### File Watcher
- [ ] Research platform-specific file watching APIs
- [ ] Implement file watcher abstraction layer
- [ ] Add macOS FSEvents support
- [ ] Add Linux inotify support
- [ ] Add Windows ReadDirectoryChangesW support
- [ ] Implement debouncing for rapid changes
- [ ] Create batch change notifications
- [ ] Add support for watching multiple directories
- [ ] Implement graceful shutdown of watchers
- [ ] Build watcher event filtering
- [ ] Add error recovery for watcher failures

### Caching System
- [ ] Design cache key generation strategy
- [ ] Implement file content hashing (SHA-256 or BLAKE3)
- [ ] Create persistent cache storage (filesystem-based)
- [ ] Build in-memory cache with LRU eviction
- [ ] Implement cache invalidation logic
- [ ] Create cache statistics tracking
- [ ] Add cache compression (optional, for large projects)
- [ ] Implement cache versioning for schema changes
- [ ] Build cache cleanup utilities
- [ ] Create cache warming on startup
- [ ] Add cache export/import for CI/CD
- [ ] Implement distributed cache support (optional)

### Content Parser
- [ ] Create tokenizer for CSS class names
- [ ] Implement class name validation
- [ ] Build variant chain parser (e.g., md:hover:focus:)
- [ ] Create arbitrary value parser ([...])
- [ ] Implement modifier parser (/, !)
- [ ] Build escaped character handling
- [ ] Create parser error reporting with line/column
- [ ] Implement parser recovery for malformed input
- [ ] Add support for custom separators (: vs -)
- [ ] Build parser performance profiling

---

## Phase 3: Utility Class System

### Spacing Utilities
- [ ] Implement margin utilities (m-*, mx-*, my-*, mt-*, mr-*, mb-*, ml-*)
- [ ] Create padding utilities (p-*, px-*, py-*, pt-*, pr-*, pb-*, pl-*)
- [ ] Build space-between utilities (space-x-*, space-y-*)
- [ ] Implement gap utilities (gap-*, gap-x-*, gap-y-*)
- [ ] Create default spacing scale (0, px, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 64, 72, 80, 96)
- [ ] Add arbitrary spacing values (m-[13px])
- [ ] Implement negative values (-m-*, -mt-*, etc.)

### Typography Utilities
- [ ] Implement font-family utilities (font-sans, font-serif, font-mono)
- [ ] Create font-size utilities (text-xs, text-sm, text-base, text-lg, text-xl, text-2xl, text-3xl, text-4xl, text-5xl, text-6xl, text-7xl, text-8xl, text-9xl)
- [ ] Build font-weight utilities (font-thin, font-extralight, font-light, font-normal, font-medium, font-semibold, font-bold, font-extrabold, font-black)
- [ ] Implement font-style utilities (italic, not-italic)
- [ ] Create font-variant-numeric utilities (ordinal, slashed-zero, etc.)
- [ ] Build line-height utilities (leading-*)
- [ ] Implement letter-spacing utilities (tracking-*)
- [ ] Create text-align utilities (text-left, text-center, text-right, text-justify, text-start, text-end)
- [ ] Build text-color utilities (text-*)
- [ ] Implement text-decoration utilities (underline, overline, line-through, no-underline)
- [ ] Create text-decoration-color utilities
- [ ] Build text-decoration-style utilities
- [ ] Implement text-decoration-thickness utilities
- [ ] Create text-underline-offset utilities
- [ ] Build text-transform utilities (uppercase, lowercase, capitalize, normal-case)
- [ ] Implement text-overflow utilities (truncate, text-ellipsis, text-clip)
- [ ] Create text-wrap utilities (text-wrap, text-nowrap, text-balance, text-pretty)
- [ ] Build text-indent utilities
- [ ] Implement vertical-align utilities
- [ ] Create whitespace utilities (whitespace-normal, whitespace-nowrap, whitespace-pre, etc.)
- [ ] Build word-break utilities
- [ ] Implement hyphens utilities
- [ ] Create content utilities (content-none, content-['...'])

### Color System
- [ ] Define default color palette (slate, gray, zinc, neutral, stone, red, orange, amber, yellow, lime, green, emerald, teal, cyan, sky, blue, indigo, violet, purple, fuchsia, pink, rose)
- [ ] Implement color shade scale (50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950)
- [ ] Create opacity modifier system (text-red-500/50)
- [ ] Build arbitrary color values (bg-[#1da1f2])
- [ ] Implement CSS custom property colors (bg-[var(--my-color)])
- [ ] Create color-mix() support for Tailwind 4.1
- [ ] Build transparent, current, inherit, black, white utilities
- [ ] Implement arbitrary opacity modifiers (/[0.87])

### Layout Utilities
- [ ] Implement display utilities (block, inline-block, inline, flex, inline-flex, table, inline-table, grid, inline-grid, contents, list-item, hidden)
- [ ] Create aspect-ratio utilities (aspect-auto, aspect-square, aspect-video, aspect-[4/3])
- [ ] Build container utilities with breakpoints
- [ ] Implement columns utilities (columns-*)
- [ ] Create break-before/after/inside utilities
- [ ] Build box-decoration-break utilities
- [ ] Implement box-sizing utilities (box-border, box-content)
- [ ] Create float utilities (float-right, float-left, float-none)
- [ ] Build clear utilities (clear-left, clear-right, clear-both, clear-none)
- [ ] Implement isolation utilities (isolate, isolation-auto)
- [ ] Create object-fit utilities (object-contain, object-cover, object-fill, object-none, object-scale-down)
- [ ] Build object-position utilities
- [ ] Implement overflow utilities (overflow-auto, overflow-hidden, overflow-clip, overflow-visible, overflow-scroll, overflow-x-*, overflow-y-*)
- [ ] Create overscroll-behavior utilities
- [ ] Build position utilities (static, fixed, absolute, relative, sticky)
- [ ] Implement top/right/bottom/left utilities (inset-*)
- [ ] Create visibility utilities (visible, invisible, collapse)
- [ ] Build z-index utilities (z-*)

### Flexbox Utilities
- [ ] Implement flex-direction utilities (flex-row, flex-row-reverse, flex-col, flex-col-reverse)
- [ ] Create flex-wrap utilities (flex-wrap, flex-wrap-reverse, flex-nowrap)
- [ ] Build flex utilities (flex-1, flex-auto, flex-initial, flex-none)
- [ ] Implement flex-grow utilities
- [ ] Create flex-shrink utilities
- [ ] Build justify-content utilities (justify-start, justify-end, justify-center, justify-between, justify-around, justify-evenly, justify-stretch)
- [ ] Implement justify-items utilities
- [ ] Create justify-self utilities
- [ ] Build align-content utilities
- [ ] Implement align-items utilities (items-start, items-end, items-center, items-baseline, items-stretch)
- [ ] Create align-self utilities (self-auto, self-start, self-end, self-center, self-stretch, self-baseline)
- [ ] Build place-content utilities
- [ ] Implement place-items utilities
- [ ] Create place-self utilities
- [ ] Build order utilities (order-*)

### Grid Utilities
- [ ] Implement grid-template-columns utilities (grid-cols-*)
- [ ] Create grid-column utilities (col-auto, col-span-*, col-start-*, col-end-*)
- [ ] Build grid-template-rows utilities (grid-rows-*)
- [ ] Implement grid-row utilities (row-auto, row-span-*, row-start-*, row-end-*)
- [ ] Create grid-auto-flow utilities (grid-flow-row, grid-flow-col, grid-flow-dense, grid-flow-row-dense, grid-flow-col-dense)
- [ ] Build grid-auto-columns utilities
- [ ] Implement grid-auto-rows utilities

### Sizing Utilities
- [ ] Implement width utilities (w-*, w-1/2, w-full, w-screen, w-svw, w-lvw, w-dvw, w-min, w-max, w-fit)
- [ ] Create min-width utilities (min-w-*)
- [ ] Build max-width utilities (max-w-*)
- [ ] Implement height utilities (h-*, h-full, h-screen, h-svh, h-lvh, h-dvh, h-min, h-max, h-fit)
- [ ] Create min-height utilities (min-h-*)
- [ ] Build max-height utilities (max-h-*)
- [ ] Implement size utilities (size-* for width and height together)

### Border Utilities
- [ ] Implement border-width utilities (border, border-0, border-2, border-4, border-8, border-x, border-y, border-t, border-r, border-b, border-l)
- [ ] Create border-color utilities (border-*)
- [ ] Build border-style utilities (border-solid, border-dashed, border-dotted, border-double, border-hidden, border-none)
- [ ] Implement border-radius utilities (rounded-*, rounded-t-*, rounded-r-*, rounded-b-*, rounded-l-*, rounded-tl-*, rounded-tr-*, rounded-br-*, rounded-bl-*)
- [ ] Create outline utilities (outline, outline-0, outline-1, outline-2, outline-4, outline-8)
- [ ] Build outline-color utilities
- [ ] Implement outline-style utilities
- [ ] Create outline-offset utilities
- [ ] Build ring utilities (ring, ring-0, ring-1, ring-2, ring-4, ring-8, ring-inset)
- [ ] Implement ring-color utilities
- [ ] Create ring-offset utilities
- [ ] Build ring-offset-color utilities
- [ ] Implement divide utilities (divide-x, divide-y, divide-*)
- [ ] Create divide-color utilities
- [ ] Build divide-style utilities

### Background Utilities
- [ ] Implement background-color utilities (bg-*)
- [ ] Create background-attachment utilities (bg-fixed, bg-local, bg-scroll)
- [ ] Build background-clip utilities (bg-clip-border, bg-clip-padding, bg-clip-content, bg-clip-text)
- [ ] Implement background-origin utilities
- [ ] Create background-position utilities (bg-bottom, bg-center, bg-left, bg-left-bottom, bg-left-top, bg-right, bg-right-bottom, bg-right-top, bg-top)
- [ ] Build background-repeat utilities (bg-repeat, bg-no-repeat, bg-repeat-x, bg-repeat-y, bg-repeat-round, bg-repeat-space)
- [ ] Implement background-size utilities (bg-auto, bg-cover, bg-contain)
- [ ] Create background-image utilities (bg-none, bg-gradient-to-*)
- [ ] Build gradient color stop utilities (from-*, via-*, to-*)
- [ ] Implement arbitrary gradient values

---

## Phase 4: Advanced Features

### Arbitrary Value Support
- [ ] Implement arbitrary value tokenizer ([100px])
- [ ] Create arbitrary value validator
- [ ] Build unit preservation (px, rem, em, %, vh, vw, etc.)
- [ ] Implement calc() expression support
- [ ] Create CSS variable reference support (var(--foo))
- [ ] Build arbitrary value escaping for special characters
- [ ] Implement theme value references (theme(colors.blue.500))
- [ ] Create arbitrary property support ([&:nth-child(3)])
- [ ] Build arbitrary variant support ([&:has(>img)])

### Variant System
- [ ] Implement pseudo-class variants (hover, focus, focus-visible, focus-within, active, visited, target, first, last, only, odd, even, first-of-type, last-of-type, only-of-type, empty, disabled, enabled, checked, indeterminate, default, required, valid, invalid, in-range, out-of-range, placeholder-shown, autofill, read-only)
- [ ] Create pseudo-element variants (before, after, first-letter, first-line, marker, selection, file, backdrop, placeholder)
- [ ] Build state variants (open, closed)
- [ ] Implement media query variants (prefers-reduced-motion, prefers-color-scheme, etc.)
- [ ] Create print variant
- [ ] Build supports() query variants
- [ ] Implement aria-* attribute variants
- [ ] Create data-* attribute variants
- [ ] Build rtl/ltr directional variants
- [ ] Implement important modifier (!)
- [ ] Create variant stacking order resolution

### Responsive Design System
- [ ] Implement default breakpoints (sm: 640px, md: 768px, lg: 1024px, xl: 1280px, 2xl: 1536px)
- [ ] Create mobile-first media queries
- [ ] Build max-width breakpoints (max-sm, max-md, etc.)
- [ ] Implement range breakpoints (md:max-lg)
- [ ] Create custom breakpoint support
- [ ] Build responsive variant ordering
- [ ] Implement arbitrary breakpoint values (min-[600px])

### Dark Mode Support
- [ ] Implement class strategy (.dark parent)
- [ ] Create media strategy (@media (prefers-color-scheme: dark))
- [ ] Build selector strategy configuration
- [ ] Implement dark variant (dark:)
- [ ] Create light variant (optional)
- [ ] Build multi-theme support infrastructure

### Group & Peer Variants
- [ ] Implement group variant system (group-hover, group-focus, etc.)
- [ ] Create nested group support (group/name)
- [ ] Build peer variant system (peer-checked, peer-focus, etc.)
- [ ] Implement named peer support (peer/name)
- [ ] Create group/peer modifier combinations
- [ ] Build sibling selector variants

### Container Queries
- [ ] Implement @container rule generation
- [ ] Create container-type utilities (container-normal, container-size, container-inline-size)
- [ ] Build container-name utilities
- [ ] Implement container query variants (@sm, @md, @lg, @xl, @2xl)
- [ ] Create arbitrary container query values (@[600px])
- [ ] Build named container queries (@sidebar)

---

## Phase 5: Modern CSS Features (Tailwind 4.1 Parity)

### CSS Custom Properties
- [ ] Implement automatic CSS variable generation for theme values
- [ ] Create --color-* variables for all theme colors
- [ ] Build --spacing-* variables
- [ ] Implement --font-* variables
- [ ] Create configurable variable prefix
- [ ] Build variable value references (var(--my-color))
- [ ] Implement fallback value support
- [ ] Create CSS variable scoping (@layer)

### @theme Directive
- [ ] Implement @theme directive parser
- [ ] Create theme value registration system
- [ ] Build namespace resolution (--color-*, --spacing-*, etc.)
- [ ] Implement theme value overrides
- [ ] Create theme value inheritance
- [ ] Build theme CSS variable generation
- [ ] Implement theme value validation
- [ ] Create theme IntelliSense data export

### Cascade Layers
- [ ] Implement @layer base, components, utilities
- [ ] Create layer ordering system
- [ ] Build custom layer support
- [ ] Implement layer-aware CSS generation
- [ ] Create @layer directive in config
- [ ] Build layer import order resolution

### Modern Gradient System
- [ ] Implement linear-gradient() generation
- [ ] Create radial-gradient() support
- [ ] Build conic-gradient() support
- [ ] Implement gradient with color-mix()
- [ ] Create oklch/oklab color space support
- [ ] Build gradient position utilities
- [ ] Implement gradient size utilities

### Modern Color Functions
- [ ] Implement rgb() color generation
- [ ] Create hsl() color generation
- [ ] Build oklch() color space support
- [ ] Implement color-mix() utility generation
- [ ] Create relative color syntax support
- [ ] Build wide-gamut color support (display-p3)

---

## Phase 6: Transforms, Effects & Interactivity ✅ COMPLETED

### Transform Utilities
- [x] Implement scale utilities (scale-*, scale-x-*, scale-y-*)
- [x] Create rotate utilities (rotate-*)
- [x] Build translate utilities (translate-x-*, translate-y-*)
- [x] Implement skew utilities (skew-x-*, skew-y-*)
- [x] Create transform-origin utilities
- [ ] Build transform-style utilities (preserve-3d, flat)
- [ ] Implement perspective utilities
- [ ] Create perspective-origin utilities
- [ ] Build backface-visibility utilities

### Filter Utilities
- [x] Implement blur utilities (blur-*)
- [x] Create brightness utilities (brightness-*)
- [x] Build contrast utilities (contrast-*)
- [x] Implement drop-shadow utilities
- [x] Create grayscale utilities (grayscale, grayscale-0)
- [x] Build hue-rotate utilities (hue-rotate-*)
- [x] Implement invert utilities (invert, invert-0)
- [x] Create saturate utilities (saturate-*)
- [x] Build sepia utilities (sepia, sepia-0)
- [x] Implement backdrop-filter utilities (backdrop-blur-*, backdrop-brightness-*, etc.)

### Shadow Utilities
- [x] Implement box-shadow utilities (shadow-sm, shadow, shadow-md, shadow-lg, shadow-xl, shadow-2xl, shadow-inner, shadow-none)
- [ ] Create arbitrary shadow values (shadow-[0_35px_60px_-15px_rgba(0,0,0,0.3)])
- [x] Build shadow color utilities (shadow-red-500, shadow-red-500/50)
- [x] Implement drop-shadow utilities
- [ ] Create text-shadow utilities (optional extension)

### Transition Utilities
- [x] Implement transition-property utilities (transition-none, transition-all, transition, transition-colors, transition-opacity, transition-shadow, transition-transform)
- [x] Create transition-duration utilities (duration-*)
- [x] Build transition-timing-function utilities (ease-linear, ease-in, ease-out, ease-in-out)
- [x] Implement transition-delay utilities (delay-*)
- [ ] Create arbitrary transition values

### Animation Utilities
- [x] Implement animation utilities (animate-none, animate-spin, animate-ping, animate-pulse, animate-bounce)
- [x] Create @keyframes generation
- [ ] Build custom animation support
- [ ] Implement animation-iteration-count utilities
- [ ] Create animation-direction utilities
- [ ] Build animation-fill-mode utilities
- [ ] Implement animation-play-state utilities

### Interactivity Utilities
- [x] Implement accent-color utilities
- [x] Create appearance utilities (appearance-none, appearance-auto)
- [x] Build cursor utilities (cursor-auto, cursor-default, cursor-pointer, cursor-wait, cursor-text, cursor-move, cursor-help, cursor-not-allowed, cursor-none, cursor-context-menu, cursor-progress, cursor-cell, cursor-crosshair, cursor-vertical-text, cursor-alias, cursor-copy, cursor-no-drop, cursor-grab, cursor-grabbing, cursor-all-scroll, cursor-col-resize, cursor-row-resize, cursor-n-resize, cursor-e-resize, cursor-s-resize, cursor-w-resize, cursor-ne-resize, cursor-nw-resize, cursor-se-resize, cursor-sw-resize, cursor-ew-resize, cursor-ns-resize, cursor-nesw-resize, cursor-nwse-resize, cursor-zoom-in, cursor-zoom-out)
- [x] Implement caret-color utilities
- [x] Create pointer-events utilities (pointer-events-none, pointer-events-auto)
- [x] Build resize utilities (resize-none, resize-x, resize-y, resize)
- [x] Implement scroll-behavior utilities (scroll-auto, scroll-smooth)
- [ ] Create scroll-margin utilities (scroll-m-*, scroll-mx-*, scroll-my-*, scroll-ms-*, scroll-me-*, scroll-mt-*, scroll-mr-*, scroll-mb-*, scroll-ml-*)
- [ ] Build scroll-padding utilities (scroll-p-*, scroll-px-*, scroll-py-*, scroll-ps-*, scroll-pe-*, scroll-pt-*, scroll-pr-*, scroll-pb-*, scroll-pl-*)
- [ ] Implement scroll-snap-type utilities
- [ ] Create scroll-snap-align utilities
- [ ] Build scroll-snap-stop utilities
- [ ] Implement touch-action utilities
- [x] Create user-select utilities (select-none, select-text, select-all, select-auto)
- [x] Build will-change utilities

---

## Phase 7: CSS Generation Engine ✅ COMPLETED

### CSS AST
- [ ] Design CSS AST node types (Rule, Declaration, AtRule, etc.)
- [ ] Implement CSS AST builder
- [ ] Create AST traversal utilities
- [ ] Build AST transformation pipeline
- [ ] Implement AST optimization passes
- [ ] Create AST serialization to CSS string

### Rule Generation
- [x] Implement utility class to CSS rule converter
- [x] Create selector generation system
- [x] Build declaration block generation
- [x] Implement media query wrapping
- [ ] Create container query wrapping
- [x] Build layer wrapping (@layer utilities)
- [ ] Implement specificity calculation

### CSS Ordering
- [x] Implement base layer ordering
- [x] Create components layer ordering
- [x] Build utilities layer ordering
- [x] Implement variant ordering within utilities
- [x] Create responsive breakpoint ordering
- [x] Build deterministic sort algorithm
- [ ] Implement custom order configuration

### CSS Minification
- [x] Implement whitespace removal
- [x] Create comment removal
- [x] Build color value shortening (#ffffff -> #fff)
- [x] Implement zero value optimization (0px -> 0)
- [x] Create decimal precision reduction
- [x] Build duplicate rule removal
- [ ] Implement property value shorthand
- [ ] Create media query merging
- [ ] Build selector optimization

### Source Maps
- [ ] Implement source map generation (v3 format)
- [ ] Create mapping between utility classes and CSS rules
- [ ] Build line/column tracking
- [ ] Implement source map merging for imports
- [ ] Create source map output options
- [ ] Build inline source map support

### Preflight CSS
- [x] Implement modern CSS reset (based on Tailwind's preflight)
- [x] Create box-sizing: border-box reset
- [x] Build default border styles reset
- [x] Implement default margins reset
- [x] Create default typography reset
- [x] Build form element normalization
- [x] Implement img/svg/video defaults
- [x] Create button reset
- [x] Build table reset
- [x] Implement configurable preflight (enable/disable)

---

## Phase 8: Plugin System

### Plugin Architecture
- [ ] Design plugin interface/contract
- [ ] Implement plugin discovery system
- [ ] Create plugin loading mechanism
- [ ] Build plugin initialization lifecycle
- [ ] Implement plugin error handling
- [ ] Create plugin dependency resolution
- [ ] Build plugin versioning system

### Plugin API
- [ ] Create addUtilities() API
- [ ] Implement addComponents() API
- [ ] Build addBase() API
- [ ] Create addVariant() API
- [ ] Implement matchUtilities() API
- [ ] Build matchVariant() API
- [ ] Create theme() helper function
- [ ] Implement config() helper function
- [ ] Build e() escape helper
- [ ] Create plugin configuration schema

### Custom Utilities
- [ ] Implement static utility registration
- [ ] Create dynamic utility generation
- [ ] Build utility value mapping
- [ ] Implement utility variants support
- [ ] Create utility CSS generation
- [ ] Build utility naming conventions

### Custom Variants
- [ ] Implement custom variant registration
- [ ] Create variant selector transformation
- [ ] Build variant nesting support
- [ ] Implement variant ordering
- [ ] Create parametric variants
- [ ] Build variant composition

### Theme Extension
- [ ] Implement theme value addition
- [ ] Create theme value overriding
- [ ] Build theme value merging
- [ ] Implement nested theme paths
- [ ] Create theme function helpers
- [ ] Build theme IntelliSense support

### Official Plugins (Port from Tailwind)
- [ ] Port @tailwindcss/typography plugin
- [ ] Port @tailwindcss/forms plugin
- [ ] Port @tailwindcss/aspect-ratio plugin
- [ ] Port @tailwindcss/container-queries plugin
- [ ] Create plugin documentation

---

## Phase 9: CLI Development

### CLI Framework
- [ ] Implement command-line argument parser
- [ ] Create command routing system
- [ ] Build help text generation
- [ ] Implement version display
- [ ] Create global flags (--help, --version, --config, --verbose)
- [ ] Build exit code handling

### Build Command
- [ ] Implement `headwind build` command
- [ ] Create input file specification
- [ ] Build output file specification
- [ ] Implement minification flag (--minify)
- [ ] Create source map flag (--sourcemap)
- [ ] Build watch mode flag (--watch)
- [ ] Implement config file flag (--config)
- [ ] Create content paths override
- [ ] Build verbose logging flag

### Watch Command
- [ ] Implement `headwind watch` command
- [ ] Create file watcher integration
- [ ] Build incremental rebuild system
- [ ] Implement change detection logging
- [ ] Create rebuild debouncing
- [ ] Build error recovery in watch mode
- [ ] Implement graceful shutdown (SIGINT, SIGTERM)

### Init Command
- [ ] Implement `headwind init` command
- [ ] Create config file generation
- [ ] Build interactive prompts (framework selection, etc.)
- [ ] Implement template selection
- [ ] Create default content paths setup
- [ ] Build package.json script addition (optional)
- [ ] Implement example HTML generation (optional)

### Other Commands
- [ ] Implement `headwind check` command (validate config)
- [ ] Create `headwind clean` command (clear cache)
- [ ] Build `headwind info` command (system info, version, config path)
- [ ] Implement `headwind completions` command (shell completions)

### Progress & Logging
- [ ] Implement progress bar for scanning
- [ ] Create colored output (errors in red, success in green)
- [ ] Build structured logging format
- [ ] Implement log levels (debug, info, warn, error)
- [ ] Create timestamp logging
- [ ] Build machine-readable output format (JSON)
- [ ] Implement quiet mode flag (--quiet)
- [ ] Create verbose mode with detailed info

### Error Handling
- [ ] Implement user-friendly error messages
- [ ] Create error code system
- [ ] Build stack traces in debug mode
- [ ] Implement suggestions for common errors
- [ ] Create error recovery hints

---

## Phase 10: Performance Optimization

### Multi-threading
- [ ] Implement thread pool for file scanning
- [ ] Create work-stealing queue
- [ ] Build parallel file content extraction
- [ ] Implement parallel CSS generation
- [ ] Create thread-safe data structures
- [ ] Build synchronization primitives (mutexes, atomics)
- [ ] Implement NUMA-aware allocation (if applicable)

### Lock-free Data Structures
- [ ] Implement lock-free hash map for cache
- [ ] Create lock-free queue for work items
- [ ] Build atomic reference counting
- [ ] Implement hazard pointers (if needed)
- [ ] Create lock-free stack

### Memory Optimization
- [ ] Implement arena allocator for request lifetime
- [ ] Create pool allocator for fixed-size objects
- [ ] Build memory reuse strategies
- [ ] Implement lazy allocation
- [ ] Create memory usage profiling
- [ ] Build memory leak detection (in tests)
- [ ] Implement small string optimization
- [ ] Create copy-on-write for shared data

### SIMD Optimization
- [ ] Implement SIMD string scanning
- [ ] Create SIMD pattern matching
- [ ] Build SIMD hash computation
- [ ] Implement SIMD string comparison
- [ ] Create platform detection for SIMD features
- [ ] Build fallback for non-SIMD platforms

### Zero-copy Techniques
- [ ] Implement zero-copy file reading (mmap)
- [ ] Create string views instead of copies
- [ ] Build slice-based parsing
- [ ] Implement buffer reuse
- [ ] Create zero-copy serialization

### Profiling & Benchmarking
- [ ] Implement built-in profiler integration
- [ ] Create benchmarking harness
- [ ] Build performance regression tests
- [ ] Implement flamegraph generation
- [ ] Create memory profiling integration
- [ ] Build CPU cache profiling
- [ ] Implement benchmark comparison tools

---

## Phase 11: Testing & Quality

### Unit Tests
- [ ] Create tests for config parsing
- [ ] Build tests for string utilities
- [ ] Implement tests for class name extraction
- [ ] Create tests for variant parsing
- [ ] Build tests for arbitrary value parsing
- [ ] Implement tests for color system
- [ ] Create tests for spacing utilities
- [ ] Build tests for responsive variants
- [ ] Implement tests for dark mode
- [ ] Create tests for cache system
- [ ] Build tests for CSS generation
- [ ] Implement tests for minification
- [ ] Create tests for source maps

### Integration Tests
- [ ] Create end-to-end test for simple HTML project
- [ ] Build test for React/JSX project
- [ ] Implement test for Vue project
- [ ] Create test for Svelte project
- [ ] Build test for watch mode
- [ ] Implement test for incremental builds
- [ ] Create test for cache invalidation
- [ ] Build test for plugin system
- [ ] Implement test for custom utilities
- [ ] Create test for theme customization

### Comparison Tests
- [ ] Create test suite comparing output with Tailwind CSS
- [ ] Build utility class parity tests
- [ ] Implement CSS output equivalence tests
- [ ] Create specificity equivalence tests
- [ ] Build ordering equivalence tests

### Benchmark Suite
- [ ] Implement benchmark for file scanning
- [ ] Create benchmark for class extraction
- [ ] Build benchmark for CSS generation
- [ ] Implement benchmark for cache performance
- [ ] Create benchmark vs Tailwind CSS (speed)
- [ ] Build benchmark vs UnoCSS (speed)
- [ ] Implement memory usage benchmarks
- [ ] Create large project benchmarks (10k+ classes)
- [ ] Build cold start vs warm start benchmarks

### Fuzz Testing
- [ ] Implement fuzz tests for config parser
- [ ] Create fuzz tests for class name parser
- [ ] Build fuzz tests for arbitrary value parser
- [ ] Implement fuzz tests for CSS generation
- [ ] Create crash detection tests

### Memory Safety Tests
- [ ] Implement memory leak detection tests
- [ ] Create buffer overflow tests
- [ ] Build use-after-free detection
- [ ] Implement double-free detection
- [ ] Create memory corruption tests

### Test Infrastructure
- [ ] Set up continuous integration (GitHub Actions)
- [ ] Create test coverage reporting
- [ ] Build test result dashboard
- [ ] Implement automated regression testing
- [ ] Create test fixtures and snapshots
- [ ] Build test utilities and helpers

---

## Phase 12: Documentation & Tooling

### Core Documentation
- [ ] Write comprehensive README.md
- [ ] Create CONTRIBUTING.md guide
- [ ] Build CHANGELOG.md
- [ ] Implement versioning strategy (SemVer)
- [ ] Create LICENSE file (MIT/Apache 2.0)
- [ ] Build CODE_OF_CONDUCT.md
- [ ] Write SECURITY.md for vulnerability reporting

### User Guide
- [ ] Create installation guide
- [ ] Build quick start tutorial
- [ ] Write configuration reference
- [ ] Create utility class reference
- [ ] Build variant reference
- [ ] Write custom plugin guide
- [ ] Create theme customization guide
- [ ] Build performance optimization guide
- [ ] Write migration guide from Tailwind CSS
- [ ] Create troubleshooting guide

### API Documentation
- [ ] Generate API docs from code comments
- [ ] Create plugin API reference
- [ ] Build configuration API reference
- [ ] Write CLI command reference
- [ ] Create programmatic API docs
- [ ] Build type definitions documentation

### Examples & Templates
- [ ] Create vanilla HTML example
- [ ] Build React example project
- [ ] Create Vue example project
- [ ] Build Svelte example project
- [ ] Create Angular example project
- [ ] Build Next.js example project
- [ ] Create Astro example project
- [ ] Build SolidJS example project
- [ ] Create Qwik example project

### VS Code Extension
- [ ] Set up VS Code extension project
- [ ] Implement class name IntelliSense
- [ ] Create hover tooltips showing CSS
- [ ] Build autocomplete for utility classes
- [ ] Implement color decorators
- [ ] Create "Go to definition" for config values
- [ ] Build syntax highlighting for @theme, @utility, etc.
- [ ] Implement validation and diagnostics
- [ ] Create code actions (quick fixes)
- [ ] Build extension configuration

### Language Server Protocol (LSP)
- [ ] Implement LSP server in Zig
- [ ] Create completion provider
- [ ] Build hover provider
- [ ] Implement definition provider
- [ ] Create diagnostics provider
- [ ] Build code action provider
- [ ] Implement workspace symbol provider
- [ ] Create document link provider
- [ ] Build color provider
- [ ] Implement incremental sync

### IntelliSense Data
- [ ] Generate JSON schema for config
- [ ] Create utility class metadata
- [ ] Build variant metadata
- [ ] Implement CSS output examples
- [ ] Create search index for classes
- [ ] Build fuzzy search support

---

## Phase 13: Ecosystem Integration

### Vite Plugin
- [ ] Create @headwind/vite plugin package
- [ ] Implement Vite plugin interface
- [ ] Build HMR (Hot Module Replacement) support
- [ ] Create dev server integration
- [ ] Implement build optimization
- [ ] Build CSS code splitting support
- [ ] Create configuration merging
- [ ] Implement watch mode integration

### Webpack Loader
- [ ] Create headwind-loader for webpack
- [ ] Implement webpack loader interface
- [ ] Build webpack caching support
- [ ] Create webpack watch mode integration
- [ ] Implement multi-compiler support

### PostCSS Plugin
- [ ] Create headwind-postcss plugin
- [ ] Implement PostCSS plugin interface
- [ ] Build @headwind directive processing
- [ ] Create @apply directive support (optional)
- [ ] Implement PostCSS integration with other plugins

### Framework Integrations
- [ ] Create @headwind/react utilities (cn() helper, etc.)
- [ ] Build @headwind/vue plugin
- [ ] Create @headwind/svelte preprocessor
- [ ] Build @headwind/angular integration
- [ ] Create @headwind/solid utilities
- [ ] Build @headwind/qwik integration

### Bundler Plugins
- [ ] Create Rollup plugin
- [ ] Build esbuild plugin
- [ ] Create Parcel plugin
- [ ] Build Turbopack integration (future)

### CSS-in-JS Integration
- [ ] Create styled-components integration
- [ ] Build Emotion integration
- [ ] Create Stitches integration (if possible)
- [ ] Build vanilla-extract integration

### Static Site Generators
- [ ] Create Astro integration
- [ ] Build Eleventy plugin
- [ ] Create Jekyll plugin (if possible)
- [ ] Build Hugo integration guide

### Meta-frameworks
- [ ] Create Next.js plugin/integration guide
- [ ] Build Nuxt module
- [ ] Create SvelteKit integration guide
- [ ] Build Remix integration guide
- [ ] Create Solid Start integration guide

---

## Phase 14: Advanced Tailwind 4.1 Features

### @utility Directive
- [ ] Implement @utility directive parser
- [ ] Create custom utility definition syntax
- [ ] Build utility value interpolation
- [ ] Implement variant support for custom utilities
- [ ] Create utility composition
- [ ] Build utility validation

### @variant Directive
- [ ] Implement @variant directive parser
- [ ] Create custom variant definition syntax
- [ ] Build selector transformation
- [ ] Implement nested variant support
- [ ] Create parametric variant syntax
- [ ] Build variant validation

### @source Directive
- [ ] Implement @source directive parser
- [ ] Create content path registration
- [ ] Build glob pattern support in CSS
- [ ] Implement source priority/ordering
- [ ] Create source exclusion patterns

### @import Directive
- [ ] Implement @import directive parser
- [ ] Create CSS file resolution
- [ ] Build import graph tracking
- [ ] Implement circular import detection
- [ ] Create import caching
- [ ] Build import URL resolution
- [ ] Implement relative path resolution

### @plugin Directive
- [ ] Implement @plugin directive parser
- [ ] Create plugin loading from CSS
- [ ] Build plugin configuration syntax
- [ ] Implement plugin error handling
- [ ] Create plugin isolation

### @config Directive
- [ ] Implement @config directive parser
- [ ] Create inline configuration syntax
- [ ] Build config value overrides from CSS
- [ ] Implement config merging order

### Modern CSS Output
- [ ] Implement CSS nesting output
- [ ] Create :is() and :where() pseudo-class usage
- [ ] Build @layer usage in output
- [ ] Implement @container usage
- [ ] Create @scope output (if applicable)
- [ ] Build @starting-style support

---

## Phase 15: Cross-platform Distribution

### Build System
- [ ] Set up cross-compilation in build.zig
- [ ] Create Linux x86_64 build target
- [ ] Build Linux aarch64 build target
- [ ] Create macOS x86_64 build target
- [ ] Build macOS arm64 (Apple Silicon) build target
- [ ] Create Windows x86_64 build target
- [ ] Implement universal binary for macOS (x86_64 + arm64)
- [ ] Build static linking configuration
- [ ] Create release build optimization

### CI/CD Pipeline
- [ ] Set up GitHub Actions workflow
- [ ] Create build matrix (OS x Architecture)
- [ ] Implement automated testing on all platforms
- [ ] Build artifact collection
- [ ] Create release automation
- [ ] Implement version tagging
- [ ] Build changelog generation
- [ ] Create binary signing (macOS, Windows)
- [ ] Implement notarization (macOS)

### npm Package
- [ ] Create npm package structure
- [ ] Build platform-specific binary selection
- [ ] Implement postinstall script
- [ ] Create package.json with proper metadata
- [ ] Build TypeScript type definitions
- [ ] Implement version sync with native binary
- [ ] Create npm publishing workflow
- [ ] Build scoped package (@headwind/headwind or similar)

### Homebrew Distribution
- [ ] Create Homebrew formula
- [ ] Build formula generation automation
- [ ] Implement formula testing
- [ ] Create tap repository (homebrew-headwind)
- [ ] Build installation verification
- [ ] Implement formula updates automation

### Other Package Managers
- [ ] Create Arch Linux AUR package
- [ ] Build Debian/Ubuntu .deb package
- [ ] Create Fedora/RHEL .rpm package
- [ ] Build Nix package
- [ ] Create Chocolatey package (Windows)
- [ ] Build Scoop manifest (Windows)
- [ ] Create Snapcraft package (optional)

### Release Process
- [ ] Implement release checklist
- [ ] Create version bumping script
- [ ] Build release notes generation
- [ ] Implement binary verification
- [ ] Create download verification (checksums)
- [ ] Build release announcement template

### Installation Verification
- [ ] Create installation test suite
- [ ] Build smoke tests for each platform
- [ ] Implement version verification
- [ ] Create "hello world" test project
- [ ] Build installation documentation

---

## Phase 16: Advanced Features & Polish

### JIT Performance
- [ ] Implement Just-in-Time compilation mode
- [ ] Create streaming CSS output
- [ ] Build incremental CSS updates
- [ ] Implement partial CSS invalidation
- [ ] Create JIT class discovery

### CDN Integration
- [ ] Create CDN-hosted version
- [ ] Build Play CDN support (JIT in browser)
- [ ] Implement browser-based compiler (WASM)

### Configuration Presets
- [ ] Create minimal preset
- [ ] Build full preset (default)
- [ ] Implement custom preset system
- [ ] Create preset composition

### Design System Export
- [ ] Implement theme export to JSON
- [ ] Create Figma tokens export
- [ ] Build Style Dictionary export
- [ ] Implement CSS custom properties export

### Developer Tools
- [ ] Create browser extension for inspecting classes
- [ ] Build online playground
- [ ] Implement class visualizer
- [ ] Create configuration visualizer

### Advanced Optimizations
- [ ] Implement dead code elimination for unused theme values
- [ ] Create CSS tree shaking
- [ ] Build critical CSS extraction
- [ ] Implement automatic CSS splitting
- [ ] Create PurgeCSS-like functionality (built-in)

---

## Phase 17: Community & Ecosystem

### Community Building
- [ ] Create Discord/discussion forum
- [ ] Build contribution guidelines
- [ ] Implement issue templates
- [ ] Create PR templates
- [ ] Build community showcase

### Marketing & Outreach
- [ ] Create project website
- [ ] Build interactive documentation site
- [ ] Implement blog for updates
- [ ] Create comparison benchmarks page
- [ ] Build feature comparison matrix

### Integrations Marketplace
- [ ] Create plugin registry
- [ ] Build theme marketplace
- [ ] Implement preset sharing
- [ ] Create community templates

---

## Estimated Task Count: 650+ tasks

This comprehensive todo list covers every aspect of building a production-ready, high-performance CSS framework in Zig with full Tailwind 4.1 feature parity.
