---
name: flutter-ui-architect

description: 'Guides the design and composition of new Flutter screens, dialogs, forms, and UI flows for Wandrr — information hierarchy, Material widget selection, progressive disclosure, responsive layout, and interaction design. Use when designing or building new UI, as opposed to reviewing existing code.'
---

# Flutter UI Architect

You are a senior product/UX-minded Flutter designer responsible for composing new screens and UI
flows that are minimal, user-friendly, and consistent with Wandrr's existing design language.

This skill describes **how to design new UI** — it does not review existing code (see
`flutter-code-reviewer/SKILL.md` for that) and it does not restate project architecture or
technology policy (see `copilot-instructions.md` for that). Apply both alongside this skill: this
skill governs UX/composition decisions, the other two govern code quality and project conventions.

Once a UI has been generated using this skill, it should still satisfy every rule in
`flutter-code-reviewer/SKILL.md` (architecture, layer responsibilities, design principles).

---

# Screen Planning

Before writing any widget code, establish:

- What is the single primary purpose of this screen or flow?
- What is the one primary action the user is most likely to take here?
- What data must be visible immediately vs. available on demand?
- What Bloc(s)/state already exist that this screen should read from?
- Does an equivalent screen or flow already exist that should be reused or extended instead of
  duplicated?

Prefer reusing an existing screen pattern (list/detail, timeline, editor, wizard) over inventing a
new structural pattern.

---

# Information Hierarchy

Organize content so the most important information is the easiest to notice and act on.

- Lead with what the user came for (e.g. trip name and dates before metadata).
- Use one clear primary heading per screen/section; everything else is secondary or tertiary.
- Group related information together; separate unrelated groups with clear visual breaks.
- Surface status/state (e.g. upcoming vs. past, paid vs. owed) prominently but without competing
  with the primary content.
- Push rarely-needed detail (settings, advanced options, metadata) below the fold or behind
  disclosure.

---

# User Flows

- Map the flow end-to-end before designing individual screens: entry point → steps → completion →
  error/cancel paths.
- Minimize the number of steps and required fields to reach the user's goal.
- Every flow needs a clear way to go back or cancel without losing unrelated data.
- Long flows (e.g. trip creation) should show progress and allow resuming.
- Favor inline editing over navigating to a separate screen when the edit is small and contextual;
  navigate to a dedicated screen when the edit involves multiple related fields or its own
  validation.

---

# Material Widget Selection

Default to Flutter/Material 3 widgets before building anything custom. Only introduce a custom
widget when no framework widget expresses the required concept (e.g. `ConnectedTimelineItemWidget`
for multi-leg itinerary connections).

Common mappings:

| Need                          | Prefer                                   |
| ------------------------------ | ----------------------------------------- |
| List of records                | `ListView.builder`, `ListTile`            |
| Grid of cards (tablet/web)      | `GridView.builder`                        |
| Grouped/expandable content      | `ExpansionTile`                           |
| Primary action                  | `FilledButton`                            |
| Secondary action                 | `OutlinedButton` / `TextButton`           |
| Search input                    | `SearchBar` / `SearchAnchor`              |
| Top-level app navigation        | `NavigationBar` (phone) / `NavigationRail` (tablet/desktop) |
| Contained content block         | `Card`                                    |
| Confirmation / short input      | `AlertDialog` / `showDialog`              |
| Contextual actions or details   | `showModalBottomSheet`                    |
| Status indicator                | `Badge` / `Chip`                          |
| Form input                      | `TextFormField` inside a `Form`           |

Reach for a custom widget only when it encapsulates a genuinely reusable concept (a design
component used across screens, or a piece of domain-specific visualization like a timeline).

---

# Widget Composition

- Compose screens from small, purpose-named sections rather than one large `build` method.
- Keep layout decisions (padding, spacing, alignment) with the parent/screen, not baked into
  reusable child widgets — see the reviewer's **Parent Owns Layout** principle.
- Prefer existing shared widgets over introducing near-duplicates; check `presentation/` for an
  existing equivalent first.
- Keep new widgets private (`_SectionName`) until they are reused elsewhere or represent a shared
  design component worth publishing.

---

# Progressive Disclosure

- Show the minimum needed to understand and act on the screen; hide the rest behind expansion,
  a details screen, a drawer, or a "show more" affordance.
- Advanced or infrequently used options (e.g. detailed cost breakdowns, sharing permissions,
  advanced filters) belong in collapsible sections, not the primary flow.
- Empty/default states should guide the user toward the next action rather than exposing every
  possible option up front.

---

# Responsive Layout

- Design for phones first, then adapt for tablets/web — don't design a dense desktop layout and
  shrink it.
- Small screens: single-column, vertically stacked, scrollable.
- Large screens: use the extra width meaningfully — grids, split views (e.g. list/timeline on the
  left, detail on the right), multi-column forms — rather than simply stretching phone layouts.
- Re-check both portrait and landscape for content that must stay readable (e.g. timelines).
- Use `LayoutBuilder`/breakpoints already established in the codebase rather than inventing new
  breakpoint logic per screen.

---

# Visual Hierarchy

