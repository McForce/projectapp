public without sharing class OpportunityContractorService {
    public void createContractorChanges(List<Opportunity> opportunities) {
        // Check CRUD permissions
        if (!Contractor__c.SObjectType.getDescribe().isAccessible() || 
            !Contractor_Changes__c.SObjectType.getDescribe().isCreateable()) {
            throw new SecurityException('Insufficient permissions to access Contractor__c or create Contractor_Changes__c records');
        }
        
        // Get all Project Ids from opportunities
        Set<Id> projectIds = new Set<Id>();
        Map<Id, Id> projectToOppMap = new Map<Id, Id>();
        
        for (Opportunity opp : opportunities) {
            if (opp.Project__c != null) {
                projectIds.add(opp.Project__c);
                projectToOppMap.put(opp.Project__c, opp.Id);
            }
        }
        
        if (projectIds.isEmpty()) {
            return;
        }
        
        // Query contractors for all related projects
        List<Contractor__c> contractors = [
            SELECT Id, Name, Contact__c, Project__c, Budget_Percentage__c, Cost__c 
            FROM Contractor__c 
            WHERE Project__c IN :projectIds
        ];
        
        if (contractors.isEmpty()) {
            return;
        }
        
        // Create Contractor Changes records
        List<Contractor_Changes__c> contractorChanges = new List<Contractor_Changes__c>();
        
        for (Contractor__c contractor : contractors) {
            Contractor_Changes__c change = new Contractor_Changes__c(
                Name = contractor.Name,
                Contact__c = contractor.Contact__c,
                Contractor__c = contractor.Id,
                Project__c = contractor.Project__c,
                Budget_Percentage__c = contractor.Budget_Percentage__c,
                Cost__c = contractor.Cost__c,
                Opportunity__c = projectToOppMap.get(contractor.Project__c)
            );
            contractorChanges.add(change);
        }
        
        if (!contractorChanges.isEmpty()) {
            // Perform final createable check before DML
            if (!Contractor_Changes__c.SObjectType.getDescribe().isCreateable()) {
                throw new SecurityException('Insufficient permissions to create Contractor_Changes__c records');
            }
            
            // Use Database.insert with allOrNone false to handle partial successes
            List<Database.SaveResult> results = Database.insert(contractorChanges, false);
            handleDMLErrors(results);
        }
    }
    
    private void handleDMLErrors(List<Database.SaveResult> saveResults) {
        List<String> errors = new List<String>();
        
        for (Database.SaveResult result : saveResults) {
            if (!result.isSuccess()) {
                for (Database.Error error : result.getErrors()) {
                    errors.add('Error: ' + error.getMessage());
                }
            }
        }
        
        if (!errors.isEmpty()) {
            // Log errors or notify administrators
            logErrors(errors);
        }
    }
    
    private void logErrors(List<String> errors) {
        // Implement error logging mechanism
        // This could be a custom object, platform event, or integration with logging service
        System.debug(LoggingLevel.ERROR, 'Errors occurred while creating Contractor Changes: ' + String.join(errors, ', '));
    }
}