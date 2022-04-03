/**
 * Created by SWE. Fernando Caldera on 5/12/2021.
 */
@IsTest
public with sharing class Apttus_APTS_Agreement_c_TriggerTest {

    @TestSetup
    private static void setupData(){
        User user = TestDataFactory.getUser(true);
        System.runAs(user){
            TestDataFactory.getApttusAPTSAgreement(true);
        }
    }

    @IsTest
    public static void CPQAgreement(){
        Apttus__APTS_Agreement__c aptsAgreement = [
                SELECT Id
                FROM Apttus__APTS_Agreement__c
                LIMIT  1
        ];
        User user = [SELECT Id, Username FROM User WHERE Alias = 'Test' LIMIT 1];
        Test.startTest();
        System.runAs(user){
            updateApttusAPTSAgreement(aptsAgreement);
        }
        Test.stopTest();
        List<Opportunity_PM_Request__c> opportunityPMRequests = [SELECT Id, Region__c FROM Opportunity_PM_Request__c WHERE Agreement_Lookup__c = :aptsAgreement.Id ];
        List<Apttus__APTS_Agreement__c> aptsAgreements = [SELECT Id, Apttus__Account__r.Id, Apttus__Account__r.Customer_Region__c FROM Apttus__APTS_Agreement__c WHERE Id = :aptsAgreement.Id];
        System.assert(opportunityPMRequests.size() == 1);
        System.assert(aptsAgreements.size() == 1);
        System.assert(getMappedRegion(opportunityPMRequests.get(0).Region__c).equals(aptsAgreements.get(0).Apttus__Account__r.Customer_Region__c));
    }

    private static String getMappedRegion(String region){
        Map<String, String> mappedRegionsMap = new Map<String, String>();
        mappedRegionsMap.put('EMEA', 'EMEA');
        mappedRegionsMap.put('APAC', 'APAC');
        mappedRegionsMap.put('Americas', 'AMERS');
        return mappedRegionsMap.get(region);
    }

    private static void updateApttusAPTSAgreement(Apttus__APTS_Agreement__c aptsAgreement){
        aptsAgreement.Apttus__Status_Category__c = 'In Effect';
        update aptsAgreement;
    }

}