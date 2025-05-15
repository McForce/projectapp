public with sharing class OpportunityContractorChangesHandler {
    
    public static List<OpportunityContractorChangesController.ContractorChangeWrapper> getContractorChanges(Id opportunityId) {
        // Validate CRUD permissions
        if (!Contractor_Changes__c.SObjectType.getDescribe().isAccessible()) {
            throw new AuraHandledException('Insufficient permissions to access Contractor Changes');
        }
        
        List<OpportunityContractorChangesController.ContractorChangeWrapper> wrappers = new List<OpportunityContractorChangesController.ContractorChangeWrapper>();
        
        Decimal oppAmount = getOpportunityAmount(opportunityId);
        
        for (Contractor_Changes__c cc : [
            SELECT Id, Contractor__r.Name, Cost__c, Budget_Percentage__c, Change_Type__c
            FROM Contractor_Changes__c 
            WHERE Project__r.Opportunity__c = :opportunityId
            WITH SECURITY_ENFORCED
        ]) {
            OpportunityContractorChangesController.ContractorChangeWrapper wrapper = new OpportunityContractorChangesController.ContractorChangeWrapper();
            wrapper.id = cc.Id;
            wrapper.contractorName = cc.Contractor__r.Name;
            wrapper.cost = cc.Cost__c;
            wrapper.budgetPercentage = oppAmount > 0 ? (cc.Cost__c / oppAmount) * 100 : 0;
            wrapper.changeType = cc.Change_Type__c;
            wrappers.add(wrapper);
        }
        
        return wrappers;
    }
    
    public static Decimal getOpportunityAmount(Id opportunityId) {
        // Validate CRUD permissions
        if (!Opportunity.SObjectType.getDescribe().isAccessible()) {
            throw new AuraHandledException('Insufficient permissions to access Opportunity');
        }
        
        Opportunity opp = [
            SELECT Amount 
            FROM Opportunity 
            WHERE Id = :opportunityId 
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        
        return opp.Amount;
    }
    
    public static void updateContractorChanges(List<OpportunityContractorChangesController.ContractorChangeWrapper> contractorChanges) {
        // Validate CRUD permissions
        if (!Contractor_Changes__c.SObjectType.getDescribe().isUpdateable()) {
            throw new AuraHandledException('Insufficient permissions to update Contractor Changes');
        }
        
        List<Contractor_Changes__c> recordsToUpdate = new List<Contractor_Changes__c>();
        
        for (OpportunityContractorChangesController.ContractorChangeWrapper wrapper : contractorChanges) {
            Contractor_Changes__c cc = new Contractor_Changes__c(
                Id = wrapper.id,
                Cost__c = wrapper.cost,
                Change_Type__c = 'Reallocation' // Set to Reallocation when cost is updated
            );
            recordsToUpdate.add(cc);
        }
        
        if (!recordsToUpdate.isEmpty()) {
            try {
                update recordsToUpdate;
            } catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        }
    }
}