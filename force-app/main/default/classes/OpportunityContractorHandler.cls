public with sharing class OpportunityContractorHandler {
    
    /**
     * @description Checks if user has read access to necessary objects
     * @return Boolean indicating if user has access
     */
    public static Boolean hasReadAccess() {
        return Schema.sObjectType.Contractor_Changes__c.isAccessible() 
            && Schema.sObjectType.Opportunity.isAccessible();
    }
    
    /**
     * @description Checks if user has update access to necessary objects
     * @return Boolean indicating if user has access
     */
    public static Boolean hasUpdateAccess() {
        return Schema.sObjectType.Contractor_Changes__c.isUpdateable();
    }
    
    /**
     * @description Gets contractor data for an opportunity
     * @param opportunityId The ID of the opportunity
     * @return ContractorDataWrapper containing all necessary data
     */
    public static OpportunityContractorController.ContractorDataWrapper getContractorData(Id opportunityId) {
        // Get Opportunity Amount
        Opportunity opp = [
            SELECT Id, Amount 
            FROM Opportunity 
            WHERE Id = :opportunityId 
            WITH SECURITY_ENFORCED
        ];
        
        // Get Contractor Changes
        List<Contractor_Changes__c> contractorChanges = [
            SELECT Id, Name, Contractor__r.Name, Cost__c, Change_Type__c 
            FROM Contractor_Changes__c 
            WHERE Opportunity__c = :opportunityId
            WITH SECURITY_ENFORCED
        ];
        
        return aggregateContractorData(contractorChanges, opp.Amount);
    }
    
    /**
     * @description Processes updates to contractor changes
     * @param changes List of contractor changes to update
     * @param opportunityId The ID of the parent opportunity
     */
    public static void processUpdates(
        List<OpportunityContractorController.ContractorChangeRecord> changes, 
        Id opportunityId
    ) {
        // Get Opportunity Amount for validation
        Opportunity opp = [
            SELECT Amount 
            FROM Opportunity 
            WHERE Id = :opportunityId 
            WITH SECURITY_ENFORCED
        ];
        
        // Validate total cost
        validateTotalCost(changes, opp.Amount);
        
        // Prepare records for update
        List<Contractor_Changes__c> recordsToUpdate = prepareRecordsForUpdate(changes);
        
        // Perform update
        update recordsToUpdate;
    }
    
    /**
     * @description Aggregates contractor data into a wrapper
     * @param contractorChanges List of contractor change records
     * @param opportunityAmount The opportunity amount
     * @return ContractorDataWrapper
     */
    private static OpportunityContractorController.ContractorDataWrapper aggregateContractorData(
        List<Contractor_Changes__c> contractorChanges,
        Decimal opportunityAmount
    ) {
        Decimal totalCost = 0;
        List<OpportunityContractorController.ContractorChangeRecord> records = 
            new List<OpportunityContractorController.ContractorChangeRecord>();
        
        for(Contractor_Changes__c cc : contractorChanges) {
            Decimal budgetPercentage = calculateBudgetPercentage(cc.Cost__c, opportunityAmount);
            records.add(createContractorRecord(cc, budgetPercentage));
            totalCost += cc.Cost__c;
        }
        
        OpportunityContractorController.ContractorDataWrapper wrapper = 
            new OpportunityContractorController.ContractorDataWrapper();
        wrapper.contractorChanges = records;
        wrapper.opportunityAmount = opportunityAmount;
        wrapper.totalCost = totalCost;
        
        return wrapper;
    }
    
    /**
     * @description Validates that total cost matches opportunity amount
     * @param changes List of contractor changes
     * @param opportunityAmount The opportunity amount
     */
    private static void validateTotalCost(
        List<OpportunityContractorController.ContractorChangeRecord> changes,
        Decimal opportunityAmount
    ) {
        Decimal totalCost = 0;
        for(OpportunityContractorController.ContractorChangeRecord record : changes) {
            totalCost += record.cost;
        }
        
        if(totalCost != opportunityAmount) {
            throw new AuraHandledException(
                'Total cost (' + totalCost + ') must equal the Opportunity amount (' + 
                opportunityAmount + ')'
            );
        }
    }
    
    /**
     * @description Prepares records for update
     * @param changes List of contractor changes
     * @return List<Contractor_Changes__c>
     */
    private static List<Contractor_Changes__c> prepareRecordsForUpdate(
        List<OpportunityContractorController.ContractorChangeRecord> changes
    ) {
        List<Contractor_Changes__c> recordsToUpdate = new List<Contractor_Changes__c>();
        
        for(OpportunityContractorController.ContractorChangeRecord record : changes) {
            recordsToUpdate.add(new Contractor_Changes__c(
                Id = record.recordId,
                Cost__c = record.cost,
                Change_Type__c = 'Reallocation'
            ));
        }
        
        return recordsToUpdate;
    }
    
    /**
     * @description Calculates budget percentage
     * @param cost The cost value
     * @param opportunityAmount The opportunity amount
     * @return Decimal
     */
    private static Decimal calculateBudgetPercentage(Decimal cost, Decimal opportunityAmount) {
        return (opportunityAmount != 0) ? (cost / opportunityAmount) * 100 : 0;
    }
    
    /**
     * @description Creates a contractor record from a Contractor_Changes__c record
     * @param cc The contractor change record
     * @param budgetPercentage The calculated budget percentage
     * @return ContractorChangeRecord
     */
    private static OpportunityContractorController.ContractorChangeRecord createContractorRecord(
        Contractor_Changes__c cc,
        Decimal budgetPercentage
    ) {
        OpportunityContractorController.ContractorChangeRecord record = 
            new OpportunityContractorController.ContractorChangeRecord();
        record.recordId = cc.Id;
        record.contractorName = cc.Contractor__r.Name;
        record.cost = cc.Cost__c;
        record.budgetPercentage = budgetPercentage;
        record.changeType = cc.Change_Type__c;
        return record;
    }
}