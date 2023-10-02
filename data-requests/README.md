# Public Data Requests (PDR)

[![super-linter](https://github.com/ccao-data/public/actions/workflows/lint.yaml/badge.svg)](https://github.com/ccao-data/public/actions/workflows/lint.yaml)
[![pre-commit](https://github.com/ccao-data/public/actions/workflows/pre-commit.yaml/badge.svg)](https://github.com/ccao-data/public/actions/workflows/pre-commit.yaml)

Public data requests are one-off requests primarily from outside the CCAO. The purpose of scripting and committing even simple requests is to ensure that request outputs are reproducible.

## Workflow

1. Create a branch associated with the issue. This can be done directly from within the issue page (bottom right).
2. Clone the repository, then checkout the issue branch locally.
3. Copy the template directory `pdr-issue-template` to create a new project directory specifically for your issue. Be sure to rename both the directory _and_ the `.Rproj` file, i.e. `pdr-issue-template.Rproj` should become `pdr-issue-XXXX.Rproj`, replacing `XXXX` with the issue number.
4. Open the newly-created project directory in RStudio, this should initialize `renv` specifically for your issue project. Work the issue to completion, taking note of the requirements below.
5. Store your input data, output data, and code following the requirements below.
6. Once you've finished working the issue, snapshot the state of your R (or Python) dependencies using `renv::snapshot()` or `pipreqs`.
7. Create a pull request to merge your issue branch to `main`. Wait for a @core-team member to review your PR.
8. Once approved, merge your PR, then send the resulting data to the relevant parties.

## Requirements

All code in this repository should be associated with an issue directory. Pull requests to close PDR issues should not modify code outside of their respective directories.

Scripts should be stored in the directory related to their issue. Scripts should be named descriptively according to their function.

Input data should keep its original name or should be renamed descriptively.

Output data should be named descriptively and saved to `s3://ccao-data-public-us-east-1/data-requests/pdr-issue-XXXX/`

Some additional notes:

- Be sure to use zero-padding when creating and renaming issue files and directories.
- Do not save data in this repository or your pull request will be rejected.
- Try to use stakeholders' affiliations rather than their names.
- Try to include context in code comments and issue descriptions about _why_ you did things a certain way.