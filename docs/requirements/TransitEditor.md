# TransitEditor

## Requirements

### TransitEditor

#### TransitEditor.TravelType

- **REQ_TRA_002**: The user can choose the travel type.

##### TransitEditor.TravelType.Options

- **REQ_TRA_003**: Travel type choices include bus, flight, rented vehicle, train, walk, ferry, cruise, vehicle, public transport, and taxi.

##### TransitEditor.TravelType.Change

- **REQ_TRA_004**: Changing travel type updates the travel-specific fields shown to the user.

#### TransitEditor.Operator

- **REQ_TRA_005**: Bookable travel may include an operator or booking reference.

##### TransitEditor.Operator.Flight

- **REQ_TRA_006**: Flight travel requires flight operator details.

###### TransitEditor.Operator.Flight.Validation

- **REQ_TRA_007**: Flight travel requires enough operator details for the user to identify the flight.

#### TransitEditor.Departure

- **REQ_TRA_008**: A transit has a departure location.

- **REQ_TRA_009**: A transit has a departure date and time.

#### TransitEditor.Arrival

- **REQ_TRA_010**: A transit has an arrival location.

- **REQ_TRA_011**: A transit has an arrival date and time.

#### TransitEditor.LocationSearch

- **REQ_TRA_012**: The user can search for departure and arrival locations.

#### TransitEditor.Validation

- **REQ_TRA_014**: A transit cannot be saved unless departure and arrival locations and date-times are provided.

- **REQ_TRA_018**: A transit cannot be saved unless arrival is after departure.

#### TransitEditor.Confirmation

- **REQ_TRA_019**: Bookable travel may include an optional confirmation identifier.

#### TransitEditor.Platforms

- **REQ_TRA_020**: Departure and arrival platform or terminal details can be recorded for their respective locations.

#### TransitEditor.Seats

- **REQ_TRA_023**: Transit travel may store seat numbers by tripmate.

- **REQ_TRA_024**: The current user's seat number is available without showing all tripmates first.

- **REQ_TRA_025**: The user can reveal and edit seat numbers for all tripmates.

#### TransitEditor.Notes

- **REQ_TRA_026**: A transit may include optional notes.

#### TransitEditor.Expense

- **REQ_TRA_027**: A transit includes editable expense details.

##### TransitEditor.Expense.Validation

- **REQ_TRA_028**: A transit cannot be saved when its expense details are invalid.

#### TransitEditor.DisplayName

- **REQ_TRA_029**: A complete transit is described by departure, arrival, and departure date.

- **REQ_TRA_030**: An incomplete transit is described as an unnamed entry.

#### TransitEditor.Timezones

- **REQ_TRA_031**: Transit times are shown according to the local time of their departure and arrival locations.

#### TransitEditor.Conflicts

- **REQ_TRA_034**: Changing departure or arrival time can require conflict review before saving.

#### TransitEditor.Save

- **REQ_TRA_035**: Saving a valid transit adds or updates the transit in itinerary and budgeting views.

#### TransitEditor.Journey

- **REQ_TRA_036**: A transit can be edited as part of a multi-leg journey.

##### TransitEditor.Journey.Initialization

- **REQ_TRA_037**: When editing a leg that belongs to a journey, all legs in that journey are available for editing.

- **REQ_TRA_038**: When editing a leg that is not part of a journey, the editor starts with a single leg.

##### TransitEditor.Journey.Legs

- **REQ_TRA_039**: Journey legs are ordered by departure time when the order can be determined.

###### TransitEditor.Journey.Legs.Add

- **REQ_TRA_040**: The user can add a leg to a journey.

- **REQ_TRA_041**: A new journey leg starts from the previous leg's arrival location when available.

###### TransitEditor.Journey.Legs.Remove

- **REQ_TRA_042**: The user can remove a leg from a journey before saving.

- **REQ_TRA_043**: Removing a leg is not committed until the user saves the journey.

##### TransitEditor.Journey.LoneLeg

- **REQ_TRA_044**: If only one leg remains in a journey, it becomes a standalone transit after saving.

##### TransitEditor.Journey.Validation

- **REQ_TRA_045**: A journey cannot be saved unless each leg is valid.

- **REQ_TRA_046**: A journey cannot be saved when a later leg departs before the previous leg arrives.

##### TransitEditor.Journey.Layover

- **REQ_TRA_047**: The journey editor shows layover duration between consecutive legs when it can be calculated.

##### TransitEditor.Journey.Expense

- **REQ_TRA_048**: A journey total can reflect expenses across all included legs.

##### TransitEditor.Journey.Conflicts

- **REQ_TRA_049**: Changing any journey leg time can require conflict review before saving.

##### TransitEditor.Journey.Save

- **REQ_TRA_050**: Saving a valid journey creates, updates, and deletes legs together according to the user's pending changes.
