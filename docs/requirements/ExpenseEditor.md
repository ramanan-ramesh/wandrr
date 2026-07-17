# ExpenseEditor

## Requirements

### ExpenseEditor

#### ExpenseEditor.LinkedExpense

- **REQ_EXP_002**: When an expense belongs to a stay, transit, or sight, selecting it opens the owning item when detailed editing belongs there.

#### ExpenseEditor.Category

- **REQ_EXP_003**: A standalone expense has a category.

##### ExpenseEditor.Category.Options

- **REQ_EXP_004**: Expense category choices include other, flights, lodging, car rental, public transit, food, drinks, sightseeing, activities, shopping, fuel, groceries, and taxi.

- **REQ_EXP_005**: The user can change a standalone expense category.

#### ExpenseEditor.Title

- **REQ_EXP_006**: A standalone expense has an editable title.

##### ExpenseEditor.Title.Linked

- **REQ_EXP_007**: A linked expense title is derived from the linked trip item and is not independently edited as a standalone expense title.

#### ExpenseEditor.PaidOn

- **REQ_EXP_008**: A standalone expense may have a paid-on date.

- **REQ_EXP_009**: Changing the paid-on date immediately updates the selected date shown to the user.

#### ExpenseEditor.Description

- **REQ_EXP_010**: A standalone expense may include an optional description.

#### ExpenseEditor.PaymentDetails

- **REQ_EXP_011**: A standalone expense includes editable payment details.

#### ExpenseEditor.Validation

##### ExpenseEditor.Validation.Amount

- **REQ_EXP_012**: A standalone expense cannot be saved unless its total amount is greater than zero.

##### ExpenseEditor.Validation.Currency

- **REQ_EXP_013**: A standalone expense cannot be saved without a currency.

##### ExpenseEditor.Validation.Split

- **REQ_EXP_014**: A standalone expense cannot be saved unless at least one payer and at least one split participant are present.

#### ExpenseEditor.Responsive

##### ExpenseEditor.Responsive.Narrow

- **REQ_EXP_015**: The expense editor adapts its layout to available screen width while keeping expense details and payment details available.

#### ExpenseEditor.Save

- **REQ_EXP_017**: Saving a valid standalone expense adds or updates the expense in budgeting views.

#### ExpenseEditor.Delete

- **REQ_EXP_018**: Standalone expenses can be deleted from expense lists where deletion is offered.

##### ExpenseEditor.Delete.Linked

- **REQ_EXP_019**: Linked expenses are deleted by deleting or editing their owning stay, transit, or sight.
