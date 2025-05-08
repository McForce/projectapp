public class OppContractorHandler {
    
    public static void handleAfterInsert(List<Opportunity> newOpportunities) {
        Set<Id> projectIds = new Set<Id>();
        Map<Id, Opportunity> contractorChangeOpps = new Map<Id, Opportunity>();
        
        // Filter opportunities of type "Contractor Changes" and collect Project IDs
        for(Opportunity opp : newOpportunities) {
            if(opp.Type == 'Contractor Changes' && opp.Project__c != null) {
                projectIds.add(opp.Project__c);
                contractorChangeOpps.put(opp.Project__c, opp);
            }
        }
        
        if(projectIds.isEmpty()) {
            return;
        }
        
        // Query existing Contractors for the related Projects
        List<Contractor__c> existingContractors = [
            SELECT Id, Project__c, Contact__c, Cost__c, Budget_Percentage__c
            FROM Contractor__c
            WHERE Project__c IN :projectIds
        ];
        
        List<Contractor_Changes__c> contractorChangesToInsert = new List<Contractor_Changes__c>();
        
        // Create Contractor Changes records for each Contractor
        for(Contractor__c contractor : existingContractors) {
            if(contractorChangeOpps.containsKey(contractor.Project__c)) {
                Contractor_Changes__c change = new Contractor_Changes__c(
                    Project__c = contractor.Project__c,
                    Contact__c = contractor.Contact__c,
                    Contractor__c = contractor.name,
                    Budget_Percentage__c = contractor.Budget_Percentage__c,
                    Cost__c = contractor.Cost__c,
                    Opportunity__c = contractorChangeOpps.get(contractor.Project__c).Id
                );
                contractorChangesToInsert.add(change);
            }
        }
        
        if(!contractorChangesToInsert.isEmpty()) {
            try {
                insert contractorChangesToInsert;
            } catch(Exception e) {
                // Handle any errors here
                System.debug('Error creating Contractor Changes records: ' + e.getMessage());
                // You might want to add custom error handling here
            }
        }
    }
}