public with sharing class OpportunityContractorHandler {
    
    public static void createInitialContractorChanges(List<Opportunity> newOpportunities) {
        List<Contractor_Changes__c> initialContractorChanges = new List<Contractor_Changes__c>();
        
        // Get default contractors for projects
        List<Contractor__c> defaultContractors = [
            SELECT Id, Name, Cost__c 
            FROM Contractor__c 
            WHERE Is_Default__c = true
        ];
        
        for (Opportunity opp : newOpportunities) {
            // If no default contractors, skip
            if (defaultContractors.isEmpty()) {
                continue;
            }
            
            // Create initial contractor changes for each default contractor
            for (Contractor__c contractor : defaultContractors) {
                Contractor_Changes__c change = new Contractor_Changes__c(
                    Opportunity__c = opp.Id,
                    Contractor__c = contractor.Id,
                    Cost__c = 0, // Initially set to 0
                    Change_Type__c = 'Initial',
                    Budget_Percentage__c = 0
                );
                initialContractorChanges.add(change);
            }
        }
        
        // Insert initial contractor changes
        if (!initialContractorChanges.isEmpty()) {
            insert initialContractorChanges;
        }
    }
    
    // Trigger handler method
    public static void handleAfterInsert(List<Opportunity> newOpportunities) {
        createInitialContractorChanges(newOpportunities);
    }
}