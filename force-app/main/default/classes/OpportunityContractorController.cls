public with sharing class OpportunityContractorController {
    
    @AuraEnabled(cacheable=true)
    public static List<Contractor_Changes__c> getContractorChanges(Id opportunityId) {
        return [
            SELECT Id, 
                   Contractor__c, 
                   Contractor__r.Name, 
                   Cost__c, 
                   Budget_Percentage__c, 
                   Change_Type__c
            FROM Contractor_Changes__c
            WHERE Opportunity__c = :opportunityId
            ORDER BY CreatedDate
        ];
    }
    
    @AuraEnabled(cacheable=true)
    public static Decimal getOpportunityAmount(Id opportunityId) {
        Opportunity opp = [
            SELECT Amount 
            FROM Opportunity 
            WHERE Id = :opportunityId 
            LIMIT 1
        ];
        return opp.Amount != null ? opp.Amount : 0;
    }
    
    @AuraEnabled
    public static List<Contractor_Changes__c> updateContractorChanges(List<Contractor_Changes__c> contractorChanges, Id opportunityId) {
        // Validate total cost matches opportunity amount
        Decimal opportunityAmount = getOpportunityAmount(opportunityId);
        Decimal totalCost = 0;
        
        for (Contractor_Changes__c change : contractorChanges) {
            // Set Change Type to Reallocation
            change.Change_Type__c = 'Reallocation';
            
            // Accumulate total cost
            totalCost += (change.Cost__c != null ? change.Cost__c : 0);
        }
        
        // Throw error if total cost doesn't match opportunity amount
        if (Math.abs(totalCost - opportunityAmount) > 0.01) {
            throw new AuraHandledException('Total contractor costs must equal the Opportunity Amount. Current total: ' + totalCost + ', Opportunity Amount: ' + opportunityAmount);
        }
        
        // Recalculate budget percentages
        for (Contractor_Changes__c change : contractorChanges) {
            change.Budget_Percentage__c = (change.Cost__c / opportunityAmount) * 100;
        }
        
        try {
            update contractorChanges;
            return contractorChanges;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating Contractor Changes: ' + e.getMessage());
        }
    }
}