1. Custom Object: Contractor_Billing__c
Custom Fields:
Field Name: Contractor_Invoice__c
Field Type: Lookup
Lookup Object: Contractor_Invoice__c
Field Name: Last_Billed_Up_To__c
Field Type: Date
Field Name: Contractor
Field Type: Lookup
Lookup Object: Contractor

2. Custom Object: Contractor_Changes__c
Custom Fields:
Field Name: Budget_Percentage__c
Field Type: Percent
Precision: 18
Scale: 2
Field Name: Change_Type__c
Field Type: Picklist
Values:
Add
Remove
Reallocation
Field Name: Contact__c
Field Type: Lookup
Lookup Object: Contact
Field Name: Contractor__c
Field Type: Lookup
Lookup Object: Contractor__c
Field Name: Cost__c
Field Type: Currency
Precision: 18
Scale: 2
Field Name: Opportunity__c
Field Type: Lookup
Lookup Object: Opportunity

3. Custom Object: Contractor__c
Custom Fields:
Field Name: Budget_Percentage__c
Field Type: Percent
Precision: 18
Scale: 2
Field Name: Contact__c
Field Type: Lookup
Lookup Object: Contact
Field Name: Cost__c
Field Type: Currency
Precision: 18
Scale: 0
Field Name: Project__c
Field Type: Lookup
Lookup Object: Project__c
Field Name: Project_Addition_Date__c
Field Type: Date

4. Custom Object: Contractor_Invoice__c
Custom Fields:
Field Name: Last_Billed_Up_To__c
Field Type: Date

5. Standard Object: Opportunity
Custom Fields:
Field Name: Bill_Effective_Date__c
Field Type: Date
Field Name: Project__c
Field Type: Lookup
Lookup Object: Project__c
Field Name: Account
Field Type: Lookup
Lookup Object: Account

6. Custom Object: Contractor_Changes__c
Fields:
- Budget_Percentage__c
  - Type: Percent
  - Precision: 18
  - Scale: 2
- Change_Type__c
  - Type: Picklist
  - Values:
    - Add
    - Remove
    - Reallocation
- Contact__c
  - Type: Lookup
  - Lookup Object: Contact
- Contractor__c
  - Type: Lookup
  - Lookup Object: Contractor__c
- Cost__c
  - Type: Currency
  - Precision: 18
  - Scale: 2
- Opportunity__c
  - Type: Lookup
  - Lookup Object: Opportunity
- Project__c
  - Type: Lookup
  - Lookup Object: Project

7. Custom Object:Project 
Fields: 
Field Name: Account__c
Field Type: Lookup
Lookup Object: Account
Field Name: Project_Start_Date__c
Field Type: Date
Field Name: Budget_Cost__c
Field Type: Currency

8. Standard Object: Contact
Fields: 
Field Name: Account
Field Type: Lookup
Lookup Object: Account
