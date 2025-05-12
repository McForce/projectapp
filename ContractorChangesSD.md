 Solution Design: Contractor Changes Management

1. Business Requirements

 Primary Requirement
Provide a view when a button is clicked on the Opportunity record that:
- Lists all Contractor Changes associated with the Opportunity
- Displays Contractor details including:
  - Contractor Name
  - Cost
  - Budget Percentage
- Shows Budget Total (sum of all costs)
- Supports inline editing of costs
- Update Multiple Contractor Changes
- Maintains total cost equal to Opportunity Amount

 Business Rules
1. Total contractor costs must equal the Opportunity Amount
2. Budget percentages must be automatically recalculated when costs change
3. When costs are modified, Change Type of Contractor Changes should update to 'Reallocation'

 2. Technical Design

 2.1 Data Model

 Objects Used
1. Opportunity
   - Standard Salesforce object
   - Contains the total amount field (Amount)

2. Contractor_Changes__c
   - Custom object
   - Fields:
     - Contractor__c (Lookup to Contractor)
     - Cost__c (Currency)
     - Budget_Percentage__c (Percentage)
     - Change_Type__c (Text)
     - Opportunity__c (Master-Detail to Opportunity)
     - Project__c (Lookup to Project)

3. Contractor__c
   - Custom object
   - Fields:
     - Name
     - Project__c
     - Contact__c
     - Cost__c
     - Budget_Percentage__c

 2.2 Component Architecture

 Lightning Web Component: Contractor Changes
- Purpose: Displays and manages contractor changes inline editing through button on Opportunity
- Features:
  - Data table with inline editing
  - Real-time total calculation
  - Error handling
  - Toast notifications
  - Automatic refresh after updates

 Apex Controller: Opportunity Contractor Controller
- Methods:
  1. Get Contractor Changes 
  2. Get Opportunity Amount 
  3. Update Multiple Contractor Changes

Apex Handler Opportunity Contractor Handler
- Creates initial contractor changes when opportunity is created
- Handles the After Insert trigger event
