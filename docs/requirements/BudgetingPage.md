# BudgetingPage

## Requirements

### BudgetingPage

#### BudgetingPage.Sections

- **REQ_BUD_002**: Budgeting provides Expenses, Debt, and Breakdown sections.

- **REQ_BUD_003**: Expenses is the default budgeting section.

#### BudgetingPage.Expenses

- **REQ_BUD_004**: The expenses section shows expense-bearing stays, transits, sights, and standalone expenses.

##### BudgetingPage.Expenses.BudgetSummary

- **REQ_BUD_005**: The expenses section shows the trip budget and total spent.

- **REQ_BUD_006**: The budget summary updates when expense totals change.

##### BudgetingPage.Expenses.Sorting

- **REQ_BUD_007**: The user can sort expenses by cost, category, or date where those sort options are available.

- **REQ_BUD_012**: Expenses are shown newest-first by default.

##### BudgetingPage.Expenses.Item

- **REQ_BUD_013**: Each expense item shows the information needed to identify the expense, including name, category, date when available, and amount.

- **REQ_BUD_017**: Activating a standalone expense opens the standalone expense editor.

- **REQ_BUD_018**: Activating a linked expense opens the relevant stay, transit, or itinerary editing flow.

##### BudgetingPage.Expenses.Delete

- **REQ_BUD_019**: Standalone expenses can be deleted from the expenses section.

##### BudgetingPage.Expenses.Loading

- **REQ_BUD_020**: While expenses are loading and no expense data is available, the expenses section shows loading placeholders.

#### BudgetingPage.Debt

- **REQ_BUD_021**: The debt section shows who needs to pay whom and how much.

- **REQ_BUD_022**: Debt entries distinguish debts owed by the current user from debts owed to the current user.

##### BudgetingPage.Debt.EmptyState

- **REQ_BUD_023**: When there are no split expenses, the debt section shows an empty-state message.

#### BudgetingPage.Breakdown

- **REQ_BUD_024**: The breakdown section shows spending grouped by category.

- **REQ_BUD_025**: The breakdown section shows spending grouped by trip day.

##### BudgetingPage.Breakdown.EmptyState

- **REQ_BUD_026**: When no spending data is available, breakdown content communicates that there is nothing to summarize.

#### BudgetingPage.Currency

- **REQ_BUD_027**: Budgeting displays use the active trip budget currency where totals are compared to the trip budget.

#### BudgetingPage.LiveUpdates

- **REQ_BUD_028**: Expense, debt, breakdown, and budget summary content update when expenses are created, changed, or removed.

- **REQ_BUD_029**: Budgeting content updates when the trip currency changes.
