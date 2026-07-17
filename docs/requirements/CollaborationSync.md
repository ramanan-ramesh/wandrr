# CollaborationSync

## Requirements

### CollaborationSync

#### CollaborationSync.Visibility

- **REQ_SYN_002**: A user sees trips they own or that are shared with them.

#### CollaborationSync.LiveUpdates

- **REQ_SYN_003**: When a shared trip is open, changes made by other contributors are reflected in the open trip.

##### CollaborationSync.LiveUpdates.Entities

- **REQ_SYN_004**: Live updates include stays, transits, standalone expenses, itinerary items, and trip details.

##### CollaborationSync.LiveUpdates.Create

- **REQ_SYN_005**: When another contributor creates trip content, the new content appears in the relevant trip views.

##### CollaborationSync.LiveUpdates.Update

- **REQ_SYN_006**: When another contributor changes trip content, the changed content updates in the relevant trip views.

##### CollaborationSync.LiveUpdates.Delete

- **REQ_SYN_007**: When another contributor deletes trip content, the deleted content disappears from the relevant trip views.

#### CollaborationSync.Navigation

- **REQ_SYN_008**: Live shared updates are active while the trip is open.

- **REQ_SYN_009**: Live shared updates for a trip stop being shown after the user leaves that trip.

#### CollaborationSync.TripDateChanges

- **REQ_SYN_010**: When trip dates change, visible itinerary days update to match the new date range.

#### CollaborationSync.Budgeting

- **REQ_SYN_011**: Shared expense changes update budgeting totals, debt, and breakdown information.

#### CollaborationSync.Preservation

- **REQ_SYN_012**: Removing a contributor does not rewrite historical expense records solely to remove that contributor from past expenses.
