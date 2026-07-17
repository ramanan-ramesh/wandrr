# ItineraryPlanDataEditor

## Requirements

### ItineraryPlanDataEditor

#### ItineraryPlanDataEditor.Header

- **REQ_IPD_002**: The editor shows the itinerary day being edited.

#### ItineraryPlanDataEditor.EntryMode

##### ItineraryPlanDataEditor.EntryMode.Create

- **REQ_IPD_003**: When creating a sight, note, or checklist, the editor starts on the matching content type.

- **REQ_IPD_004**: When creating a sight, note, or checklist, a new editable item is added for the chosen day.

##### ItineraryPlanDataEditor.EntryMode.Edit

- **REQ_IPD_005**: When editing an existing sight, note, or checklist, the editor starts on the matching content type.

- **REQ_IPD_006**: When editing an existing item, the matching item is expanded or focused when possible.

#### ItineraryPlanDataEditor.Tabs

- **REQ_IPD_007**: The editor provides Sights, Notes, and Checklists sections.

#### ItineraryPlanDataEditor.Sights

- **REQ_IPD_008**: The sights section lists all sights for the day.

##### ItineraryPlanDataEditor.Sights.Add

- **REQ_IPD_009**: The user can add a sight to the day.

##### ItineraryPlanDataEditor.Sights.Remove

- **REQ_IPD_010**: The user can remove a sight from the day.

##### ItineraryPlanDataEditor.Sights.Name

- **REQ_IPD_011**: Each sight includes a name and may include location, visit time, description, and expense details.

###### ItineraryPlanDataEditor.Sights.Name.Validation

- **REQ_IPD_012**: A sight name must be at least three characters.

##### ItineraryPlanDataEditor.Sights.VisitTime

###### ItineraryPlanDataEditor.Sights.VisitTime.Validation

- **REQ_IPD_017**: Two sights on the same day cannot have the same visit time.

###### ItineraryPlanDataEditor.Sights.VisitTime.Conflicts

- **REQ_IPD_018**: Changing sight visit times can require conflict review before saving.

#### ItineraryPlanDataEditor.Notes

- **REQ_IPD_019**: The notes section lists all notes for the day.

##### ItineraryPlanDataEditor.Notes.Add

- **REQ_IPD_020**: The user can add a note to the day.

##### ItineraryPlanDataEditor.Notes.Remove

- **REQ_IPD_021**: The user can remove a note from the day.

##### ItineraryPlanDataEditor.Notes.Validation

- **REQ_IPD_022**: A saved note cannot be empty.

#### ItineraryPlanDataEditor.Checklists

- **REQ_IPD_023**: The checklists section lists all checklists for the day.

##### ItineraryPlanDataEditor.Checklists.Add

- **REQ_IPD_024**: The user can add a checklist to the day.

##### ItineraryPlanDataEditor.Checklists.Remove

- **REQ_IPD_025**: The user can remove a checklist from the day.

##### ItineraryPlanDataEditor.Checklists.Title

- **REQ_IPD_026**: Each checklist has a title.

###### ItineraryPlanDataEditor.Checklists.Title.Validation

- **REQ_IPD_027**: A checklist title must be at least three characters.

##### ItineraryPlanDataEditor.Checklists.Items

- **REQ_IPD_028**: Each checklist contains one or more items.

- **REQ_IPD_029**: The user can add and remove checklist items.

- **REQ_IPD_030**: Each checklist item can be checked or unchecked.

###### ItineraryPlanDataEditor.Checklists.Items.Validation

- **REQ_IPD_031**: A checklist item cannot be empty.

#### ItineraryPlanDataEditor.Validation

- **REQ_IPD_032**: A day with no sights, notes, or checklists is valid.

#### ItineraryPlanDataEditor.Save

- **REQ_IPD_033**: Changes are saved only when the user confirms the editor.

#### ItineraryPlanDataEditor.Cancel

- **REQ_IPD_034**: Closing the editor without saving discards unsaved changes.

#### ItineraryPlanDataEditor.Timezones

- **REQ_IPD_035**: Sight visit times preserve the wall-clock time intended for the sight location.
