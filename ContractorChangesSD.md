Business Requirement: have a button on the Opportunity that provides a view of all Contractor Changes associated with the Opportunity displaying the Contractor, their Cost and Budget percentage, and have a Budget Total at the bottom (total Cost) and do inline editing

The user should be able to inline edit where they are able to Update the the Cost - that will update the Budget percentage (percentage of Opportunity’s Amount)

Validation on save that the total Cost must equal the Opportunity’s Amount

Automation - when the Contractor’s cost is updated the Change type on the Contractor Change record is set to Reallocation

Proposed Solution Overview:

The user should be able to inline edit where they are able to Update the the Cost - that will update the Budget percentage (percentage of Opportunity’s Amount)
Validation on save that the total Cost must equal the Opportunity’s Amount
Automation - when the Contractor’s cost is updated the Change type on the Contractor Change record is set to Reallocation
Multiple record updates on save
Component is accessible through an action (button) on the Opportunity
Technical Approach:

Data Model Relationships:
Opportunity (Parent)
Contractor Changes (Child) – Lookup to Project and Contractor
Contractor (Child) – Lookup to Project
Contractor Billing (Child) – Lookup to Contractor
Backend Implementation:
Apex Controller Class:
Develop an Apex Controller (e.g., OpportunityContractorChangeController) to:
Fetch all Contractor Change records related to the Opportunity (by Opportunity Id).
Calculate each Contractor Change's Budget Percentage (Cost / Opportunity.Amount).
Aggregate total Cost for the Budget Total.
Accept and process inline edits from the LWC.(multiple record updates)
Ensure multiple record updates on save
On save, validate that the total Cost matches the Opportunity Amount.
If a Contractor Change’s Cost is updated, set its Change Type to "Reallocation" before update.
Dont use a trigger, handle in the controller through the save action

Apex Wrapper Class:
Create a Wrapper class (e.g., ContractorChangeWrapper) to:
Aggregate data for each Contractor Change (Contractor Name, Cost, Budget Percentage, Change Type, etc.).
Expose calculated fields like Budget Percentage.
Pass data efficiently to/from the LWC.

Frontend Implementation:
Lightning Web Component (LWC):
Display a table of Contractor Changes with columns: Contractor (Contractor Change record) , Cost (editable), Budget Percentage (read-only).
Calculate and display the Budget Total (sum of Costs) at the bottom.
Allow inline editing of the Cost field.
Send updates to the Apex Controller on save.
Display error messages if validation fails (i.e., if Budget Total ≠ Opportunity Amount).
Disable save until the validation passes.
LWC will run from a action (button) from the Opportunity Lightning record page.
Ensure CRUD/FLS compliance in the Apex Controller.
Handle exceptions and display user-friendly error messages.
Key Considerations:
Performance: Only fetch necessary fields; use aggregate queries where possible.
Scalability: Future requirements will include adding and removing Contractor Changes - build for scale
Security: Enforce field-level and object-level security in Apex.
Reusability: Design the Apex handler to accept any Project Id for flexibility.
Code best Practice: Ensure you use apex best practice which includes validate CRUD permission before SOQL/DML operations
Avoid using if statements without curly braces (rule: Code Style-IfStmtsMustUseBraces)
Validate CRUD permission before SOQL/DML operation (rule: Security-ApexCRUDViolation)

Technical Flow (Mermaid)
sequenceDiagram
    participant LWC
    participant Apex
    participant Database
    participant User

    LWC->>Apex: getContractorChanges(oppId)
    LWC->>Apex: getOpportunityAmount(oppId)
    Apex->>Database: Query Contractor_Changes__c
    Apex->>Database: Query Opportunity
    Database-->>Apex: Return data
    Apex-->>LWC: Return data
    LWC->>User: Display data table
