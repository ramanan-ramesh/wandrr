# ConflictResolution

## Requirements

### ConflictResolution

#### ConflictResolution.Triggers

- **REQ_CON_001**: Changing a trip date range can require conflict review.

- **REQ_CON_002**: Changing trip contributors can require expense split review.

- **REQ_CON_003**: Changing stay check-in or check-out can require conflict review.

- **REQ_CON_004**: Changing transit departure or arrival can require conflict review.

- **REQ_CON_005**: Changing a journey leg time can require conflict review.

- **REQ_CON_006**: Setting, clearing, or changing a sight visit time can require conflict review.

- **REQ_CON_007**: Changing non-time descriptive details does not require time-conflict review.

#### ConflictResolution.Types

##### ConflictResolution.Types.DateBounds

- **REQ_CON_008**: A conflict exists when an existing trip item falls outside the updated trip date range.

##### ConflictResolution.Types.TemporalOverlap

- **REQ_CON_009**: A conflict exists when two timed trip items overlap in a disallowed way.

##### ConflictResolution.Types.SightOverlap

- **REQ_CON_010**: A conflict exists when two sights on the same day have the same visit time.

##### ConflictResolution.Types.ContributorExpenseSplit

- **REQ_CON_011**: A contributor change can create review items for expenses that may need split changes.

#### ConflictResolution.Rules

##### ConflictResolution.Rules.StayVsStay

- **REQ_CON_014**: Overlapping stays conflict with each other.

##### ConflictResolution.Rules.StayContainsTravelOrSight

- **REQ_CON_015**: A transit or sight fully contained within a stay does not conflict solely because it occurs during that stay.

##### ConflictResolution.Rules.BoundaryOverlap

- **REQ_CON_016**: Matching start times or matching end times are treated as overlaps when conflict rules allow them.

##### ConflictResolution.Rules.IncompleteItems

- **REQ_CON_017**: Items missing required time values are not reported as time conflicts.

##### ConflictResolution.Rules.SelfExclusion

- **REQ_CON_018**: The item currently being edited is not treated as conflicting with itself.

#### ConflictResolution.Banner

- **REQ_CON_019**: When conflicts are detected, the editor shows that conflict review is required.

- **REQ_CON_020**: The conflict notice shows how many conflicts require review.

- **REQ_CON_021**: The user can navigate from the conflict notice to the conflict review view.

#### ConflictResolution.SaveAvailability

- **REQ_CON_022**: The main save action remains unavailable until conflicts are confirmed or resolved.

#### ConflictResolution.Review

- **REQ_CON_023**: The conflict review view groups conflicts by stays, transits, and sights when those groups are present.

##### ConflictResolution.Review.Item

- **REQ_CON_024**: Each conflicted item shows its original time and proposed changed time when a time adjustment is available.

- **REQ_CON_025**: Each conflicted item shows when deletion is the proposed resolution.

##### ConflictResolution.Review.Adjustment

- **REQ_CON_026**: The user can edit proposed time adjustments for conflicted items.

###### ConflictResolution.Review.Adjustment.Validation

- **REQ_CON_027**: If an edited proposed time creates a new conflict, the user is told and the invalid edit is not accepted.

##### ConflictResolution.Review.DeleteRestore

- **REQ_CON_028**: The user can mark a conflicted item for deletion.

- **REQ_CON_029**: The user can restore a conflicted item previously marked for deletion.

##### ConflictResolution.Review.ExpenseSync

- **REQ_CON_030**: When a conflicted expense-bearing item is marked for deletion, its related expense change is also marked for deletion.

- **REQ_CON_031**: When a conflicted expense-bearing item is restored, its related expense change is also restored.

#### ConflictResolution.ContributorExpenses

- **REQ_CON_032**: When contributors are added, the user can choose which existing expenses include the new contributors in their split.

- **REQ_CON_033**: The user can select all expense split changes.

- **REQ_CON_034**: The user can deselect all expense split changes.

- **REQ_CON_035**: The user can choose individual expense split changes.

#### ConflictResolution.Confirmation

- **REQ_CON_036**: Confirming a conflict plan marks the conflicts as reviewed.

- **REQ_CON_037**: Confirmed conflict changes are not saved until the user saves the main edit.

#### ConflictResolution.Save

- **REQ_CON_038**: Saving a confirmed conflict plan saves the edited item and accepted conflict changes together.

- **REQ_CON_039**: Saving a trip date-range conflict plan also updates the visible itinerary days to match the new date range.
