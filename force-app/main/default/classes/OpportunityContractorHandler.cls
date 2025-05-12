public with sharing class OpportunityContractorHandler {
    
    public static void handleAfterInsert(List<Opportunity> newOpportunities) {
        // Check CRUD permissions
        if (!Schema.sObjectType.Contractor_Changes__c.isCreateable()) {
            throw new AuraHandledException('Insufficient permissions to create Contractor Changes');
        }
        
        List<Contractor_Changes__c> contractorChangesToCreate = new List<Contractor_Changes__c>();
        
        for (Opportunity opp : newOpportunities) {
            if (opp.Amount > 0) {
                // Query existing contractors for the project
                List<Contractor__c> contractors = [
                    SELECT Id, Name, Cost__c
                    FROM Contractor__c
                    WHERE Project__c = :opp.Project__c
                    WITH SECURITY_ENFORCED
                ];
                
                if (!contractors.isEmpty()) {
                    Decimal remainingAmount = opp.Amount;
                    Integer contractorCount = contractors.size();
                    
                    for (Contractor__c contractor : contractors) {
                        Decimal contractorAmount;
                        if (contractorCount > 1) {
                            contractorAmount = remainingAmount / contractorCount;
                            remainingAmount -= contractorAmount;
                            contractorCount--;
                        } else {
                            contractorAmount = remainingAmount;
                        }
                        
                        contractorChangesToCreate.add(new Contractor_Changes__c(
                            Opportunity__c = opp.Id,
                            Contractor__c = contractor.Id,
                            Cost__c = contractorAmount,
                            Budget_Percentage__c = (contractorAmount / opp.Amount) * 100,
                            Change_Type__c = 'Initial',
                            Project__c = opp.Project__c
                        ));
                    }
                }
            }
        }
        
        if (!contractorChangesToCreate.isEmpty()) {
            insert contractorChangesToCreate;
        }
    }
}