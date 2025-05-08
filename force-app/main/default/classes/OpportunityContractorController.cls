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
    public static void updateContractorChange(Id contractorChangeId, Decimal newCost, Decimal opportunityAmount) {
        // First get all contractor changes for the opportunity to validate total cost
        Contractor_Changes__c currentChange = [
            SELECT Id, Cost__c, Budget_Percentage__c, Change_Type__c, Opportunity__c
            FROM Contractor_Changes__c
            WHERE Id = :contractorChangeId
            LIMIT 1
        ];

        // Get all contractor changes for the same opportunity
        List<Contractor_Changes__c> allChanges = [
            SELECT Id, Cost__c
            FROM Contractor_Changes__c
            WHERE Opportunity__c = :currentChange.Opportunity__c
            AND Id != :contractorChangeId
        ];

        // Calculate total cost including the new cost
        Decimal totalCost = newCost;
        for (Contractor_Changes__c change : allChanges) {
            totalCost += change.Cost__c;
        }

        // Validate total cost against opportunity amount
        if (totalCost != opportunityAmount) {
            throw new AuraHandledException('Total Contractor cost ($' + totalCost.setScale(2) + 
                ') must equal the Opportunity Amount ($' + opportunityAmount.setScale(2) + ')');
        }

        // Update Cost and Change Type
        currentChange.Cost__c = newCost;
        currentChange.Change_Type__c = 'Reallocation'; // Update Change Type when cost is modified
        currentChange.Budget_Percentage__c = (newCost / opportunityAmount) * 100;

        // Save changes
        update currentChange;
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