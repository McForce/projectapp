public with sharing class OpportunityContractorHandler {
    
    /**
     * @description Aggregates and processes contractor change data
     * @param contractorChanges List of Contractor Change records
     * @param opportunityAmount The parent opportunity amount
     * @return OpportunityContractorWrapper containing processed data
     */
    public static OpportunityContractorController.OpportunityContractorWrapper processContractorData(
        List<Contractor_Changes__c> contractorChanges,
        Decimal opportunityAmount
    ) {
        Decimal totalCost = 0;
        List<OpportunityContractorController.ContractorChangeDTO> contractorDTOs = new List<OpportunityContractorController.ContractorChangeDTO>();
        
        for(Contractor_Changes__c cc : contractorChanges) {
            Decimal budgetPercentage = calculateBudgetPercentage(cc.Cost__c, opportunityAmount);
            contractorDTOs.add(createContractorDTO(cc, budgetPercentage));
            totalCost += cc.Cost__c;
        }
        
        return new OpportunityContractorController.OpportunityContractorWrapper(
            contractorDTOs,
            opportunityAmount,
            totalCost
        );
    }
    
    /**
     * @description Validates contractor changes before update
     * @param changes List of ContractorChangeDTO objects to validate
     * @param opportunityAmount The parent opportunity amount
     * @return ValidationResult containing success status and error message if any
     */
    public static ValidationResult validateContractorChanges(
        List<OpportunityContractorController.ContractorChangeDTO> changes,
        Decimal opportunityAmount
    ) {
        Decimal totalCost = 0;
        for(OpportunityContractorController.ContractorChangeDTO dto : changes) {
            totalCost += dto.cost;
        }
        
        if(totalCost != opportunityAmount) {
            return new ValidationResult(
                false,
                'Total cost (' + totalCost + ') must equal the Opportunity amount (' + opportunityAmount + ')'
            );
        }
        
        return new ValidationResult(true, '');
    }
    
    /**
     * @description Prepares contractor changes for update
     * @param changes List of ContractorChangeDTO objects
     * @return List of Contractor_Changes__c records ready for update
     */
    public static List<Contractor_Changes__c> prepareContractorUpdates(
        List<OpportunityContractorController.ContractorChangeDTO> changes
    ) {
        List<Contractor_Changes__c> recordsToUpdate = new List<Contractor_Changes__c>();
        
        for(OpportunityContractorController.ContractorChangeDTO dto : changes) {
            recordsToUpdate.add(new Contractor_Changes__c(
                Id = dto.recordId,
                Cost__c = dto.cost,
                Change_Type__c = 'Reallocation'
            ));
        }
        
        return recordsToUpdate;
    }
    
    /**
     * @description Calculates the budget percentage
     * @param cost The contractor cost
     * @param opportunityAmount The parent opportunity amount
     * @return Decimal representing the budget percentage
     */
    private static Decimal calculateBudgetPercentage(Decimal cost, Decimal opportunityAmount) {
        return (opportunityAmount != 0) ? (cost / opportunityAmount) * 100 : 0;
    }
    
    /**
     * @description Creates a DTO from a Contractor Change record
     * @param cc The Contractor Change record
     * @param budgetPercentage The calculated budget percentage
     * @return ContractorChangeDTO
     */
    private static OpportunityContractorController.ContractorChangeDTO createContractorDTO(
        Contractor_Changes__c cc,
        Decimal budgetPercentage
    ) {
        return new OpportunityContractorController.ContractorChangeDTO(
            cc.Id,
            cc.Contractor__r.Name,
            cc.Cost__c,
            budgetPercentage,
            cc.Change_Type__c
        );
    }
    
    /**
     * @description Wrapper class for validation results
     */
    public class ValidationResult {
        public Boolean isValid { get; private set; }
        public String errorMessage { get; private set; }
        
        public ValidationResult(Boolean isValid, String errorMessage) {
            this.isValid = isValid;
            this.errorMessage = errorMessage;
        }
    }
}