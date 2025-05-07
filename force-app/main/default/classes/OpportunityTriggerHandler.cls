public without sharing class OpportunityTriggerHandler {
    public static void handleContractorChanges(List<Opportunity> newOpportunities) {
        // Create instance of service class to handle business logic
        OpportunityContractorService contractorService = new OpportunityContractorService();
        
        // Filter opportunities that are of type 'Contractor Changes'
        List<Opportunity> contractorChangeOpps = new List<Opportunity>();
        
        for (Opportunity opp : newOpportunities) {
            if (opp.Type == 'Contractor Changes') {
                contractorChangeOpps.add(opp);
            }
        }
        
        if (!contractorChangeOpps.isEmpty()) {
            contractorService.createContractorChanges(contractorChangeOpps);
        }
    }
}