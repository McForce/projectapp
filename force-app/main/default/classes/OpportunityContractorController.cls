public with sharing class OpportunityContractorController {
    @AuraEnabled
    public static ContractorChangeWrapper getContractorChanges(Id opportunityId) {
        // Verify CRUD permissions
        if (!Schema.sObjectType.Contractor_Changes__c.isAccessible() || 
            !Schema.sObjectType.Opportunity.isAccessible()) {
            throw new AuraHandledException('Insufficient permissions to access records');
        }
        
        try {
            Opportunity opp = [SELECT Id, Amount FROM Opportunity WHERE Id = :opportunityId WITH SECURITY_ENFORCED];
            List<Contractor_Changes__c> contractorChanges = [
                SELECT Id, Name, Contractor__r.Name, Cost__c, Change_Type__c
                FROM Contractor_Changes__c 
                WHERE Opportunity__c = :opportunityId 
                WITH SECURITY_ENFORCED
            ];
            
            return new ContractorChangeWrapper(opp, contractorChanges);
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving contractor changes: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void updateContractorChanges(Id opportunityId, List<Contractor_Changes__c> changes) {
        // Verify CRUD permissions
        if (!Schema.sObjectType.Contractor_Changes__c.isUpdateable()) {
            throw new AuraHandledException('Insufficient permissions to update records');
        }
        
        try {
            // Get Opportunity amount for validation
            Opportunity opp = [SELECT Amount FROM Opportunity WHERE Id = :opportunityId WITH SECURITY_ENFORCED];
            
            // Calculate total cost
            Decimal totalCost = 0;
            for(Contractor_Changes__c change : changes) {
                totalCost += change.Cost__c;
                // Set Change Type to Reallocation if cost has changed
                change.Change_Type__c = 'Reallocation';
            }
            
            // Validate total cost equals opportunity amount
            if (totalCost != opp.Amount) {
                throw new AuraHandledException('Total cost must equal opportunity amount');
            }
            
            update changes;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating contractor changes: ' + e.getMessage());
        }
    }
    
    public class ContractorChangeWrapper {
        @AuraEnabled public Opportunity opportunity { get; set; }
        @AuraEnabled public List<Contractor_Changes__c> contractorChanges { get; set; }
        @AuraEnabled public Decimal totalCost { get; set; }
        
        public ContractorChangeWrapper(Opportunity opp, List<Contractor_Changes__c> changes) {
            this.opportunity = opp;
            this.contractorChanges = changes;
            this.totalCost = 0;
            
            for(Contractor_Changes__c change : changes) {
                this.totalCost += change.Cost__c;
            }
        }
    }
}