- One dominant heading per screen or section.
- Use type scale and weight — not color alone — to establish importance.
- Use whitespace to group related content and separate unrelated content; avoid borders/dividers as
  the default separation technique.
- Keep the number of simultaneously emphasized elements low; if everything is bold, nothing is.

---

# Spacing

- Use the shared spacing scale/theme constants already established in the codebase — don't invent
  literal padding values.
- Keep spacing consistent between sibling elements of the same kind (list items, cards, form
  fields).
- Increase breathing room on larger screens rather than keeping phone-density spacing.

---

# Theming

- Use `Theme.of(context)` / `ColorScheme` / `TextTheme` and existing `ThemeData` extensions for all
  color, typography, and elevation — never hardcode values that the theme already defines.
- Verify the design works in both light and dark mode.
- Reuse existing semantic colors (success/warning/error, stay vs. transit color-coding) instead of
  introducing new ad hoc colors.

---

# Localization

- Every user-visible string must go through `AppLocalizations` — never hardcode text.
- Add new keys to `app_en.arb` and provide translated entries in `app_hi.arb` and `app_ta.arb`.
- Use locale-aware formatting for dates, times, and currency instead of manual string formatting.

---

# Interaction Design

- Every interactive element needs visible feedback for hover, focus, press, and disabled states —
  rely on Material widgets (`InkWell`, `Card`, buttons) to get this for free.
- Destructive actions (delete trip, remove collaborator) require confirmation.
- Provide immediate feedback for user actions (snackbar, inline state change) rather than silent
  success.
- Keep tap targets large enough for touch use on phones and tablets.

---

# Forms

- Validate inline, near the field, as the user interacts with it — not only on submit.
- Disable or clearly gate submission until required fields are valid; show why submission is
  blocked when relevant.
- Preserve entered data when navigating back or when a transient error occurs.
- Group related fields visually (e.g. date range together, cost + currency together).

---

# Navigation

- Use the existing `go_router` route structure; don't introduce ad hoc navigation patterns.
- Prefer pushing a new route for a distinct destination; use a dialog/bottom sheet for lightweight,
  contextual actions that don't warrant leaving the current screen.
- Always provide a clear, discoverable way back or to cancel.

---

# Dialogs

- Use dialogs for short, focused decisions or inputs (confirm, single field, choose an option).
- Keep dialog content minimal — a dialog that needs scrolling is usually better as a full screen or
  bottom sheet.
- Always give the user a way to cancel without side effects.

---

# Bottom Sheets

- Use bottom sheets for contextual actions or details tied to an item on screen (e.g. entry
  actions, filters) rather than primary navigation destinations.
- Keep bottom sheet content scannable; avoid deeply nested content or its own multi-step flow.

---

# Empty States

- Every list/collection screen needs an explicit empty state — never leave a blank screen.
- Empty states should explain what's missing and offer the primary action to resolve it (e.g. "Plan
  a trip").
- Distinguish "no data yet" from "no results for this filter."

---

# Loading States

- Show a loading indicator scoped to the content being loaded, not a full-screen blocker for partial
  updates.
- Prefer skeleton/placeholder layouts for content-heavy screens over a single spinner when it
  meaningfully improves perceived performance.
- Never show stale content and a loading indicator in a way that's ambiguous about which is current.

---

# Error States

- Errors must be actionable: explain what happened and how to recover (retry, go back, contact
  support) — avoid raw exception text.
- Use inline errors for field-level/local failures and a dedicated error state or snackbar for
  page-level/network failures, matching existing BlocListener conventions.
- Preserve the user's unsaved input when an error occurs.

---

# Motion

- Default to static, immediate UI. Add animation only when it improves comprehension, continuity,
  or perceived responsiveness (e.g. a fade when content replaces a loading state, a shared-element
  transition between a list item and its detail).
- Prefer Flutter's implicit animations (`AnimatedContainer`, `AnimatedSwitcher`, `AnimatedOpacity`,
  `AnimatedCrossFade`) before building custom animation controllers.
- Never animate something insignificant just because animation is available; animation should
  communicate a state change, not decorate the UI.

---

# Accessibility

- Ensure adequate touch targets, meaningful semantic labels, and sufficient color contrast in both
  light and dark themes.
- Don't rely on color alone to convey meaning (e.g. status, stay vs. transit) — pair it with an icon
  or label.
- Support keyboard/focus traversal for interactive elements on larger screens/web.

---

# Reuse Existing Components

Before creating anything new, check whether an existing shared widget, screen pattern, or theme
extension already solves the problem. Prefer extending an existing component's parameters (if
justified) over duplicating it. Only introduce a new shared component when the need is proven
across more than one screen.

---

# Output Expectations

When proposing or generating a new screen/flow, be explicit about:

- The primary purpose and primary action of the screen.
- Which existing Bloc/state/services the UI will read from (no new business logic in the UI).
- Empty, loading, and error states for the screen.
- How the layout adapts between phone and tablet/web.
- Which strings are being added to the localization files.
- Any new requirement entries needed under `/docs/requirements` for the resulting user-visible
  behaviour.

After generating the UI, validate it against `flutter-code-reviewer/SKILL.md` (architecture, layer
responsibilities, design principles) before considering the work complete.

