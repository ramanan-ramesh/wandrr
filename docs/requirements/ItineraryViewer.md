# ItineraryViewer

## Requirements

### ItineraryViewer

#### ItineraryViewer.DayNavigation

- **REQ_ITV_001**: The itinerary viewer lets the user choose any day in the trip date range.

- **REQ_ITV_004**: The user can quickly move through the day list when there are more days than fit on screen.

##### ItineraryViewer.DayNavigation.Persistence

- **REQ_ITV_005**: The currently viewed day is preserved when the user switches between itinerary and budgeting and returns.

#### ItineraryViewer.DayTabs

- **REQ_ITV_006**: Each itinerary day provides Timeline, Notes, Checklists, and Sights views.

- **REQ_ITV_007**: Selecting a day view shows the content for the selected day only.

#### ItineraryViewer.Timeline

- **REQ_ITV_008**: The timeline shows scheduled events for the selected day in chronological order.

##### ItineraryViewer.Timeline.Stays

- **REQ_ITV_009**: A stay check-in appears on the check-in day.

- **REQ_ITV_010**: A stay check-out appears on the check-out day.

- **REQ_ITV_011**: A stay spanning the selected day is represented as lodging context for that day.

##### ItineraryViewer.Timeline.Transits

- **REQ_ITV_012**: A transit appears on the day of its departure.

- **REQ_ITV_013**: A transit arriving on a later day is also represented on the arrival day.

##### ItineraryViewer.Timeline.Sights

- **REQ_ITV_014**: A sight with a visit time appears in the timeline for its itinerary day.

##### ItineraryViewer.Timeline.EventContent

- **REQ_ITV_015**: Each timeline event shows the information needed to identify the event, such as time, title, and relevant trip details when available.

##### ItineraryViewer.Timeline.EventActions

- **REQ_ITV_020**: Activating a stay event opens the stay editor.

- **REQ_ITV_021**: Activating a transit event opens the transit editor for that transit or journey.

- **REQ_ITV_022**: Activating a sight event opens itinerary item editing for that sight.

- **REQ_ITV_023**: Timeline events that can be removed provide a delete action.

##### ItineraryViewer.Timeline.Journeys

- **REQ_ITV_024**: Transit legs in the same journey are shown as connected travel segments.

- **REQ_ITV_025**: Connected journey segments show their order within the journey.

- **REQ_ITV_026**: Layover duration is shown between consecutive journey legs when it can be calculated.

#### ItineraryViewer.Notes

- **REQ_ITV_027**: The notes view shows notes saved for the selected day.

#### ItineraryViewer.Checklists

- **REQ_ITV_028**: The checklists view shows checklists saved for the selected day.

- **REQ_ITV_029**: Checklist items show whether they are checked or unchecked.

#### ItineraryViewer.Sights

- **REQ_ITV_030**: The sights view shows sights saved for the selected day.

#### ItineraryViewer.Loading

- **REQ_ITV_031**: While selected-day itinerary data is loading and no events are available, the timeline shows loading placeholders.

#### ItineraryViewer.EmptyState

- **REQ_ITV_032**: When the selected day has no timeline events, the timeline shows an empty-state message.

#### ItineraryViewer.LiveUpdates

- **REQ_ITV_033**: The visible itinerary day updates when relevant stays, transits, expenses, or itinerary items are created, changed, or removed.

#### ItineraryViewer.Timezones

- **REQ_ITV_034**: Stay, transit, and sight times are displayed using the location-specific wall-clock meanings entered by the user.
