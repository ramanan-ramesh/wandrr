# TripsListView

## Requirements

### TripsListView

#### TripsListView.UpcomingTrips

- **REQ_TLV_002**: Trips whose end date is today or later appear in the upcoming trips section.

#### TripsListView.PastTrips

- **REQ_TLV_003**: Trips whose end date is before today appear in the past trips section.

#### TripsListView.Sorting

- **REQ_TLV_004**: Trips within each section are ordered by start date with newer trips before older trips.

#### TripsListView.YearFilter

- **REQ_TLV_005**: Each trips section offers year filters based on trip start years in that section.

- **REQ_TLV_006**: Selecting a year filter shows only trips from that start year in that section.

##### TripsListView.YearFilter.Default

- **REQ_TLV_007**: When a section first appears, its first available year is selected automatically.

#### TripsListView.EmptyState

- **REQ_TLV_008**: When the user has no trips, the trips list shows an empty-state message encouraging trip planning.

#### TripsListView.PlanATrip

- **REQ_TLV_009**: The trips list provides a prominent action to plan a new trip.

- **REQ_TLV_010**: Activating the plan-a-trip action opens the create trip flow.

##### TripsListView.PlanATrip.Keyboard

- **REQ_TLV_011**: The plan-a-trip action is hidden when text entry would otherwise cover it.

#### TripsListView.TripCard

- **REQ_TLV_012**: Each trip card shows the information needed to identify the trip, including its thumbnail, name, and date range.

##### TripsListView.TripCard.ImageLoading

- **REQ_TLV_015**: While a trip thumbnail is loading, the card reserves the image area and shows a loading placeholder.

##### TripsListView.TripCard.Open

- **REQ_TLV_016**: Activating a trip card opens that trip in the trip editor.

##### TripsListView.TripCard.StatusBadge

- **REQ_TLV_017**: Trip cards indicate active or upcoming status when that status is relevant to the user.

##### TripsListView.TripCard.Actions

- **REQ_TLV_020**: Each trip card offers actions for changing the thumbnail, printing, copying, and deleting the trip.

###### TripsListView.TripCard.Actions.Thumbnail

- **REQ_TLV_021**: Changing a trip thumbnail updates the card when the user confirms a different thumbnail.

###### TripsListView.TripCard.Actions.Print

- **REQ_TLV_022**: Choosing print from a trip card opens the print flow for that trip.

###### TripsListView.TripCard.Actions.Copy

- **REQ_TLV_023**: Choosing copy from a trip card opens the copy trip flow for that trip.

###### TripsListView.TripCard.Actions.Delete

- **REQ_TLV_024**: Choosing delete from a trip card opens a confirmation before deletion.

#### TripsListView.Responsive

- **REQ_TLV_025**: The trip list adjusts the number of visible card columns to available screen width.

#### TripsListView.LiveUpdates

- **REQ_TLV_026**: Created trips appear in the list without requiring the user to restart the app.

- **REQ_TLV_027**: Deleted trips disappear from the list without requiring the user to restart the app.
