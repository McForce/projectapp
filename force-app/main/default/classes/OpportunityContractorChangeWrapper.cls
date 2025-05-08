public class OpportunityContractorChangeWrapper {
    @AuraEnabled public Id recordId { get; set; }
    @AuraEnabled public String contractorName { get; set; }
    @AuraEnabled public Decimal cost { get; set; }
    @AuraEnabled public Decimal budgetPercentage { get; set; }
    @AuraEnabled public String changeType { get; set; }
    @AuraEnabled public Boolean isDirty { get; set; }
    
    public OpportunityContractorChangeWrapper(Contractor_Changes__c change, Decimal opportunityAmount) {
        this.recordId = change.Id;
        this.contractorName = change.Contractor__r.Name;
        this.cost = change.Cost__c;
        this.changeType = change.Change_Type__c;
        this.isDirty = false;
        
        // Calculate budget percentage
        if (opportunityAmount != null && opportunityAmount != 0) {
            this.budgetPercentage = (change.Cost__c / opportunityAmount) * 100;
        }
    }
}