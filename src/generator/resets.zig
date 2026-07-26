const std = @import("std");
const string_utils = @import("../utils/string.zig");

/// CSS Reset Generator
/// Generates various CSS reset styles based on reset type
pub const ResetGenerator = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) ResetGenerator {
        return .{ .allocator = allocator };
    }

    /// Generate CSS for a reset utility (e.g., reset-meyer, reset-normalize)
    pub fn generateReset(self: *ResetGenerator, reset_type: []const u8) !?[]const u8 {
        if (std.mem.eql(u8, reset_type, "meyer")) {
            return try self.generateMeyerReset();
        } else if (std.mem.eql(u8, reset_type, "normalize")) {
            return try self.generateNormalizeReset();
        } else if (std.mem.eql(u8, reset_type, "tailwind") or std.mem.eql(u8, reset_type, "preflight")) {
            return try self.generateTailwindPreflight();
        } else if (std.mem.eql(u8, reset_type, "minimal")) {
            return try self.generateMinimalReset();
        } else if (std.mem.eql(u8, reset_type, "modern")) {
            return try self.generateModernReset();
        } else if (std.mem.eql(u8, reset_type, "sanitize")) {
            return try self.generateSanitizeReset();
        }
        return null;
    }

    /// Eric Meyer's CSS Reset
    fn generateMeyerReset(self: *ResetGenerator) ![]const u8 {
        _ = self;
        return
        \\/* Meyer Reset v2.0 */
        \\html, body, div, span, applet, object, iframe,
        \\h1, h2, h3, h4, h5, h6, p, blockquote, pre,
        \\a, abbr, acronym, address, big, cite, code,
        \\del, dfn, em, img, ins, kbd, q, s, samp,
        \\small, strike, strong, sub, sup, tt, var,
        \\b, u, i, center,
        \\dl, dt, dd, ol, ul, li,
        \\fieldset, form, label, legend,
        \\table, caption, tbody, tfoot, thead, tr, th, td,
        \\article, aside, canvas, details, embed,
        \\figure, figcaption, footer, header, hgroup,
        \\menu, nav, output, ruby, section, summary,
        \\time, mark, audio, video {
        \\  margin: 0;
        \\  padding: 0;
        \\  border: 0;
        \\  font-size: 100%;
        \\  font: inherit;
        \\  vertical-align: baseline;
        \\}
        \\article, aside, details, figcaption, figure,
        \\footer, header, hgroup, menu, nav, section {
        \\  display: block;
        \\}
        \\body {
        \\  line-height: 1;
        \\}
        \\ol, ul {
        \\  list-style: none;
        \\}
        \\blockquote, q {
        \\  quotes: none;
        \\}
        \\blockquote:before, blockquote:after,
        \\q:before, q:after {
        \\  content: '';
        \\  content: none;
        \\}
        \\table {
        \\  border-collapse: collapse;
        \\  border-spacing: 0;
        \\}
        ;
    }

    /// Normalize.css inspired reset
    fn generateNormalizeReset(self: *ResetGenerator) ![]const u8 {
        _ = self;
        return
        \\/* Normalize Reset */
        \\html {
        \\  line-height: 1.15;
        \\  -webkit-text-size-adjust: 100%;
        \\}
        \\body {
        \\  margin: 0;
        \\}
        \\main {
        \\  display: block;
        \\}
        \\h1 {
        \\  font-size: 2em;
        \\  margin: 0.67em 0;
        \\}
        \\hr {
        \\  box-sizing: content-box;
        \\  height: 0;
        \\  overflow: visible;
        \\}
        \\pre {
        \\  font-family: monospace, monospace;
        \\  font-size: 1em;
        \\}
        \\a {
        \\  background-color: transparent;
        \\}
        \\abbr[title] {
        \\  border-bottom: none;
        \\  text-decoration: underline;
        \\  text-decoration: underline dotted;
        \\}
        \\b, strong {
        \\  font-weight: bolder;
        \\}
        \\code, kbd, samp {
        \\  font-family: monospace, monospace;
        \\  font-size: 1em;
        \\}
        \\small {
        \\  font-size: 80%;
        \\}
        \\sub, sup {
        \\  font-size: 75%;
        \\  line-height: 0;
        \\  position: relative;
        \\  vertical-align: baseline;
        \\}
        \\sub {
        \\  bottom: -0.25em;
        \\}
        \\sup {
        \\  top: -0.5em;
        \\}
        \\img {
        \\  border-style: none;
        \\}
        \\button, input, optgroup, select, textarea {
        \\  font-family: inherit;
        \\  font-size: 100%;
        \\  line-height: 1.15;
        \\  margin: 0;
        \\}
        \\button, input {
        \\  overflow: visible;
        \\}
        \\button, select {
        \\  text-transform: none;
        \\}
        \\button,
        \\[type="button"],
        \\[type="reset"],
        \\[type="submit"] {
        \\  -webkit-appearance: button;
        \\}
        \\fieldset {
        \\  padding: 0.35em 0.75em 0.625em;
        \\}
        \\legend {
        \\  box-sizing: border-box;
        \\  color: inherit;
        \\  display: table;
        \\  max-width: 100%;
        \\  padding: 0;
        \\  white-space: normal;
        \\}
        \\progress {
        \\  vertical-align: baseline;
        \\}
        \\textarea {
        \\  overflow: auto;
        \\}
        \\[type="checkbox"],
        \\[type="radio"] {
        \\  box-sizing: border-box;
        \\  padding: 0;
        \\}
        \\[type="number"]::-webkit-inner-spin-button,
        \\[type="number"]::-webkit-outer-spin-button {
        \\  height: auto;
        \\}
        \\[type="search"] {
        \\  -webkit-appearance: textfield;
        \\  outline-offset: -2px;
        \\}
        \\[type="search"]::-webkit-search-decoration {
        \\  -webkit-appearance: none;
        \\}
        \\::-webkit-file-upload-button {
        \\  -webkit-appearance: button;
        \\  font: inherit;
        \\}
        \\details {
        \\  display: block;
        \\}
        \\summary {
        \\  display: list-item;
        \\}
        \\template {
        \\  display: none;
        \\}
        \\[hidden] {
        \\  display: none;
        \\}
        ;
    }

    /// Tailwind Preflight (modern-normalize based)
    fn generateTailwindPreflight(self: *ResetGenerator) ![]const u8 {
        _ = self;
        return
        \\/* Tailwind Preflight */
        \\*, ::before, ::after {
        \\  box-sizing: border-box;
        \\  border-width: 0;
        \\  border-style: solid;
        \\  border-color: currentColor;
        \\}
        \\html, :host {
        \\  line-height: 1.5;
        \\  -webkit-text-size-adjust: 100%;
        \\  -moz-tab-size: 4;
        \\  tab-size: 4;
        \\  font-family: ui-sans-serif, system-ui, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji";
        \\  font-feature-settings: normal;
        \\  font-variation-settings: normal;
        \\  -webkit-tap-highlight-color: transparent;
        \\}
        \\body {
        \\  margin: 0;
        \\  line-height: inherit;
        \\}
        \\hr {
        \\  height: 0;
        \\  color: inherit;
        \\  border-top-width: 1px;
        \\}
        \\abbr:where([title]) {
        \\  text-decoration: underline dotted;
        \\}
        \\h1, h2, h3, h4, h5, h6 {
        \\  font-size: inherit;
        \\  font-weight: inherit;
        \\}
        \\a {
        \\  color: inherit;
        \\  text-decoration: inherit;
        \\}
        \\b, strong {
        \\  font-weight: bolder;
        \\}
        \\code, kbd, samp, pre {
        \\  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
        \\  font-feature-settings: normal;
        \\  font-variation-settings: normal;
        \\  font-size: 1em;
        \\}
        \\small {
        \\  font-size: 80%;
        \\}
        \\sub, sup {
        \\  font-size: 75%;
        \\  line-height: 0;
        \\  position: relative;
        \\  vertical-align: baseline;
        \\}
        \\sub {
        \\  bottom: -0.25em;
        \\}
        \\sup {
        \\  top: -0.5em;
        \\}
        \\table {
        \\  text-indent: 0;
        \\  border-color: inherit;
        \\  border-collapse: collapse;
        \\}
        \\button, input, optgroup, select, textarea {
        \\  font-family: inherit;
        \\  font-feature-settings: inherit;
        \\  font-variation-settings: inherit;
        \\  font-size: 100%;
        \\  font-weight: inherit;
        \\  line-height: inherit;
        \\  letter-spacing: inherit;
        \\  color: inherit;
        \\  margin: 0;
        \\  padding: 0;
        \\}
        \\button, select {
        \\  text-transform: none;
        \\}
        \\button, input:where([type="button"]), input:where([type="reset"]), input:where([type="submit"]) {
        \\  -webkit-appearance: button;
        \\  background-color: transparent;
        \\  background-image: none;
        \\}
        \\:-moz-focusring {
        \\  outline: auto;
        \\}
        \\:-moz-ui-invalid {
        \\  box-shadow: none;
        \\}
        \\progress {
        \\  vertical-align: baseline;
        \\}
        \\::-webkit-inner-spin-button, ::-webkit-outer-spin-button {
        \\  height: auto;
        \\}
        \\[type="search"] {
        \\  -webkit-appearance: textfield;
        \\  outline-offset: -2px;
        \\}
        \\::-webkit-search-decoration {
        \\  -webkit-appearance: none;
        \\}
        \\::-webkit-file-upload-button {
        \\  -webkit-appearance: button;
        \\  font: inherit;
        \\}
        \\summary {
        \\  display: list-item;
        \\}
        \\blockquote, dl, dd, h1, h2, h3, h4, h5, h6, hr, figure, p, pre {
        \\  margin: 0;
        \\}
        \\fieldset {
        \\  margin: 0;
        \\  padding: 0;
        \\}
        \\legend {
        \\  padding: 0;
        \\}
        \\ol, ul, menu {
        \\  list-style: none;
        \\  margin: 0;
        \\  padding: 0;
        \\}
        \\dialog {
        \\  padding: 0;
        \\}
        \\textarea {
        \\  resize: vertical;
        \\}
        \\input::placeholder, textarea::placeholder {
        \\  opacity: 1;
        \\  color: #9ca3af;
        \\}
        \\button, [role="button"] {
        \\  cursor: pointer;
        \\}
        \\:disabled {
        \\  cursor: default;
        \\}
        \\img, svg, video, canvas, audio, iframe, embed, object {
        \\  display: block;
        \\  vertical-align: middle;
        \\}
        \\img, video {
        \\  max-width: 100%;
        \\  height: auto;
        \\}
        \\[hidden]:where(:not([hidden="until-found"])) {
        \\  display: none;
        \\}
        ;
    }

    /// Minimal reset - just the essentials
    fn generateMinimalReset(self: *ResetGenerator) ![]const u8 {
        _ = self;
        return
        \\/* Minimal Reset */
        \\*, *::before, *::after {
        \\  box-sizing: border-box;
        \\}
        \\* {
        \\  margin: 0;
        \\}
        \\body {
        \\  line-height: 1.5;
        \\  -webkit-font-smoothing: antialiased;
        \\}
        \\img, picture, video, canvas, svg {
        \\  display: block;
        \\  max-width: 100%;
        \\}
        \\input, button, textarea, select {
        \\  font: inherit;
        \\}
        \\p, h1, h2, h3, h4, h5, h6 {
        \\  overflow-wrap: break-word;
        \\}
        \\#root, #__next {
        \\  isolation: isolate;
        \\}
        ;
    }

    /// Modern CSS Reset (Josh Comeau style)
    fn generateModernReset(self: *ResetGenerator) ![]const u8 {
        _ = self;
        return
        \\/* Modern Reset */
        \\*, *::before, *::after {
        \\  box-sizing: border-box;
        \\}
        \\* {
        \\  margin: 0;
        \\}
        \\html, body {
        \\  height: 100%;
        \\}
        \\body {
        \\  line-height: 1.5;
        \\  -webkit-font-smoothing: antialiased;
        \\}
        \\img, picture, video, canvas, svg {
        \\  display: block;
        \\  max-width: 100%;
        \\}
        \\input, button, textarea, select {
        \\  font: inherit;
        \\}
        \\p, h1, h2, h3, h4, h5, h6 {
        \\  overflow-wrap: break-word;
        \\}
        \\h1, h2, h3, h4, h5, h6 {
        \\  text-wrap: balance;
        \\}
        \\p {
        \\  text-wrap: pretty;
        \\}
        \\a:not([class]) {
        \\  text-decoration-skip-ink: auto;
        \\  color: currentColor;
        \\}
        \\#root, #__next {
        \\  isolation: isolate;
        \\}
        \\@media (prefers-reduced-motion: no-preference) {
        \\  html {
        \\    scroll-behavior: smooth;
        \\  }
        \\}
        ;
    }

    /// Sanitize.css inspired reset
    fn generateSanitizeReset(self: *ResetGenerator) ![]const u8 {
        _ = self;
        return
        \\/* Sanitize Reset */
        \\*, ::before, ::after {
        \\  box-sizing: border-box;
        \\}
        \\::before, ::after {
        \\  text-decoration: inherit;
        \\  vertical-align: inherit;
        \\}
        \\html {
        \\  cursor: default;
        \\  line-height: 1.5;
        \\  -moz-tab-size: 4;
        \\  tab-size: 4;
        \\  -webkit-tap-highlight-color: transparent;
        \\  -ms-text-size-adjust: 100%;
        \\  -webkit-text-size-adjust: 100%;
        \\  word-break: break-word;
        \\}
        \\body {
        \\  margin: 0;
        \\}
        \\h1 {
        \\  font-size: 2em;
        \\  margin: 0.67em 0;
        \\}
        \\dl dl, dl ol, dl ul,
        \\ol dl, ul dl {
        \\  margin: 0;
        \\}
        \\ol ol, ol ul,
        \\ul ol, ul ul {
        \\  margin: 0;
        \\}
        \\hr {
        \\  color: inherit;
        \\  height: 0;
        \\}
        \\nav ol, nav ul {
        \\  list-style: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg'/%3E");
        \\  padding: 0;
        \\}
        \\pre {
        \\  font-family: monospace, monospace;
        \\  font-size: 1em;
        \\  overflow: auto;
        \\}
        \\abbr[title] {
        \\  text-decoration: underline;
        \\  text-decoration: underline dotted;
        \\}
        \\b, strong {
        \\  font-weight: bolder;
        \\}
        \\code, kbd, samp {
        \\  font-family: monospace, monospace;
        \\  font-size: 1em;
        \\}
        \\small {
        \\  font-size: 80%;
        \\}
        \\audio, canvas, iframe, img, svg, video {
        \\  vertical-align: middle;
        \\}
        \\audio:not([controls]) {
        \\  display: none;
        \\  height: 0;
        \\}
        \\img {
        \\  border-style: none;
        \\}
        \\svg:not([fill]) {
        \\  fill: currentColor;
        \\}
        \\table {
        \\  border-collapse: collapse;
        \\}
        \\button {
        \\  -webkit-appearance: button;
        \\}
        \\button, input, select {
        \\  margin: 0;
        \\}
        \\button, [type="button"], [type="reset"], [type="submit"] {
        \\  -webkit-appearance: button;
        \\}
        \\fieldset {
        \\  border: 1px solid #a0a0a0;
        \\  padding: 0.35em 0.75em 0.625em;
        \\}
        \\progress {
        \\  vertical-align: baseline;
        \\}
        \\textarea {
        \\  margin: 0;
        \\  overflow: auto;
        \\  resize: vertical;
        \\}
        \\[type="search"] {
        \\  -webkit-appearance: textfield;
        \\  outline-offset: -2px;
        \\}
        \\::-webkit-inner-spin-button, ::-webkit-outer-spin-button {
        \\  height: auto;
        \\}
        \\::-webkit-input-placeholder {
        \\  color: inherit;
        \\  opacity: 0.54;
        \\}
        \\::-webkit-search-decoration {
        \\  -webkit-appearance: none;
        \\}
        \\::-webkit-file-upload-button {
        \\  -webkit-appearance: button;
        \\  font: inherit;
        \\}
        \\::-moz-focus-inner {
        \\  border-style: none;
        \\  padding: 0;
        \\}
        \\:-moz-focusring {
        \\  outline: 1px dotted ButtonText;
        \\}
        \\:-moz-ui-invalid {
        \\  box-shadow: none;
        \\}
        \\details {
        \\  display: block;
        \\}
        \\dialog {
        \\  background-color: white;
        \\  border: solid;
        \\  color: black;
        \\  display: block;
        \\  height: fit-content;
        \\  left: 0;
        \\  margin: auto;
        \\  padding: 1em;
        \\  position: absolute;
        \\  right: 0;
        \\  width: fit-content;
        \\}
        \\dialog:not([open]) {
        \\  display: none;
        \\}
        \\summary {
        \\  display: list-item;
        \\}
        \\[aria-busy="true"] {
        \\  cursor: progress;
        \\}
        \\[aria-controls] {
        \\  cursor: pointer;
        \\}
        \\[aria-disabled="true"], [disabled] {
        \\  cursor: not-allowed;
        \\}
        \\[aria-hidden="false"][hidden] {
        \\  display: initial;
        \\}
        \\[aria-hidden="false"][hidden]:not(:focus) {
        \\  clip: rect(0, 0, 0, 0);
        \\  position: absolute;
        \\}
        ;
    }
};

