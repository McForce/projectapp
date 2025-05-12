trigger OpportunityTrigger on Opportunity (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        OpportunityTriggerHandler.handleContractorChanges(Trigger.new);
        if (Trigger.isAfter && Trigger.isInsert) {
            OpportunityContractorHandler.handleAfterInsert(Trigger.new);
        }
    }
}