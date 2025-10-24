const std = @import("std");

/// Generate comprehensive Tailwind-style preflight CSS reset
pub fn generatePreflight(allocator: std.mem.Allocator) ![]const u8 {
    _ = allocator;

    return
        \\  /* Preflight - Modern CSS Reset */
        \\
        \\  /* 1. Use a more-intuitive box-sizing model */
        \\  *, ::before, ::after {
        \\    box-sizing: border-box;
        \\  }
        \\
        \\  /* 2. Remove default margin and padding */
        \\  * {
        \\    margin: 0;
        \\    padding: 0;
        \\  }
        \\
        \\  /* 3. Allow percentage-based heights */
        \\  html, body {
        \\    height: 100%;
        \\  }
        \\
        \\  /* 4. Add smooth scrolling */
        \\  html:focus-within {
        \\    scroll-behavior: smooth;
        \\  }
        \\
        \\  /* 5. Improve text rendering */
        \\  body {
        \\    line-height: 1.5;
        \\    -webkit-font-smoothing: antialiased;
        \\    -moz-osx-font-smoothing: grayscale;
        \\  }
        \\
        \\  /* 6. Improve media defaults */
        \\  img, picture, video, canvas, svg {
        \\    display: block;
        \\    max-width: 100%;
        \\  }
        \\
        \\  /* 7. Remove built-in form typography styles */
        \\  input, button, textarea, select {
        \\    font: inherit;
        \\  }
        \\
        \\  /* 8. Avoid text overflows */
        \\  p, h1, h2, h3, h4, h5, h6 {
        \\    overflow-wrap: break-word;
        \\  }
        \\
        \\  /* 9. Create a root stacking context */
        \\  #root, #__next {
        \\    isolation: isolate;
        \\  }
        \\
        \\  /* 10. Remove default button styles */
        \\  button, [role="button"] {
        \\    cursor: pointer;
        \\    background: none;
        \\    border: none;
        \\  }
        \\
        \\  /* 11. Remove list styles */
        \\  ol, ul, menu {
        \\    list-style: none;
        \\  }
        \\
        \\  /* 12. Reset links */
        \\  a {
        \\    color: inherit;
        \\    text-decoration: inherit;
        \\  }
        \\
        \\  /* 13. Reset form elements */
        \\  button, input, optgroup, select, textarea {
        \\    font-family: inherit;
        \\    font-size: 100%;
        \\    font-weight: inherit;
        \\    line-height: inherit;
        \\    color: inherit;
        \\  }
        \\
        \\  /* 14. Reset button borders */
        \\  button, select {
        \\    text-transform: none;
        \\  }
        \\
        \\  /* 15. Correct button styling in Safari */
        \\  button, [type='button'], [type='reset'], [type='submit'] {
        \\    -webkit-appearance: button;
        \\    background-color: transparent;
        \\    background-image: none;
        \\  }
        \\
        \\  /* 16. Remove default padding in Firefox */
        \\  button::-moz-focus-inner,
        \\  [type='button']::-moz-focus-inner,
        \\  [type='reset']::-moz-focus-inner,
        \\  [type='submit']::-moz-focus-inner {
        \\    border-style: none;
        \\    padding: 0;
        \\  }
        \\
        \\  /* 17. Reset fieldsets */
        \\  fieldset {
        \\    border: 0;
        \\    padding: 0;
        \\    margin: 0;
        \\    min-width: 0;
        \\  }
        \\
        \\  /* 18. Reset legend */
        \\  legend {
        \\    padding: 0;
        \\  }
        \\
        \\  /* 19. Add default cursor for disabled elements */
        \\  [disabled] {
        \\    cursor: not-allowed;
        \\  }
        \\
        \\  /* 20. Reset textarea resize */
        \\  textarea {
        \\    resize: vertical;
        \\  }
        \\
        \\  /* 21. Reset input placeholder opacity */
        \\  input::placeholder,
        \\  textarea::placeholder {
        \\    opacity: 1;
        \\    color: #9ca3af;
        \\  }
        \\
        \\  /* 22. Reset button focus styles */
        \\  button:focus-visible, [type='button']:focus-visible,
        \\  [type='reset']:focus-visible, [type='submit']:focus-visible {
        \\    outline: 2px solid transparent;
        \\    outline-offset: 2px;
        \\  }
        \\
        \\  /* 23. Reset search input appearance */
        \\  [type='search'] {
        \\    -webkit-appearance: textfield;
        \\    outline-offset: -2px;
        \\  }
        \\
        \\  /* 24. Remove search cancel button */
        \\  [type='search']::-webkit-search-decoration {
        \\    -webkit-appearance: none;
        \\  }
        \\
        \\  /* 25. Fix file upload button webkit appearance */
        \\  ::-webkit-file-upload-button {
        \\    -webkit-appearance: button;
        \\    font: inherit;
        \\  }
        \\
        \\  /* 26. Reset summary element */
        \\  summary {
        \\    display: list-item;
        \\  }
        \\
        \\  /* 27. Reset abbr title */
        \\  abbr[title] {
        \\    text-decoration: underline dotted;
        \\  }
        \\
        \\  /* 28. Reset table borders */
        \\  table {
        \\    border-collapse: collapse;
        \\    border-spacing: 0;
        \\  }
        \\
        \\  /* 29. Reset hidden attribute */
        \\  [hidden] {
        \\    display: none !important;
        \\  }
    ;
}

/// Generate minimal preflight (legacy behavior)
pub fn generateMinimalPreflight(allocator: std.mem.Allocator) ![]const u8 {
    _ = allocator;

    return
        \\  /* Preflight */
        \\  *, ::before, ::after { box-sizing: border-box; }
        \\  body { margin: 0; line-height: inherit; }
    ;
}