/// Check if a class is a reset utility
pub fn isResetClass(class: []const u8) bool {
    return std.mem.startsWith(u8, class, "reset-");
}

/// Get the reset type from a reset class
pub fn getResetType(class: []const u8) ?[]const u8 {
    if (std.mem.startsWith(u8, class, "reset-")) {
        return class[6..];
    }
    return null;
}

test "meyer reset" {
    const allocator = std.testing.allocator;
    var generator = ResetGenerator.init(allocator);
    const css = (try generator.generateReset("meyer")).?;
    try std.testing.expect(std.mem.indexOf(u8, css, "margin: 0") != null);
}

test "normalize reset" {
    const allocator = std.testing.allocator;
    var generator = ResetGenerator.init(allocator);
    const css = (try generator.generateReset("normalize")).?;
    try std.testing.expect(std.mem.indexOf(u8, css, "line-height: 1.15") != null);
}

test "tailwind preflight" {
    const allocator = std.testing.allocator;
    var generator = ResetGenerator.init(allocator);
    const css = (try generator.generateReset("tailwind")).?;
    try std.testing.expect(std.mem.indexOf(u8, css, "box-sizing: border-box") != null);
}

test "isResetClass" {
    try std.testing.expect(isResetClass("reset-meyer"));
    try std.testing.expect(isResetClass("reset-normalize"));
    try std.testing.expect(!isResetClass("flex"));
    try std.testing.expect(!isResetClass("bg-blue-500"));
}

test "getResetType" {
    try std.testing.expectEqualStrings("meyer", getResetType("reset-meyer").?);
    try std.testing.expectEqualStrings("normalize", getResetType("reset-normalize").?);
    try std.testing.expect(getResetType("flex") == null);
}
