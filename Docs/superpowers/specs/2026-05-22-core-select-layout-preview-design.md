# Core Select Layout Preview Design

## Goal

Refine `CoreSelectScene` so core research choices read as a centered square-cell grid and sortie preparation keeps the current core appearance visible while the player adjusts the loadout.

## Scope

- Keep the work inside the existing `Scenes/CoreSelect/CoreSelectScene.gd` and `Scenes/CoreSelect/CoreSelectScene.tscn` screen flow.
- Improve the research view layout only. Research rules, costs, unlock rules, and node data remain unchanged.
- Rework the sortie preparation layout into a left-right split.
- Add a first-pass core appearance preview based on selected sortie tree node visual metadata.
- Keep existing dungeon intel, skill choices, selected tree node logic, stat preview, and sortie transition behavior.

## Approved Layout Direction

### Core Research

Each research node cell should use a stable square footprint. Tier rows should align their node cells around the horizontal center so the research view reads as a compact tree board instead of a row of uneven cards.

The square cell can keep the existing card content hierarchy:

1. Node name and track.
2. Short node description and exterior metadata.
3. Research or level status.
4. Research or level action.

Longer text must wrap inside the square cell rather than changing the cell footprint.

### Sortie Preparation

The sortie view should use a left-right split:

- Left side: current core appearance preview and compact selected-build context.
- Right side: existing scrollable sortie controls, including dungeon intel, basic attack choice, tier loadout selection, part ability choice, build summary, and sortie action.

The preview side should stay visually present while the player changes the loadout. The control side remains the main scrolling surface when content is taller than the viewport.

## Core Preview

The project does not currently provide dedicated core preview art assets. The first implementation should build a lightweight UI preview from existing `AbilityTreeNode.visual_slot` and `AbilityTreeNode.visual_variant` metadata.

The preview should show:

- A base core silhouette or modular frame built from Godot UI controls.
- Five exterior slots that map to the selected sortie tree tiers.
- A visible empty state for tiers without a selected node.
- Selected node track and variant cues so attack, defense, and utility loadouts feel distinct before art assets exist.

The preview should update whenever a sortie tree node is selected or cleared. Basic attack and part ability choices remain represented in the existing textual/stat build summary rather than changing the exterior preview.

## Data Flow

1. The player opens the existing core design scene.
2. Research view reads available ability nodes and renders centered square research cells.
3. Sortie view reads `GameState.active_tree_node_ids`.
4. Each selected tier resolves to an `AbilityTreeNode`.
5. The preview renders selected node visual slot and visual variant state from those resolved nodes.
6. Selecting or clearing a sortie tier rebuilds the sortie view and refreshes the preview from the same `GameState` selection.

No new saved state is required.

## Empty And Error States

- A tier without an equipped node should render as an empty exterior slot in the preview.
- If a selected node cannot resolve from `_nodes_by_id`, the preview should behave as if that slot is empty and keep the rest of the sortie view usable.
- Missing art assets are expected in this iteration; the preview must not depend on texture resources.

## Testing And Verification

- Verify the research view keeps all research node cells square and centered across the five tiers.
- Verify research cell content wraps without resizing the square footprint.
- Verify the sortie view uses a left-right layout with the preview visible beside the controls on the intended desktop layout.
- Verify selecting and clearing tier nodes updates the preview slot states.
- Verify empty tiers still render clearly in the preview.
- Run the project validation path available for Godot scene and script checks after implementation.

## Out Of Scope

- Creating final core illustration or sprite assets.
- Splitting the preview into a reusable standalone scene before another screen needs it.
- Changing ability tree rules, research balance, loadout rules, or dungeon flow.
