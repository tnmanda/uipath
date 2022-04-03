/**
 * Created by SWE. Fernando Caldera on 5/12/2021.
 */

/**
 * @author SWE. Fernando Caldera
 * @description This class tests the PM Requests automation functionality
 * for COM Contracts.
 */
@IsTest
public with sharing class CO_ContractWO_TriggerTest {

    @TestSetup
    private static void setupData() {
        User user = TestDataFactory.getUser(true);
        System.runAs(user) {
            TestDataFactory.getContractWO(true);
        }
    }

    @IsTest
    public static void COMContract() {
        ContractWO__c contractWO = [
                SELECT Id, Last_Approval_Step__c,
                        Product_By_Contract_Type__c,
                        Contract_Type__c, Order_Header__c, Order_Header__r.Owner__r.IsActive,
                        Approval_Reject__c
                FROM ContractWO__c
                LIMIT 1
        ];
        User user = [SELECT Id, Username, IsActive FROM User WHERE Alias = 'Test' LIMIT 1];
        Test.startTest();
        System.runAs(user) {
            updateToDocumentExecutionStage(contractWO);
        }
        Test.stopTest();

        List<Opportunity_PM_Request__c> opportunityPMRequests = [SELECT Id, Region__c FROM Opportunity_PM_Request__c WHERE Contract_Order__c = :contractWO.Id];
        List<ContractWO__c> contractWOS = [SELECT Id, Company_Number__r.Customer_Region__c FROM ContractWO__c WHERE Id = :contractWO.Id];
        System.assert(opportunityPMRequests.size() == 1);
        System.assert(contractWOS.size() == 1);
        System.assert(getMappedRegion(opportunityPMRequests.get(0).Region__c).equals(contractWOS.get(0).Company_Number__r.Customer_Region__c));
    }

    private static String getMappedRegion(String region){
        Map<String, String> mappedRegionsMap = new Map<String, String>();
        mappedRegionsMap.put('APAC', 'APAC');
        mappedRegionsMap.put('EMEA', 'EMEA');
        mappedRegionsMap.put('Americas', 'AMERS');
        return mappedRegionsMap.get(region);
    }

    private static void updateToDocumentExecutionStage(ContractWO__c contractWO) {
        contractWO.Last_Approval_Step__c = 4;
        update contractWO;
    }
}