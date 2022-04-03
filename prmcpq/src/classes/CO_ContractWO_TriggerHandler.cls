/**
 * Created by SWE. Fernando Caldera on 5/27/2021.
 */

/**
 * @description This class is the handler for the ContractWO Trigger.
 */
public with sharing class CO_ContractWO_TriggerHandler {

    protected Boolean isBefore;
    protected Boolean isAfter;
    protected Boolean isInsert;
    protected Boolean isUpdate;
    protected Boolean isDelete;
    protected Boolean isExecute;
    protected List<ContractWO__c> newList;
    protected List<ContractWO__c> oldList;
    protected Map<Id, ContractWO__c> newMap;
    protected Map<Id, ContractWO__c> oldMap;

    public CO_ContractWO_TriggerHandler(
            Boolean isBefore, Boolean isAfter,
            Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isExecute,
            List<ContractWO__c> newList,
            List<ContractWO__c> oldList,
            Map<Id, ContractWO__c> newMap,
            Map<Id, ContractWO__c> oldMap
    ) {
        this.isBefore = isBefore;
        this.isAfter = isAfter;
        this.isInsert = isInsert;
        this.isUpdate = isUpdate;
        this.isDelete = isDelete;
        this.isExecute = isExecute;
        this.newList = newList;
        this.oldList = oldList;
        this.newMap = newMap;
        this.oldMap = oldMap;
    }

    /**
     * @description Executes the handler's flow.
     */
    public void execute() {
        if (isAfter && isUpdate) {
            createPMRequest(newMap, oldMap);
        }
    }

    /**
     * @description This method fills the PM Request object sent as parameter.
     * @param opportunityPMRequest The PM Request.
     * @param contractWO The contract linked to the PM Request.
     * @param contractWOSInDBMap The Map of contractWOs in database.
     */
    private void fillValues(Opportunity_PM_Request__c opportunityPMRequest, ContractWO__c contractWO, Map<Id, ContractWO__c> contractWOSInDBMap) {
        if (opportunityPMRequest != null && contractWO != null && contractWOSInDBMap != null) {
            opportunityPMRequest.New_Monthly_Revenue_APAC__c = 0;
            opportunityPMRequest.New_Monthly_Revenue_Canada__c = 0;
            opportunityPMRequest.New_Monthly_Revenue_EMEA__c = 0;
            opportunityPMRequest.New_Monthly_Revenue_NA__c = 0;

            opportunityPMRequest.Host_Count_by_Region_APAC__c = 0;
            opportunityPMRequest.Host_Count_by_Region_Canada__c = 0;
            opportunityPMRequest.Host_Count_by_Region_EMEA__c = 0;
            opportunityPMRequest.Host_Count_by_Region_NA__c = 0;

            opportunityPMRequest.Estimated_Minutes_per_Month_APAC__c = 0;
            opportunityPMRequest.Estimated_Minutes_per_Month_Canada__c = 0;
            opportunityPMRequest.Estimated_Minutes_per_Month_EMEA__c = 0;
            opportunityPMRequest.Estimated_Minutes_per_Month_NA__c = 0;
            opportunityPMRequest.Total_Contract_Amount__c = 0;
            opportunityPMRequest.Total_Contract_Length__c = 0;

            opportunityPMRequest.Region__c = getMappedRegion(contractWOSInDBMap.get(contractWO.Id).Company_Number__r.Customer_Region__c);
            opportunityPMRequest.Lead_Sales_Rep_Email__c = opportunityPMRequest.Opportunity__r.Owner.Email;
            opportunityPMRequest.Sales_Rep_Name__c = opportunityPMRequest.Opportunity__r.Owner.Id;

            opportunityPMRequest.APAC__c = '0';
            opportunityPMRequest.EMEA__c = '0';
            opportunityPMRequest.Americas__c = '0';
            opportunityPMRequest.Canada__c = '0';

            if ('APAC'.equals(opportunityPMRequest.Region__c)) {
                opportunityPMRequest.APAC__c = contractWOSInDBMap.get(contractWO.Id).Company_Number__r.AccountNumber;
            } else if ('EMEA'.equals(opportunityPMRequest.Region__c)) {
                opportunityPMRequest.EMEA__c = contractWOSInDBMap.get(contractWO.Id).Company_Number__r.AccountNumber;
            } else if ('Americas'.equals(opportunityPMRequest.Region__c)) {
                opportunityPMRequest.Americas__c = contractWOSInDBMap.get(contractWO.Id).Company_Number__r.AccountNumber;
            } else if ('CANADA'.equals(opportunityPMRequest.Region__c)) {
                opportunityPMRequest.Canada__c = contractWOSInDBMap.get(contractWO.Id).Company_Number__r.AccountNumber;
            }

            opportunityPMRequest.Agreement_Lookup__c = contractWOSInDBMap.get(contractWO.Id).Agreement__c;
            opportunityPMRequest.Agreement_Lookup__r = contractWOSInDBMap.get(contractWO.Id).Agreement__r;
            opportunityPMRequest.Company_Name__c = contractWOSInDBMap.get(contractWO.Id).Company_Number__c;
            opportunityPMRequest.Company_Name__r = contractWOSInDBMap.get(contractWO.Id).Company_Number__r;
            if(contractWOSInDBMap.get(contractWO.Id).Company_Number__r != null){
                Boolean wholesale = contractWOSInDBMap.get(contractWO.Id).Company_Number__r.wholesale__c;
                if(wholesale){
                    opportunityPMRequest.Channel__c = 'Yes';
                }else{
                    opportunityPMRequest.Channel__c = 'No';
                }
            }
        }
    }

    /**
     * @param region The region in the account object's format.
     *
     * @return The region value mapped to match the PM Request's format.
     */
    private String getMappedRegion(String region) {
        String mappedRegion = '';
        if (region != null) {
            Map<String, String> regionMap = new Map<String, String>();
            regionMap.put('APAC', 'APAC');
            regionMap.put('EMEA', 'EMEA');
            regionMap.put('AMERS', 'Americas');
            mappedRegion = regionMap.get(region);
        }
        return mappedRegion;
    }

    /**
     * @description This method returns whether the contract has any PM Request linked directly to it
     * or not.
     * @param contractWO The contract.
     * @param opportunityPMRequests A List of the PM Requests that are in the database.
     *
     * @return Whether there's a PM Request linked to the contract or not.
     */
    private Boolean existsPMRForContract(ContractWO__c contractWO, List<Opportunity_PM_Request__c> opportunityPMRequests) {
        Boolean exists = false;
        for (Opportunity_PM_Request__c opportunityPMRequest : opportunityPMRequests) {
            if (opportunityPMRequest.Contract_Order__c == contractWO.Id) {
                exists = true;
                break;
            }
        }
        return exists;
    }

    /**
     * @description This method returns whether the specified
     * contract is in document execution stage or not.
     * @param contractWO The contract.
     *
     * @return Whether the contract is in document execution stage or not.
     */
    private Boolean isPMRCreationReady(ContractWO__c contractWO) {
        Boolean isPMRCreationReady = false;
        if (
//                (
//                        ((contractWO.Contract_Type__c == 'Web' && contractWO.Product__c != 'UM PRO')
//                                || contractWO.BJN_or_Vidyo__c || contractWO.Contract_Type__c == 'Audio')
//                                && contractWO.Last_Approval_Step__c == 4
//                )
//                        ||
//                        ((contractWO.Contract_Type__c == 'Ancillary/Event Services'
//                                || contractWO.Contract_Type__c == 'Non-Disclosure Agreement')
//                                && contractWO.Last_Approval_Step__c == 4
//                        )
//                        ||
//                        ((contractWO.Second_Commercial_Validation__c ||
//                                contractWO.Product__c == 'Webex Teams (Spark)/Equipment')
//                                && contractWO.Last_Approval_Step__c == 5
//                        )
                contractWO.Last_Approval_Step__c == 6 || contractWO.Last_Approval_Step__c == 7
                ) {
            isPMRCreationReady = true;
        }
        return isPMRCreationReady;
    }

    /**
     * @description Checks if the status of the specified contract
     * changed in the update.
     * @param contractWO The contract to check if its status changed or not.
     * @param oldMap The oldMap (from trigger).
     *
     * @return Whether the contract status changed during the update.
     */
    private Boolean statusChanged(ContractWO__c contractWO, Map<Id, ContractWO__c> oldMap) {
        Boolean statusChanged = false;
        if (contractWO != null && oldMap != null) {
            ContractWO__c oldContractWO = oldMap.get(contractWO.Id);
            if (oldContractWO != null) {
                if (contractWO.Last_Approval_Step__c != oldContractWO.Last_Approval_Step__c) {
                    statusChanged = true;
                }
            }
        }
        return statusChanged;
    }

    /**
     * @description This method creates a new PM Request for every
     * ContractWO that matches certain criteria.
     * @param newMap The newMap (from trigger)
     * @param oldMap The oldMap (from trigger)
     */
    private void createPMRequest(Map<Id, ContractWO__c> newMap,
            Map<Id, ContractWO__c> oldMap) {
        if (newMap != null) {
            List<Opportunity_PM_Request__c> pmrs = new List<Opportunity_PM_Request__c>();

            //We get all the PM Requests in the database that are related to any of
            //the contracts in newMap.
            List<Opportunity_PM_Request__c> pmrsInDB = [SELECT Id, Contract_Order__c FROM Opportunity_PM_Request__c WHERE Contract_Order__c IN :newMap.keySet()];

            Set<Id> opportunityIds = new Set<Id>();

            Map<Id, ContractWO__c> contractWOSInDBMap = new Map<Id, ContractWO__c>([
                    SELECT Id, Name, Agreement__c,
                            Agreement__r.Name,
                            Company_Number__r.wholesale__c,
                            Company_Number__c,
                            Company_Number__r.Region__c,
                            Company_Number__r.Name,
                            Company_Number__r.AccountNumber,
                            Company_Number__r.Customer_Region__c
                    FROM ContractWO__c
                    WHERE Id IN :newMap.keySet()
            ]);

            //We get all the opportunities ids.
            for (ContractWO__c contract : newMap.values()) {
                if (contract.Opportunity__c != null) {
                    opportunityIds.add(contract.Opportunity__c);
                }
            }

            //We get all the opportunities as well as their line items
            //froms database.
            Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>([
                    SELECT Id, Owner.Name, Owner.Email, Owner.User_Region__c, (
                            SELECT Id, Name, IsDeleted, Timeframe__c,
                                    Estimated_Contract_Duration__c, Product_Family__c, Product_Name__c, TotalPrice,
                                    West_Org__c, Opportunity.AccountId, Opportunity.Regions__c,
                                    Opportunity.Account.Region__c
                            FROM OpportunityLineItems
                    )
                    FROM Opportunity
                    WHERE Id IN :opportunityIds
            ]);

            //For each contract, we verify if the status changed, if it's on document execution stage
            //and if it doesn't have a PM Request linked to it.
            for (ContractWO__c contract : newMap.values()) {
                if (isPMRCreationReady(contract) && !existsPMRForContract(contract, pmrsInDB) && statusChanged(contract, oldMap)) {

                    Opportunity_PM_Request__c OPR = new Opportunity_PM_Request__c();
                    Boolean hasIPProducts = false;
                    Boolean hasUCPRoducts = false;
                    Id OppId = contract.Opportunity__c;
                    List<OpportunityLineItem> opportunityLineItems = opportunityMap.get(OppId).OpportunityLineItems;

                    OPR.Opportunity__c = contract.Opportunity__c;
                    OPR.Opportunity__r = opportunityMap.get(contract.Opportunity__c);

                    //OPR.Line_of_Business__c = 'UC-Only';
                    OPR.RecordTypeId = Schema.SObjectType.Opportunity_PM_Request__c.getRecordTypeInfosByDeveloperName().get('UC_Implementation_PM_Request').getRecordTypeId();
                    if (contract.Region__c != null && contract.Region__c == 'APAC') {
                        OPR.Region__c = 'APAC';
                    } else if (contract.Region__c != null && contract.Region__c == 'EU') {
                        OPR.Region__c = 'EMEA';
                    } else if (contract.Region__c != null && contract.Region__c == 'NA') {
                        OPR.Region__c = 'Americas';
                    }
                    OPR.Contract_Order__c = contract.Id;
                    if (contract.Contract_Type__c != null && contract.Contract_Type__c == 'Audio') {
                        OPR.Type_of_Implementation__c = 'Audio Only';
                    } else if (contract.Contract_Type__c != null && contract.Contract_Type__c == 'Web') {
                        OPR.Type_of_Implementation__c = 'Web Only';
                    } else if (contract.Contract_Type__c != null && contract.Contract_Type__c == 'Ancillary/Event Services') {
                        OPR.Type_of_Implementation__c = 'Audio / Web';
                    } else if (contract.Contract_Type__c != null && contract.Contract_Type__c == 'Video') {
                        OPR.Type_of_Implementation__c = 'Video';
                    } else if (contract.Contract_Type__c != null && contract.Contract_Type__c == 'UCaaS') {
                        OPR.Type_of_Implementation__c = 'Video';
                    }

                    /*if(contract.Company_Owner_Channel__c == 'Wholesale' ){
                    OPR.Channel__c = 'Yes';
                    }else{
                    OPR.Channel__c ='No';
                    }*/
                    OPR.Revenue_Type__c = 'New';

                    /* if(OPR.Region__c == 'Americas'){
                    OPR.EMEA__c = '0';
                    OPR.APAC__c = '0';
                    OPR.Canada__c ='0';
                    }
                    else if(OPR.Region__c=='EMEA'){
                    OPR.APAC__c = '0';
                    OPR.Canada__c ='0';
                    OPR.Americas__c ='0';
                    }
                    else if(OPR.Region__c == 'Canada'){
                    OPR.EMEA__c = '0';
                    OPR.APAC__c ='0';
                    OPR.Americas__c ='0';
                    }
                    else if(OPR.Region__c == 'APAC'){
                    OPR.EMEA__c = '0';
                    OPR.Canada__c ='0';
                    OPR.Americas__c ='0';
                    }*/
                    OPR.Sales_Rep_Name__c = contract.Company_Sales_Rep__c;
                    OPR.Lead_Sales_Rep_Email__c = UserInfo.getUserEmail();
                    OPR.Total_Contract_Value__c = contract.Contract_Amount__c;
                    //OPR.Lead_Sales_Rep_Phone__c = contract.Owner__r.Phone;
                    OPR.Total_Contract_Length__c = contract.Estimated_Contract_Duration__c;
                    OPR.Channel__c = contract.DS_Purchased__c;
                    // OPR.Project_Overview__c = contract.Private_Comments__c;
                    //OPR.Professional_Services_Fee_Discussed__c= contract.Ace_Sales_Rep_Name__c;
                    OPR.Total_Contract_Amount__c = contract.Contract_Amount__c;
                    OPR.Comments__c = contract.Comments_Description__c;
                    OPR.Target_Rollout_Date__c = contract.Contract_Required_Date__c;
                    //OPR.Explain_the_target_date__c=contract.Payment_Terms_Description__c;
                    //OPR.Billing_Invoicing__c= contract.Payment_Terms_Description__c;
                    //OPR.Anticipated_Customer_Pin__c=contract.Contract_Task__c;
                    //OPR.Known_special_requirements__c=contract.Wholesale_Partners_Name__c;
                    for (OpportunityLineItem prod : opportunityLineItems) {
                        if (prod.West_Org__c == 'IP') {
                            hasIPProducts = true;
                        } else if (prod.West_Org__c == 'UC') {
                            hasUCPRoducts = true;
                        }

                    }
                    if (hasIPProducts && hasUCPRoducts) {
                        OPR.Line_of_Business__c = 'UCaaS/UC';
                    } else if (!hasIPProducts && hasUCPRoducts) {
                        OPR.Line_of_Business__c = 'UC-Only';
                    } else if (hasIPProducts && !hasUCPRoducts) {
                        OPR.Line_of_Business__c = 'UCaaS-Only';
                    }

                    fillValues(OPR, contract, contractWOSInDBMap);

                    pmrs.add(OPR);
                }
            }
            if (pmrs.size() > 0) {
                insert pmrs;
            }
        }
    }
}