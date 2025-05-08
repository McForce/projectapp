public class ContractorBillingWrapper implements Comparable {
    @AuraEnabled public Id contractorId { get; set; }
    @AuraEnabled public String contractorName { get; set; }
    @AuraEnabled public Decimal budgetPercentage { get; set; }
    @AuraEnabled public Decimal cost { get; set; }
    @AuraEnabled public Date lastBilledDate { get; set; }
    @AuraEnabled public Id contactId { get; set; }
    @AuraEnabled public String contactName { get; set; }
    
    public ContractorBillingWrapper(Contractor__c contractor, Contractor_Billing__c latestBilling) {
        this.contractorId = contractor.Id;
        this.contractorName = contractor.Name;
        this.budgetPercentage = contractor.Budget_Percentage__c;
        this.cost = contractor.Cost__c;
        this.contactId = contractor.Contact__c;
        this.contactName = contractor.Contact__r.Name;
        
        if (latestBilling != null) {
            this.lastBilledDate = latestBilling.Last_Billed_Up_To__c;
        }
    }
    
    // Implement compareTo for sorting by lastBilledDate in descending order
    public Integer compareTo(Object compareTo) {
        ContractorBillingWrapper compareToWrapper = (ContractorBillingWrapper)compareTo;
        
        // Handle null dates (null dates should appear last)
        if (this.lastBilledDate == null && compareToWrapper.lastBilledDate == null) {
            return this.contractorName.compareTo(compareToWrapper.contractorName);
        } else if (this.lastBilledDate == null) {
            return 1;
        } else if (compareToWrapper.lastBilledDate == null) {
            return -1;
        }
        
        // Sort by date descending, then by name if dates are equal
        if (this.lastBilledDate > compareToWrapper.lastBilledDate) {
            return -1;
        } else if (this.lastBilledDate < compareToWrapper.lastBilledDate) {
            return 1;
        } else {
            return this.contractorName.compareTo(compareToWrapper.contractorName);
        }
    }
}