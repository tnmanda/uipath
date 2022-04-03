@IsTest
private class LeadTriggerTest {

    private static User createOrGetUser() {
        User user;

        List<User> users = [SELECT Id, Name, FirstName, LastName FROM User WHERE Name = :LeadTriggerHandler.PRM_INTEGRATION_USER_NAME];
        if (users != null && users.size() > 0 && users[0] != null) {
            user = users[0];
        }
        if (user == null) {
            user.FirstName = 'PRM';
            user.LastName = 'Integration';
            user.Alias = 'testprm';
            user.Username = 'testprm1234qa@west.com';
            user.Email = 'test@west.com';
            user.ProfileId = [SELECT Id FROM Profile LIMIT 1][0].Id;
            user.LocaleSidKey = 'en_US';
            user.LanguageLocaleKey = 'en_US';
            user.TimeZoneSidKey = 'America/Chicago';
            user.EmailEncodingKey = 'UTF-8';

            List<UserRole> userRoles = [SELECT Id FROM UserRole WHERE Name = 'System Administrator'];
            if (userRoles != null && userRoles.size() > 0 && userRoles[0] != null) {
                user.UserRoleId = userRoles[0].Id;
            }
            insert user;
        }

        return user;
    }

    @IsTest
    static void testCustomerCountryCustomerState() {
        Test.startTest();
        User user = createOrGetUser();
        System.runAs(user) {
            List<Lead> leads = new List<Lead>();
            Lead lead = new Lead();

            lead.CreatedById = user.Id;
            lead.Company = 'test company';
            lead.FirstName = 'test';
            lead.LastName = '1234 1234';
            lead.Lead_Type__c = 'UC';
            lead.Lead_Origin__c = 'Sales Sourced';
            lead.Status = 'Open';
            lead.Email = 'noemailcanada@intercall.com';
            lead.CurrencyIsoCode = 'USD';
            lead.HQRegion__c = 'NA';
            lead.LeadSource = 'Tech Partners';
            lead.Lead_Source_Detail__c = 'Tech Partners Leads';
            lead.Customer_Type__c = 'Customer';
            //lead.Customer_Country__c = LeadTriggerHelper.USA;
            //lead.Customer_State__c = 'Ohio';
            lead.Country = LeadTriggerHandler.USA;
            lead.State = 'Ohio';

            leads.add(lead);
            insert leads;

            Test.stopTest();

            leads = [SELECT Country, State, Customer_Country__c, Customer_State__c, Customer_Region__c, Customer_Legal_Entity__c FROM Lead WHERE Id = :lead.Id];
            if (leads != null && leads.size() > 0 && leads[0] != null) {
                System.assert(leads.size() == 1);
                System.assertEquals(leads[0].Country, leads[0].Customer_Country__c);
                System.assertEquals(leads[0].State, leads[0].Customer_State__c);
                System.assertEquals('AMERS', leads[0].Customer_Region__c);
                System.assertEquals('Intrado Enterprise Collaboration, Inc.', leads[0].Customer_Legal_Entity__c);
            }
        }
    }

    @IsTest
    static void testCustomerCountryNoCustomerState() {
        Test.startTest();
        User user = createOrGetUser();
        System.runAs(user) {
            List<Lead> leads = new List<Lead>();
            Lead lead = new Lead();

            lead.CreatedById = user.Id;
            lead.Company = 'test company';
            lead.FirstName = 'test';
            lead.LastName = '1234 1234';
            lead.Lead_Type__c = 'UC';
            lead.Lead_Origin__c = 'Sales Sourced';
            lead.Status = 'Open';
            lead.Email = 'noemailcanada@intercall.com';
            lead.CurrencyIsoCode = 'USD';
            lead.HQRegion__c = 'NA';
            lead.LeadSource = 'Tech Partners';
            lead.Lead_Source_Detail__c = 'Tech Partners Leads';
            lead.Customer_Type__c = 'Customer';
            lead.Country = 'Mexico';
            lead.State = 'Durango';

            leads.add(lead);
            insert leads;

            Test.stopTest();

            leads = [SELECT Country, State, Customer_Country__c, Customer_State__c, Customer_Region__c, Customer_Legal_Entity__c FROM Lead WHERE Id = :lead.Id];
            if (leads != null && leads.size() > 0 && leads[0] != null) {
                System.assert(leads.size() == 1);
                System.assertEquals('Mexico', leads[0].Customer_Country__c);
                System.assertEquals(null, leads[0].Customer_State__c);
                System.assertEquals('AMERS', leads[0].Customer_Region__c);
                System.assertEquals('Intrado Mexico, S. de R.L. de C.V.', leads[0].Customer_Legal_Entity__c);
            }
        }
    }
}