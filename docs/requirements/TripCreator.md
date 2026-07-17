# TripCreator

## Requirements

### TripCreator

#### TripCreator.Create

- **REQ_TC_001**: The create trip flow allows the user to choose a trip thumbnail.

- **REQ_TC_002**: The create trip flow allows the user to choose a start date and end date.

- **REQ_TC_003**: The create trip flow allows the user to enter a trip name.

- **REQ_TC_004**: The create trip flow allows the user to set a budget amount.

- **REQ_TC_005**: The create trip flow allows the user to choose a budget currency.

##### TripCreator.Create.Defaults

- **REQ_TC_006**: A new trip starts with INR as the budget currency.

- **REQ_TC_007**: A new trip starts with a road-trip thumbnail.

- **REQ_TC_008**: A new trip starts with a zero budget amount.

##### TripCreator.Create.Validation

- **REQ_TC_009**: A trip cannot be created without a trip name.

- **REQ_TC_010**: A trip cannot be created without both a start date and an end date.

- **REQ_TC_011**: A trip cannot be created when the end date is before the start date.

- **REQ_TC_012**: Create-trip date selection does not allow dates before the current date.

##### TripCreator.Create.Submit

- **REQ_TC_013**: When a trip is created, the current user is added as a contributor.

- **REQ_TC_014**: After successful trip creation, the create trip flow closes.

#### TripCreator.Copy

- **REQ_TC_015**: The copy trip flow starts with a name based on the source trip name.

- **REQ_TC_016**: The copy trip flow starts with the current date as the new start date.

##### TripCreator.Copy.DateShift

- **REQ_TC_017**: When the user changes the copied trip start date, the new end date preserves the source trip duration.

- **REQ_TC_018**: The copy trip flow shows the source date range and the resulting copied date range.

##### TripCreator.Copy.Contributors

- **REQ_TC_019**: The copy trip flow starts with the source trip contributors.

- **REQ_TC_020**: The user can change the contributor list before copying a trip.

##### TripCreator.Copy.Budget

- **REQ_TC_021**: The copy trip flow starts with the source trip budget.

- **REQ_TC_022**: The user can change the copied trip budget amount and currency.

##### TripCreator.Copy.Thumbnail

- **REQ_TC_023**: The copied trip uses the source trip thumbnail unless changed by another trip action.

##### TripCreator.Copy.Validation

- **REQ_TC_024**: A copied trip cannot be submitted with an empty name.

- **REQ_TC_025**: The copied trip start date can be selected from the current date up to ten years ahead.

##### TripCreator.Copy.Submit

- **REQ_TC_026**: Submitting a valid copied trip creates a separate trip.

- **REQ_TC_027**: Copied trip dates preserve the time of day for copied stays, transit legs, sights, and dated expenses.

- **REQ_TC_028**: Empty itinerary days from the source trip are not copied as user-visible day content.

#### TripCreator.Delete

- **REQ_TC_029**: The delete trip flow asks the user to confirm before a trip is deleted.

- **REQ_TC_030**: The delete trip flow provides a cancel action that leaves the trip unchanged.

- **REQ_TC_031**: Confirming deletion permanently removes the trip from the trips list.

#### TripCreator.ThumbnailSelector

- **REQ_TC_032**: The user can browse predefined trip thumbnails.

- **REQ_TC_033**: A thumbnail change is applied only after the user confirms the selection.
