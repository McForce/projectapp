public with sharing class OpportunityContractorHandler {
    
    public static void handleAfterInsert(List<Opportunity> newOpportunities) {
        // Validate CRUD permissions
        if (!Contractor_Changes__c.SObjectType.getDescribe().isCreateable()) {
            throw new SecurityException('Insufficient permissions to create Contractor Changes');
        }
        
        Set<Id> projectIds = new Set<Id>();
        for (Opportunity opp : newOpportunities) {
            if (opp.Project__c != null) {
                projectIds.add(opp.Project__c);
            }
        }
        
        if (projectIds.isEmpty()) {
            return;
        }
        
        // Get all contractors associated with these projects
        Map<Id, List<Contractor__c>> projectContractorsMap = new Map<Id, List<Contractor__c>>();
        for (Contractor__c contractor : [
            SELECT Id, Project__c, Cost__c
            FROM Contractor__c
            WHERE Project__c IN :projectIds
            WITH SECURITY_ENFORCED
        ]) {
            if (!projectContractorsMap.containsKey(contractor.Project__c)) {
                projectContractorsMap.put(contractor.Project__c, new List<Contractor__c>());
            }
            projectContractorsMap.get(contractor.Project__c).add(contractor);
        }
        
        List<Contractor_Changes__c> contractorChangesToInsert = new List<Contractor_Changes__c>();
        
        for (Opportunity opp : newOpportunities) {
            if (opp.Project__c != null && projectContractorsMap.containsKey(opp.Project__c)) {
                List<Contractor__c> contractors = projectContractorsMap.get(opp.Project__c);
                Decimal totalAmount = opp.Amount;
                Integer contractorCount = contractors.size();
                
                if (contractorCount > 0) {
                    Decimal equalShare = totalAmount / contractorCount;
                    Decimal equalPercentage = 100.0 / contractorCount;
                    
                    for (Contractor__c contractor : contractors) {
                        contractorChangesToInsert.add(new Contractor_Changes__c(
                            Opportunity__c = opp.Id,
                            Contractor__c = contractor.Id,
                            Cost__c = equalShare,
                            Budget_Percentage__c = equalPercentage,
                            Change_Type__c = 'Initial'
                        ));
                    }
                }
            }
        }
        
        if (!contractorChangesToInsert.isEmpty()) {
            insert contractorChangesToInsert;
        }
    }
}