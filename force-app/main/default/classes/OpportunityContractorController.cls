public with sharing class OpportunityContractorController {
    
    @AuraEnabled
    public static OpportunityContractorWrapper getContractorChanges(Id opportunityId) {
        // Validate CRUD permissions
        if (!Schema.sObjectType.Contractor_Changes__c.isAccessible() || 
            !Schema.sObjectType.Opportunity.isAccessible()) {
            throw new AuraHandledException('Insufficient permissions to access records');
        }
        
        try {
            // Get Opportunity Amount
            Opportunity opp = [SELECT Id, Amount FROM Opportunity WHERE Id = :opportunityId WITH SECURITY_ENFORCED];
            
            // Get Contractor Changes
            List<Contractor_Changes__c> contractorChanges = [
                SELECT Id, Name, Contractor__r.Name, Cost__c, Change_Type__c 
                FROM Contractor_Changes__c 
                WHERE Opportunity__c = :opportunityId
                WITH SECURITY_ENFORCED
            ];
            
            // Use helper class to process data
            return OpportunityContractorHandler.processContractorData(
                contractorChanges,
                opp.Amount
            );
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void updateContractorChanges(List<ContractorChangeDTO> changes, Id opportunityId) {
        // Validate CRUD permissions
        if (!Schema.sObjectType.Contractor_Changes__c.isUpdateable()) {
            throw new AuraHandledException('Insufficient permissions to update records');
        }
        
        try {
            // Get Opportunity Amount for validation
            Opportunity opp = [SELECT Amount FROM Opportunity WHERE Id = :opportunityId WITH SECURITY_ENFORCED];
            
            // Validate changes
            OpportunityContractorHandler.ValidationResult validationResult = 
                OpportunityContractorHandler.validateContractorChanges(changes, opp.Amount);
            
            if (!validationResult.isValid) {
                throw new AuraHandledException(validationResult.errorMessage);
            }
            
            // Prepare and perform update
            List<Contractor_Changes__c> recordsToUpdate = 
                OpportunityContractorHandler.prepareContractorUpdates(changes);
            
            update recordsToUpdate;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    // Wrapper classes remain the same...
    public class OpportunityContractorWrapper {
        @AuraEnabled public List<ContractorChangeDTO> contractorChanges { get; set; }
        @AuraEnabled public Decimal opportunityAmount { get; set; }
        @AuraEnabled public Decimal totalCost { get; set; }
        
        public OpportunityContractorWrapper(
            List<ContractorChangeDTO> contractorChanges,
            Decimal opportunityAmount,
            Decimal totalCost
        ) {
            this.contractorChanges = contractorChanges;
            this.opportunityAmount = opportunityAmount;
            this.totalCost = totalCost;
        }
    }
    
    public class ContractorChangeDTO {
        @AuraEnabled public Id recordId { get; set; }
        @AuraEnabled public String contractorName { get; set; }
        @AuraEnabled public Decimal cost { get; set; }
        @AuraEnabled public Decimal budgetPercentage { get; set; }
        @AuraEnabled public String changeType { get; set; }
        
        public ContractorChangeDTO(
            Id recordId,
            String contractorName,
            Decimal cost,
            Decimal budgetPercentage,
            String changeType
        ) {
            this.recordId = recordId;
            this.contractorName = contractorName;
            this.cost = cost;
            this.budgetPercentage = budgetPercentage;
            this.changeType = changeType;
        }
    }
}