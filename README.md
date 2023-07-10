# Public

Welcome to the CCAO Data Department's public engagement repository. Within this repo, you can:

- [View public talks and other engagements from the Data Department](#public-engagement)
- [View public data sets published by the CCAO](#open-data)
- [Create a new public data request](#data-requests)
- [Raise a new question or issue related to the Data Department's work](#questions-and-issues)

## Public Engagement

#### Talks

Members of the Data Department occasionally present at meetups, conferences, and other events about their work. Below is a list of the most recent recorded events:

| Date       | Title                                                                         | Topics                                                      | Video                                   | Slides                                                                                               |
|------------|-------------------------------------------------------------------------------|-------------------------------------------------------------|-----------------------------------------|------------------------------------------------------------------------------------------------------|
| 2023/01/17 | Why Are Chicago Property Taxes So High? (And What Can Be Done to Lower Them?) | R, public finance, TIF, property taxes                      | [YouTube](https://youtu.be/0F-iqRj4yR0) | [PPTX](https://github.com/ccao-data/public/raw/main/presentations/2023-01-17_Chi-Hack-Night.pptx)    |
| 2022/08/16 | Cook County Assessor's Residential Model V3                                   | data science, predictive modeling, R, Tidymodels            | [YouTube](https://youtu.be/h0pwAr-WYxI) | [PPTX](https://github.com/ccao-data/public/raw/main/presentations/2022-08-16_Chi-Hack-Night.pptx)    |
| 2021/01/20 | Cook County Assessor's Residential Model V2                                   | data science, predictive modeling, R, Tidymodels            | [YouTube](https://youtu.be/6rd-xYJb27Q) | [PPTX](https://github.com/ccao-data/public/raw/main/presentations/2021-01-20_Chi-Hack-Night.pptx)    |

#### AMAs

The Data Department has also done a reddit AMA, where we answered questions about the office and modeling.

| Date       | Title                                                                                                                                    | Topics                                                      | Link                                                                                                       |
|------------|------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------|------------------------------------------------------------------------------------------------------------|
| 2022/06/08 | We are the Cook County Assessor’s Data Team and are responsible for making the models that affect property assessments. Ask Us Anything! | public finance, property taxes, assessments, government     | [reddit](https://old.reddit.com/r/chicago/comments/v7rvqm/we_are_the_cook_county_assessors_data_team_and/) |

## Questions and Issues

- Public v private
- List of closed issues
- Here, vs specific repos

## Open Data

- Links to portal
- Links to wiki

## Data Requests

The Data Department supports the CCAO's [commitment to transparency](https://gitlab.com/groups/ccao-data-science---modeling/-/wikis/Handbook/Mission%20Vision%20Values#transparency) by accepting and processing bulk data requests from the public. This repository leverages public issue tickets to manage that work. We believe making our entire workflow public, creates transparency, reduces costs, and increases efficiency.

We strive to meet a **turnaround time of 14 business days**. However, operational priorities come before public data requests. We will communicate with requesters if we cannot meet our turnaround target.

### Is this a Freedom of Information Act Request?

**No.** This repository is a service offered by the Data Department and does not supersede the Freedom of Information Act. A data request submitted via this repository is not a request that falls under the Freedom of Information Act. In order to file an official FOIA request, please [visit our website](https://www.cookcountyassessor.com/foia-freedom-information). Departmental discretion governs this request mechanism.

### What types of requests do we process?

Transparency can be costly, and our department has limited resources. We process requests for bulk data. We do not process requests for data analysis, including graphs, sophisticated tabulations or matching, time-consuming data cleansing, etc. We will limit our expenditure on repeated data requests from the same requester if we believe the repetition is due to 'scope creep.' This often happens when the requester does not have a sufficiently clear understanding of the data they want, and uses our department to help refine their ideas. We do not have the resources to help refine your research question. If you have a specific project and need data from our office, we're happy to help. If we choose not to process a request, we will clearly indicate our rationale on the issue ticket.

### What data is available?

The CCAO is working to increase the organization and documentation of its data. The most complete and current data dictionaries and inventories can be found on the [Data Science wiki](https://gitlab.com/groups/ccao-data-science---modeling/-/wikis/Data/Data-Catalog.xlsx). A description of all curated public data sets [can be found here](https://gitlab.com/groups/ccao-data-science---modeling/-/wikis/SOPs/Open%20Data). We continue to work on building better, clearer data documentation.

### Process for making a request using GitLab

1. Check to see whether your data is available on the [Cook County Open Data Portal](https://datacatalog.cookcountyil.gov/browse?tags=cook%20county%20assessor).
2. Check to see whether someone has already requested the same data you are looking for.

    a. Navigate to the [issues list](https://gitlab.com/ccao-data-science---modeling/reports/public-data-requests/-/issues).

    b. Click 'All' to see open and closed issues.

    c. Search for keywords that may appear in other requestor's issues where they are requesting the same data.

    d. If you find a request that satisfies your needs, please comment on that issue ticket so we can send you access credentials to our data delivery server.

3. Open an issue ticket for your data request.

    a. Navigate to the [issues list](https://gitlab.com/ccao-data-science---modeling/reports/public-data-requests/-/issues).

    b. Click 'New issue'

    c. Title your issue with your name.

    d. Directly beneath the issue title there is a 'Description' selection. Select 'Public data request.' This will pre-populate your issue with a template.

    e. **Read and fill out the template**

    f. Submit the issue.

When your issue is submitted, GitLab generates an email notification to CCAO staff. Your issue will be assigned and tracked.

### Data delivery

When ready, your data will be saved on our public S3 bucket and a link will be shared in the issue comments. Your data will be saved with the issue ticket number in its name, e.g. "pdr123.csv". Your data will remain on S3 for one month - you should download it as soon as possible.
