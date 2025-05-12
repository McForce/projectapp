public with sharing class OpportunityContractorController {
    
    @AuraEnabled(cacheable=true)
    public static List<ContractorChangeWrapper> getContractorChanges(Id opportunityId) {
        // Verify CRUD permissions
        if (!Schema.sObjectType.Contractor_Changes__c.isAccessible()) {
            throw new AuraHandledException('Insufficient permissions to access Contractor Changes');
        }
        
        List<ContractorChangeWrapper> wrapperList = new List<ContractorChangeWrapper>();
        
        try {
            List<Contractor_Changes__c> contractorChanges = [
                SELECT Id, Contractor__r.Name, Cost__c, Change_Type__c
                FROM Contractor_Changes__c
                WHERE Opportunity__c = :opportunityId
            ];
            
            Decimal opportunityAmount = getOpportunityAmount(opportunityId);
            
            for (Contractor_Changes__c cc : contractorChanges) {
                wrapperList.add(new ContractorChangeWrapper(cc, opportunityAmount));
            }
            
            return wrapperList;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching contractor changes: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Decimal getOpportunityAmount(Id opportunityId) {
        // Verify CRUD permissions
        if (!Schema.sObjectType.Opportunity.isAccessible()) {
            throw new AuraHandledException('Insufficient permissions to access Opportunity');
        }
        
        try {
            Opportunity opp = [SELECT Amount FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
            return opp.Amount;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching opportunity amount: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String updateContractorChanges(List<ContractorChangeWrapper> changes, Id opportunityId) {
        // Verify CRUD permissions
        if (!Schema.sObjectType.Contractor_Changes__c.isUpdateable()) {
            throw new AuraHandledException('Insufficient permissions to update Contractor Changes');
        }
        
        try {
            Decimal opportunityAmount = getOpportunityAmount(opportunityId);
            Decimal totalCost = 0;
            List<Contractor_Changes__c> recordsToUpdate = new List<Contractor_Changes__c>();
            
            for (ContractorChangeWrapper wrapper : changes) {
                totalCost += wrapper.cost;
                
                Contractor_Changes__c cc = new Contractor_Changes__c(
                    Id = wrapper.recordId,
                    Cost__c = wrapper.cost,
                    Change_Type__c = 'Reallocation'
                );
                recordsToUpdate.add(cc);
            }
            
            // Validate total cost equals opportunity amount
            if (totalCost != opportunityAmount) {
                throw new AuraHandledException('Total cost must equal the Opportunity amount of ' + opportunityAmount);
            }
            
            update recordsToUpdate;
            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class ContractorChangeWrapper {
        @AuraEnabled public Id recordId { get; set; }
        @AuraEnabled public String contractorName { get; set; }
        @AuraEnabled public Decimal cost { get; set; }
        @AuraEnabled public Decimal budgetPercentage { get; set; }
        @AuraEnabled public String changeType { get; set; }
        
        public ContractorChangeWrapper(Contractor_Changes__c cc, Decimal opportunityAmount) {
            this.recordId = cc.Id;
            this.contractorName = cc.Contractor__r.Name;
            this.cost = cc.Cost__c;
            this.changeType = cc.Change_Type__c;
            this.budgetPercentage = opportunityAmount != 0 ? (cc.Cost__c / opportunityAmount) * 100 : 0;
        }
    }
}