# PrintTrip

## Requirements

### PrintTrip

#### PrintTrip.Entry

- **REQ_PRN_001**: The user can open print from the trip editor.

- **REQ_PRN_002**: The user can open print from a trip card in the trips list.

- **REQ_PRN_003**: Opening print for a trip shows the print page for that trip.

#### PrintTrip.Loading

- **REQ_PRN_004**: While print data is loading, the print page keeps available options visible and communicates that required data is not ready yet.

#### PrintTrip.Title

- **REQ_PRN_009**: The document title defaults to the trip name.

- **REQ_PRN_010**: The user can edit the document title before generating the document.

#### PrintTrip.IncludeSections

- **REQ_PRN_011**: The user can choose optional document sections, including checklists, expenses, sights and places, and notes.

##### PrintTrip.IncludeSections.Defaults

- **REQ_PRN_015**: Include-section options are selected by default while data availability is unknown.

##### PrintTrip.IncludeSections.Availability

- **REQ_PRN_016**: After data is ready, a section option is unavailable when the trip has no content for that section.

#### PrintTrip.TransitFilters

- **REQ_PRN_017**: The user can filter printed travel by inter-city and intra-city travel.

##### PrintTrip.TransitFilters.Defaults

- **REQ_PRN_019**: Inter-city and intra-city travel are included by default.

##### PrintTrip.TransitFilters.Classification

- **REQ_PRN_020**: Transits are classified as inter-city or intra-city for filtering; transits with unknown city information are treated as inter-city.

#### PrintTrip.TransitSelection

- **REQ_PRN_023**: All available transits are selected by default.

- **REQ_PRN_024**: The user can include or exclude individual standalone transits.

##### PrintTrip.TransitSelection.Journeys

- **REQ_PRN_025**: A multi-leg journey is shown as a grouped travel option.

- **REQ_PRN_026**: The user can include or exclude all legs of a journey at once.

- **REQ_PRN_027**: The user can choose to print a journey as one merged entry.

- **REQ_PRN_028**: The user can choose to review and select journey legs individually.

#### PrintTrip.Generate

- **REQ_PRN_029**: The generate action is unavailable until transit options are ready.

- **REQ_PRN_030**: While the document is being generated, the generate action is unavailable.

##### PrintTrip.Generate.Success

- **REQ_PRN_031**: Successful generation opens the platform print, share, or save experience.

##### PrintTrip.Generate.Error

- **REQ_PRN_032**: If document generation fails, the user sees an error message.

#### PrintTrip.Document

- **REQ_PRN_033**: The generated document uses black-and-white output suitable for printing.

##### PrintTrip.Document.Header

- **REQ_PRN_034**: The generated document header identifies Wandrr.

- **REQ_PRN_035**: If the Wandrr logo cannot be rendered, the header still shows a readable Wandrr identity.

##### PrintTrip.Document.Footer

- **REQ_PRN_036**: Each generated document page shows its page number.

##### PrintTrip.Document.Cover

- **REQ_PRN_037**: The generated document cover includes key trip overview details such as title, date range, duration, travellers, and budget when available.

##### PrintTrip.Document.Itinerary

- **REQ_PRN_042**: The generated itinerary is organized by trip day.

- **REQ_PRN_043**: Timed check-ins, check-outs, transits, and sight visits are merged into a chronological daily timeline.

- **REQ_PRN_044**: A transit that arrives on a later day is represented on the arrival day.

- **REQ_PRN_045**: Only selected transits appear in the generated document.

##### PrintTrip.Document.Sights

- **REQ_PRN_046**: Sights without visit times are shown in a separate sights and places section when sights are included.

##### PrintTrip.Document.Notes

- **REQ_PRN_047**: Notes are included only when notes are selected and notes exist.

##### PrintTrip.Document.Checklists

- **REQ_PRN_048**: Checklists are included only when checklists are selected and checklists exist.

##### PrintTrip.Document.Expenses

- **REQ_PRN_049**: Expenses are included only when expenses are selected and expenses exist.

- **REQ_PRN_050**: The expense section shows expense rows and a total.

##### PrintTrip.Document.EmptySections

- **REQ_PRN_051**: Empty document sections are skipped.

##### PrintTrip.Document.Pagination

- **REQ_PRN_052**: Large trips continue across multiple pages.

##### PrintTrip.Document.TextFallback

- **REQ_PRN_053**: If a character cannot be rendered directly, the generated document uses a readable fallback rather than missing text.
