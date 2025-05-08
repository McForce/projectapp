public with sharing class ProjectContractorBillingController {
    
    @AuraEnabled(cacheable=true)
    public static List<ContractorBillingWrapper> getContractorBillings(Id projectId) {
        // Validate input
        if (projectId == null) {
            throw new AuraHandledException('Project ID cannot be null');
        }
        
        try {
            // Validate security
            validateSecurity();
            
            // Get all contractors for the project with their contact information
            Map<Id, Contractor__c> contractorsMap = new Map<Id, Contractor__c>([
                SELECT Id, Name, Budget_Percentage__c, Cost__c, 
                       Contact__c, Contact__r.Name
                FROM Contractor__c 
                WHERE Project__c = :projectId
            ]);
            
            if (contractorsMap.isEmpty()) {
                return new List<ContractorBillingWrapper>();
            }
            
            // Get the latest billing record for each contractor
            Map<Id, Contractor_Billing__c> latestBillingMap = getLatestBillingRecords(contractorsMap.keySet());
            
            // Create wrapper objects only for contractors with billing records
            List<ContractorBillingWrapper> wrappers = new List<ContractorBillingWrapper>();
            
            for (Contractor__c contractor : contractorsMap.values()) {
                if (latestBillingMap.containsKey(contractor.Id)) {
                    wrappers.add(new ContractorBillingWrapper(
                        contractor,
                        latestBillingMap.get(contractor.Id)
                    ));
                }
            }
            
            // Sort the wrappers by last billed date
            wrappers.sort();
            
            return wrappers;
            
        } catch (SecurityException e) {
            throw new AuraHandledException('Security violation: ' + e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving contractor billing data: ' + e.getMessage());
        }
    }
    
    private static Map<Id, Contractor_Billing__c> getLatestBillingRecords(Set<Id> contractorIds) {
        Map<Id, Contractor_Billing__c> latestBillingMap = new Map<Id, Contractor_Billing__c>();
        
        for (Contractor_Billing__c billing : [
            SELECT Id, Contractor__c, Last_Billed_Up_To__c
            FROM Contractor_Billing__c
            WHERE Contractor__c IN :contractorIds
            ORDER BY Last_Billed_Up_To__c DESC
        ]) {
            // Only keep the first (latest) billing record for each contractor
            if (!latestBillingMap.containsKey(billing.Contractor__c)) {
                latestBillingMap.put(billing.Contractor__c, billing);
            }
        }
        
        return latestBillingMap;
    }
    
    private static void validateSecurity() {
        // Check object-level security
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        
        Schema.SObjectType projectObject = globalDescribe.get('Project__c');
        Schema.SObjectType contractorObject = globalDescribe.get('Contractor__c');
        Schema.SObjectType billingObject = globalDescribe.get('Contractor_Billing__c');
        
        if (!projectObject.getDescribe().isAccessible() ||
            !contractorObject.getDescribe().isAccessible() ||
            !billingObject.getDescribe().isAccessible()) {
            throw new SecurityException('Insufficient object permissions');
        }
        
        // Check field-level security
        Map<String, Schema.SObjectField> contractorFields = contractorObject.getDescribe().fields.getMap();
        Map<String, Schema.SObjectField> billingFields = billingObject.getDescribe().fields.getMap();
        
        // Validate contractor fields
        String[] contractorFieldNames = new String[]{'Name', 'Budget_Percentage__c', 'Cost__c', 'Contact__c', 'Project__c'};
        for (String fieldName : contractorFieldNames) {
            if (!contractorFields.get(fieldName).getDescribe().isAccessible()) {
                throw new SecurityException('Insufficient permissions for Contractor__c.' + fieldName);
            }
        }
        
        // Validate billing fields
        if (!billingFields.get('Last_Billed_Up_To__c').getDescribe().isAccessible() ||
            !billingFields.get('Contractor__c').getDescribe().isAccessible()) {
            throw new SecurityException('Insufficient permissions for Contractor_Billing__c fields');
        }
    }
    
    public class SecurityException extends Exception {}
}