public with sharing class OpportunityContractorChangeController {
    
    @AuraEnabled(cacheable=true)
    public static OpportunityWrapper getContractorChanges(Id opportunityId) {
        // Existing getContractorChanges method remains the same
    }
    
    @AuraEnabled
    public static String updateContractorChanges(List<OpportunityContractorChangeWrapper> changes, Id opportunityId) {
        System.debug('Starting updateContractorChanges');
        System.debug('Changes received: ' + JSON.serialize(changes));
        System.debug('Opportunity ID: ' + opportunityId);
        
        // Validate input
        if (changes == null || changes.isEmpty() || opportunityId == null) {
            throw new AuraHandledException('Invalid input parameters');
        }
        
        try {
            // Query opportunity amount first
            Opportunity opp = [
                SELECT Id, Amount 
                FROM Opportunity 
                WHERE Id = :opportunityId
                WITH SECURITY_ENFORCED
            ];
            System.debug('Opportunity Amount: ' + opp.Amount);
            
            // Prepare records for update and calculate total
            List<Contractor_Changes__c> recordsToUpdate = new List<Contractor_Changes__c>();
            Decimal totalCost = 0;
            
            for (OpportunityContractorChangeWrapper wrapper : changes) {
                totalCost += wrapper.cost;
                
                if (wrapper.isDirty) {
                    System.debug('Processing dirty record: ' + wrapper.recordId);
                    
                    Contractor_Changes__c change = new Contractor_Changes__c(
                        Id = wrapper.recordId,
                        Cost__c = wrapper.cost,
                        Change_Type__c = 'Reallocation'
                    );
                    recordsToUpdate.add(change);
                }
            }
            
            System.debug('Total Cost: ' + totalCost);
            System.debug('Records to update: ' + recordsToUpdate);
            
            // Validate total cost matches opportunity amount
            if (Math.abs(totalCost - opp.Amount) > 0.01) {
                String errorMsg = String.format('Total cost ({0}) must equal opportunity amount ({1})', 
                    new List<String>{totalCost.setScale(2).format(), opp.Amount.setScale(2).format()});
                throw new AuraHandledException(errorMsg);
            }
            
            // Update records if there are any changes
            if (!recordsToUpdate.isEmpty()) {
                try {
                    update recordsToUpdate;
                    System.debug('Update successful');
                    return 'Success';
                } catch (Exception e) {
                    System.debug('Error during update: ' + e.getMessage());
                    System.debug('Error stack trace: ' + e.getStackTraceString());
                    throw new AuraHandledException('Error updating records: ' + e.getMessage());
                }
            } else {
                System.debug('No records to update');
                return 'No changes to save';
            }
            
        } catch (Exception e) {
            System.debug('Error in updateContractorChanges: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    
    public class OpportunityWrapper {
        @AuraEnabled public List<OpportunityContractorChangeWrapper> changes { get; set; }
        @AuraEnabled public Decimal totalCost { get; set; }
        @AuraEnabled public Decimal opportunityAmount { get; set; }
        
        public OpportunityWrapper(List<OpportunityContractorChangeWrapper> changes, 
                                Decimal totalCost, 
                                Decimal opportunityAmount) {
            this.changes = changes;
            this.totalCost = totalCost;
            this.opportunityAmount = opportunityAmount;
        }
    }
}