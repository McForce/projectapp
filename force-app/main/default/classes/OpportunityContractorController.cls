public with sharing class OpportunityContractorController {
    
    @AuraEnabled(cacheable=true)
    public static List<Contractor_Changes__c> getContractorChanges(Id opportunityId) {
        // Check CRUD permissions
        if (!Schema.sObjectType.Contractor_Changes__c.isAccessible()) {
            throw new AuraHandledException('Insufficient permissions to access Contractor Changes');
        }
        
        return [
            SELECT Id, Contractor__r.Name, Cost__c, Budget_Percentage__c, 
                   Change_Type__c, Opportunity__c
            FROM Contractor_Changes__c
            WHERE Opportunity__c = :opportunityId
            WITH SECURITY_ENFORCED
        ];
    }
    
    @AuraEnabled(cacheable=true)
    public static Decimal getOpportunityAmount(Id opportunityId) {
        // Check CRUD permissions
        if (!Schema.sObjectType.Opportunity.isAccessible()) {
            throw new AuraHandledException('Insufficient permissions to access Opportunity');
        }
        
        Opportunity opp = [
            SELECT Amount 
            FROM Opportunity 
            WHERE Id = :opportunityId
            WITH SECURITY_ENFORCED
        ];
        return opp.Amount;
    }
    
    @AuraEnabled
    public static void updateMultipleContractorChanges(List<Contractor_Changes__c> contractorChanges) {
        // Check CRUD permissions
        if (!Schema.sObjectType.Contractor_Changes__c.isUpdateable()) {
            throw new AuraHandledException('Insufficient permissions to update Contractor Changes');
        }
        
        // Get all contractor changes for the opportunity to validate total
        Id opportunityId = contractorChanges[0].Opportunity__c;
        Opportunity opp = [SELECT Amount FROM Opportunity WHERE Id = :opportunityId WITH SECURITY_ENFORCED];
        
        Map<Id, Contractor_Changes__c> existingChanges = new Map<Id, Contractor_Changes__c>([
            SELECT Id, Cost__c 
            FROM Contractor_Changes__c 
            WHERE Opportunity__c = :opportunityId
            WITH SECURITY_ENFORCED
        ]);
        
        // Calculate new total
        Decimal newTotal = 0;
        for (Contractor_Changes__c cc : existingChanges.values()) {
            newTotal += cc.Cost__c;
        }
        
        // Update the changes map with new values
        for (Contractor_Changes__c newCC : contractorChanges) {
            if (existingChanges.containsKey(newCC.Id)) {
                newTotal = newTotal - existingChanges.get(newCC.Id).Cost__c + newCC.Cost__c;
                existingChanges.get(newCC.Id).Cost__c = newCC.Cost__c;
                existingChanges.get(newCC.Id).Change_Type__c = 'Reallocation';
            }
        }
        
        // Validate total matches opportunity amount
        if (newTotal != opp.Amount) {
            throw new AuraHandledException('Total contractor costs must equal the Opportunity Amount');
        }
        
        // Update records
        List<Contractor_Changes__c> toUpdate = new List<Contractor_Changes__c>();
        for (Contractor_Changes__c cc : contractorChanges) {
            if (existingChanges.containsKey(cc.Id)) {
                toUpdate.add(existingChanges.get(cc.Id));
            }
        }
        
        update toUpdate;
        
        // Recalculate budget percentages
        recalculateBudgetPercentages(opportunityId);
    }
    
    private static void recalculateBudgetPercentages(Id opportunityId) {
        List<Contractor_Changes__c> changes = [
            SELECT Id, Cost__c, Opportunity__r.Amount 
            FROM Contractor_Changes__c 
            WHERE Opportunity__c = :opportunityId
            WITH SECURITY_ENFORCED
        ];
        
        for (Contractor_Changes__c cc : changes) {
            if (cc.Opportunity__r.Amount > 0) {
                cc.Budget_Percentage__c = (cc.Cost__c / cc.Opportunity__r.Amount) * 100;
            }
        }
        
        update changes;
    }
}