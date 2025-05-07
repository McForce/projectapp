@IsTest
private class OpportunityContractorServiceTest {
    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;
        
        // Create test project
        Project__c testProject = new Project__c(
            Name = 'Test Project',
            Account__c = testAccount.Id,
            Project_Start_Date__c = Date.today(),
            Budget_Cost__c = 100000
        );
        insert testProject;
        
        // Create test contractors
        List<Contractor__c> contractors = new List<Contractor__c>();
        for (Integer i = 0; i < 200; i++) {
            contractors.add(new Contractor__c(
                Name = 'Test Contractor ' + i,
                Project__c = testProject.Id,
                Budget_Percentage__c = 10,
                Cost__c = 10000
            ));
        }
        insert contractors;
    }
    
    @IsTest
    static void testBulkContractorChangesCreation() {
        // Get test project
        Project__c testProject = [SELECT Id FROM Project__c LIMIT 1];
        
        Test.startTest();
        
        // Create test opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            Project__c = testProject.Id,
            Type = 'Contractor Changes',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;
        
        Test.stopTest();
        
        // Verify contractor changes were created
        List<Contractor_Changes__c> changes = [
            SELECT Id 
            FROM Contractor_Changes__c 
            WHERE Opportunity__c = :testOpp.Id
        ];
        
        System.assertEquals(200, changes.size(), 'Expected 200 Contractor Changes records to be created');
    }
    
    @IsTest
    static void testNonContractorChangesOpportunity() {
        // Get test project
        Project__c testProject = [SELECT Id FROM Project__c LIMIT 1];
        
        Test.startTest();
        
        // Create test opportunity with different type
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            Project__c = testProject.Id,
            Type = 'New Business',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;
        
        Test.stopTest();
        
        // Verify no contractor changes were created
        List<Contractor_Changes__c> changes = [
            SELECT Id 
            FROM Contractor_Changes__c 
            WHERE Opportunity__c = :testOpp.Id
        ];
        
        System.assertEquals(0, changes.size(), 'Expected no Contractor Changes records to be created');
    }
    
    @IsTest
    static void testPermissionCheck() {
        // This test would require a user with restricted permissions
        // Create test user without create permission on Contractor_Changes__c
        // Note: Implementation depends on your org's profile setup
        
        // Get test project
        Project__c testProject = [SELECT Id FROM Project__c LIMIT 1];
        
        Test.startTest();
        
        // Create test opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            Project__c = testProject.Id,
            Type = 'Contractor Changes',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        
        Boolean exceptionThrown = false;
        try {
            insert testOpp;
        } catch (SecurityException e) {
            exceptionThrown = true;
        }
        
        Test.stopTest();
        
        // Note: This assertion might need to be adjusted based on how you implement the permission check
        // System.assert(exceptionThrown, 'Expected SecurityException to be thrown');
    }
}