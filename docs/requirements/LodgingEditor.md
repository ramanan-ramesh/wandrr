# LodgingEditor

## Requirements

### LodgingEditor

#### LodgingEditor.Location

- **REQ_LOD_002**: A stay has a location.

- **REQ_LOD_003**: The user can search for and select a stay location.

##### LodgingEditor.Location.Validation

- **REQ_LOD_004**: A stay cannot be saved without a location.

#### LodgingEditor.Dates

- **REQ_LOD_005**: A stay has a check-in date and time.

- **REQ_LOD_006**: A stay has a check-out date and time.

##### LodgingEditor.Dates.Validation

- **REQ_LOD_007**: A stay cannot be saved unless both check-in and check-out date-times are provided.

- **REQ_LOD_009**: A stay cannot be saved when check-out is before check-in.

##### LodgingEditor.Dates.TripBounds

- **REQ_LOD_010**: Stay date selection is constrained to the trip date range.

#### LodgingEditor.Confirmation

- **REQ_LOD_011**: A stay may include an optional confirmation identifier.

#### LodgingEditor.Notes

- **REQ_LOD_012**: A stay may include optional notes.

#### LodgingEditor.Expense

- **REQ_LOD_013**: A stay includes editable expense details.

##### LodgingEditor.Expense.Validation

- **REQ_LOD_014**: A stay cannot be saved when its expense details are invalid.

#### LodgingEditor.DisplayName

- **REQ_LOD_015**: A complete stay is described as a stay at its location across its check-in and check-out dates.

- **REQ_LOD_016**: An incomplete stay is described as an unnamed entry.

#### LodgingEditor.Timezones

- **REQ_LOD_017**: Check-in and check-out are interpreted as wall-clock times at the selected stay location.

##### LodgingEditor.Timezones.LocationChange

- **REQ_LOD_018**: When the stay location changes, existing stay times preserve the user's intended wall-clock meaning for the new location.

#### LodgingEditor.Conflicts

- **REQ_LOD_019**: Changing check-in or check-out can require conflict review before saving.

- **REQ_LOD_020**: A transit or sight fully inside a stay's time range is not a conflict solely because it occurs during the stay.

#### LodgingEditor.Save

- **REQ_LOD_021**: Saving a valid stay adds or updates the stay in itinerary and budgeting views.
