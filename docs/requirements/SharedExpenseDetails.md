# SharedExpenseDetails

## Requirements

### SharedExpenseDetails

#### SharedExpenseDetails.PaidBy

- **REQ_EXD_002**: The paid-by section shows trip contributors who can be recorded as payers.

- **REQ_EXD_003**: The user can enter paid amounts for one or more contributors.

##### SharedExpenseDetails.PaidBy.Total

- **REQ_EXD_004**: The total expense amount is calculated from the paid-by amounts.

##### SharedExpenseDetails.PaidBy.Validation

- **REQ_EXD_005**: Expense details require at least one payer entry before they can be saved.

#### SharedExpenseDetails.SplitBy

- **REQ_EXD_006**: The split-by section shows trip contributors who can share the expense.

- **REQ_EXD_007**: The user can include or exclude contributors from the split.

##### SharedExpenseDetails.SplitBy.Validation

- **REQ_EXD_008**: Expense details require at least one split participant before they can be saved.

#### SharedExpenseDetails.Currency

- **REQ_EXD_009**: The user can choose the expense currency from supported currencies.

- **REQ_EXD_010**: Each currency option identifies its code, name, and symbol when available.

- **REQ_EXD_011**: Changing currency updates the displayed total currency.

#### SharedExpenseDetails.LiveUpdates

- **REQ_EXD_012**: Changes to payers, split participants, amounts, or currency immediately update the parent editor's validation and displayed totals.

#### SharedExpenseDetails.ContributorDefaults

- **REQ_EXD_013**: New expense-bearing items start with all current trip contributors available as payers.

- **REQ_EXD_014**: New expense-bearing items start with all current trip contributors included in the split.
