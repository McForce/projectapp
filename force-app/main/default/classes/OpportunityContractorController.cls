public with sharing class OpportunityContractorController {
    @AuraEnabled(cacheable=true)
    public static List<ContractorChangeWrapper> getContractorChanges(Id opportunityId) {
        List<ContractorChangeWrapper> wrappers = new List<ContractorChangeWrapper>();
        
        // Query Contractor Changes for the Opportunity
        List<Contractor_Changes__c> contractorChanges = [
            SELECT Id, Contractor__r.Name, Cost__c, Budget_Percentage__c, Change_Type__c
            FROM Contractor_Changes__c
            WHERE Opportunity__c = :opportunityId
            ORDER BY Contractor__r.Name
        ];
        
        // Create wrappers
        for (Contractor_Changes__c change : contractorChanges) {
            ContractorChangeWrapper wrapper = new ContractorChangeWrapper();
            wrapper.id = change.Id;
            wrapper.name = change.Contractor__r.Name;
            wrapper.cost = change.Cost__c;
            wrapper.budgetPercentage = change.Budget_Percentage__c;
            wrapper.changeType = change.Change_Type__c;
            wrappers.add(wrapper);
        }
        
        return wrappers;
    }

    @AuraEnabled(cacheable=true)
    public static Decimal getOpportunityAmount(Id opportunityId) {
        Opportunity opp = [
            SELECT Amount
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];
        return opp.Amount;
    }

    @AuraEnabled
    public static void updateMultipleContractorChanges(List<ContractorChangeWrapper> changes, Id opportunityId) {
        if (changes == null || changes.isEmpty()) {
            throw new AuraHandledException('No changes provided for update');
        }

        // Get opportunity amount for validation
        Decimal opportunityAmount = getOpportunityAmount(opportunityId);
        
        // Get all contractor changes for the opportunity
        List<Contractor_Changes__c> allCurrentChanges = [
            SELECT Id, Cost__c
            FROM Contractor_Changes__c
            WHERE Opportunity__c = :opportunityId
        ];
        
        // Create map of current changes
        Map<Id, Contractor_Changes__c> currentChangesMap = new Map<Id, Contractor_Changes__c>(allCurrentChanges);
        
        // Calculate total cost including all changes
        Decimal totalCost = 0;
        Map<Id, Contractor_Changes__c> updatesMap = new Map<Id, Contractor_Changes__c>();
        
        // First pass: prepare updates and calculate total
        for (ContractorChangeWrapper change : changes) {
            Contractor_Changes__c updateChange = new Contractor_Changes__c(
                Id = change.id,
                Cost__c = change.cost,
                Change_Type__c = 'Reallocation',
                Budget_Percentage__c = (change.cost / opportunityAmount) * 100
            );
            updatesMap.put(change.id, updateChange);
            totalCost += change.cost;
        }
        
        // Add costs from unchanged records
        for (Contractor_Changes__c current : allCurrentChanges) {
            if (!updatesMap.containsKey(current.Id)) {
                totalCost += current.Cost__c;
            }
        }
        
        // Validate total cost against opportunity amount
        if (Math.abs(totalCost - opportunityAmount) > 0.01) {
            throw new AuraHandledException('Total Contractor cost ($' + totalCost.setScale(2) + 
                ') must equal the Opportunity Amount ($' + opportunityAmount.setScale(2) + ')');
        }
        
        // Perform update
        if (!updatesMap.isEmpty()) {
            update updatesMap.values();
        }
    }

    // Keep the original single update method for backward compatibility
    @AuraEnabled
    public static void updateContractorChange(Id contractorChangeId, Decimal newCost, Decimal opportunityAmount) {
        List<ContractorChangeWrapper> changes = new List<ContractorChangeWrapper>();
        ContractorChangeWrapper wrapper = new ContractorChangeWrapper();
        wrapper.id = contractorChangeId;
        wrapper.cost = newCost;
        
        // Get the opportunity ID from the contractor change
        Contractor_Changes__c change = [SELECT Opportunity__c FROM Contractor_Changes__c WHERE Id = :contractorChangeId];
        updateMultipleContractorChanges(changes, change.Opportunity__c);
    }

    // Wrapper class for UI data
    public class ContractorChangeWrapper {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public Decimal cost { get; set; }
        @AuraEnabled public Decimal budgetPercentage { get; set; }
        @AuraEnabled public String changeType { get; set; }
    }
}