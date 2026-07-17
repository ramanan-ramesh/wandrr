# TripEditor

## Requirements

### TripEditor

#### TripEditor.Responsive

##### TripEditor.Responsive.Narrow

- **REQ_TED_002**: The trip editor adapts between separate itinerary/budgeting navigation on narrow screens and simultaneous itinerary/budgeting viewing on wide screens.

#### TripEditor.Loading

- **REQ_TED_004**: When a trip is opening, the editor uses available trip metadata to identify the trip whenever possible.

- **REQ_TED_005**: Trip content areas show loading states until their data is available.

- **REQ_TED_006**: Opening a recently visited trip should show available cached content while remaining data loads.

#### TripEditor.AppBar

- **REQ_TED_007**: The trip editor header shows the trip name when known.

##### TripEditor.AppBar.Collaborators

- **REQ_TED_008**: The trip editor header shows trip collaborators when collaborator information is available.

- **REQ_TED_009**: If a collaborator photo cannot be loaded, the collaborator remains represented by a fallback visual.

##### TripEditor.AppBar.TripDetails

- **REQ_TED_010**: The trip editor provides an action to edit trip details.

##### TripEditor.AppBar.Print

- **REQ_TED_011**: The trip editor provides an action to print the active trip.

#### TripEditor.AddEntity

- **REQ_TED_012**: The trip editor provides a primary action for adding trip content.

##### TripEditor.AddEntity.Options

- **REQ_TED_013**: The add-content flow offers Expense, Travel, Stay, and Itinerary Item options.

##### TripEditor.AddEntity.ItineraryItem

- **REQ_TED_014**: Choosing Itinerary Item lets the user choose Sight, Note, or Checklist.

##### TripEditor.AddEntity.ItineraryDate

- **REQ_TED_015**: New itinerary items default to the currently displayed itinerary day.

- **REQ_TED_016**: The user can choose the itinerary day for a new itinerary item.

#### TripEditor.EntityEditor

##### TripEditor.EntityEditor.Mode

###### TripEditor.EntityEditor.Mode.Create

- **REQ_TED_017**: Creating an entity opens an empty form for the selected entity type.

###### TripEditor.EntityEditor.Mode.Edit

- **REQ_TED_018**: Editing an existing entity opens a form populated with saved values.

##### TripEditor.EntityEditor.Save

- **REQ_TED_019**: The save action is unavailable while the current form is invalid.

- **REQ_TED_020**: The save action is unavailable while conflicts remain unconfirmed.

- **REQ_TED_021**: Saving a valid entity closes the editing flow after the save succeeds.

- **REQ_TED_022**: After a save succeeds, itinerary and budgeting content reflect the created or changed entity.

##### TripEditor.EntityEditor.Cancel

- **REQ_TED_023**: Closing an editor without saving discards unsaved changes.

#### TripEditor.TripDetails

- **REQ_TED_024**: Trip details editing allows the user to change trip title, trip dates, budget, and contributors.

##### TripEditor.TripDetails.Title

- **REQ_TED_025**: The trip title cannot be empty after trimming.

##### TripEditor.TripDetails.Dates

- **REQ_TED_026**: Trip details cannot be saved when the end date is before the start date.

##### TripEditor.TripDetails.Budget

- **REQ_TED_028**: Changing the trip budget currency updates budgeting displays that use the trip currency.

##### TripEditor.TripDetails.Contributors

- **REQ_TED_029**: The user can add contributors to a trip.

- **REQ_TED_030**: The user can remove contributors from a trip when removal is allowed.

- **REQ_TED_031**: The current user cannot be removed from the trip contributors.

- **REQ_TED_032**: When a contributor lookup fails, the user sees an error and the contributor is not added.

##### TripEditor.TripDetails.RemovedContributors

- **REQ_TED_033**: After contributors are removed, the app informs the user that past expenses with removed tripmates are preserved for historical accuracy.

#### TripEditor.OperationFeedback

##### TripEditor.OperationFeedback.Timeout

- **REQ_TED_034**: If a save operation does not complete in time, the user is told that changes may not have been saved.

##### TripEditor.OperationFeedback.Failure

- **REQ_TED_035**: If a save operation fails, the user is told to check the connection and try again.

#### TripEditor.Navigation

##### TripEditor.Navigation.Home

- **REQ_TED_036**: Leaving the trip editor returns the user to the trips list.

- **REQ_TED_037**: Leaving the trip editor stops showing active trip-only content.
