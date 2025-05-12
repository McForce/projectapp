public with sharing class OpportunityContractorHandler {
    public class ContractorChangeDTO {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String contractorName { get; set; }
        @AuraEnabled public Decimal cost { get; set; }
        @AuraEnabled public Decimal budgetPercentage { get; set; }
        @AuraEnabled public String changeType { get; set; }
        
        public ContractorChangeDTO(Contractor_Changes__c change, Decimal opportunityAmount) {
            this.id = change.Id;
            this.contractorName = change.Contractor__r.Name;
            this.cost = change.Cost__c;
            this.changeType = change.Change_Type__c;
            this.budgetPercentage = opportunityAmount > 0 ? (change.Cost__c / opportunityAmount) * 100 : 0;
        }
    }
    
    public static List<ContractorChangeDTO> prepareContractorChangeData(List<Contractor_Changes__c> changes, Decimal opportunityAmount) {
        List<ContractorChangeDTO> dtos = new List<ContractorChangeDTO>();
        for(Contractor_Changes__c change : changes) {
            dtos.add(new ContractorChangeDTO(change, opportunityAmount));
        }
        return dtos;
    }
}