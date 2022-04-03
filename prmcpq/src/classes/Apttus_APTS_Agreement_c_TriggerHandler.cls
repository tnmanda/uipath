/**
 * Created by SWE. Fernando Caldera on 5/27/2021.
 */

/**
 * @description This class is the handler for the Apttus_APTS_Agreement trigger.
 */
public with sharing class Apttus_APTS_Agreement_c_TriggerHandler {

    protected Boolean isBefore;
    protected Boolean isAfter;
    protected Boolean isInsert;
    protected Boolean isUpdate;
    protected Boolean isDelete;
    protected Boolean isUndelete;
    protected Boolean isExecute;
    protected List<Apttus__APTS_Agreement__c> newList;
    protected List<Apttus__APTS_Agreement__c> oldList;
    protected Map<Id, Apttus__APTS_Agreement__c> newMap;
    protected Map<Id, Apttus__APTS_Agreement__c> oldMap;

    public Apttus_APTS_Agreement_c_TriggerHandler(Boolean isBefore, Boolean isAfter,
            Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete, Boolean isExecute,
            List<Apttus__APTS_Agreement__c> newList,
            List<Apttus__APTS_Agreement__c> oldList,
            Map<Id, Apttus__APTS_Agreement__c> newMap,
            Map<Id, Apttus__APTS_Agreement__c> oldMap) {
        this.isBefore = isBefore;
        this.isAfter = isAfter;
        this.isInsert = isInsert;
        this.isUpdate = isUpdate;
        this.isDelete = isDelete;
        this.isUndelete = isUndelete;
        this.isExecute = isExecute;
        this.newList = newList;
        this.oldList = oldList;
        this.newMap = newMap;
        this.oldMap = oldMap;
    }

    /**
     * @description Starts the handler execution flow.
     */
    public void execute() {
        if (isAfter && isUpdate) {
            createPMRequest(newMap, oldMap);
        }
    }

    /**
     * @param agreement The agreement queried.
     * @param opportunityPMRequests The list of PM Requests that are in the database.
     *
     * @return Whether the Agreement has a PM Request asociated or not.
     */
    private Boolean existsPMRForAgreement(Apttus__APTS_Agreement__c agreement, List<Opportunity_PM_Request__c> opportunityPMRequests) {
        Boolean exists = false;
        for (Opportunity_PM_Request__c opportunityPMRequest : opportunityPMRequests) {
            if (agreement.Id == opportunityPMRequest.Agreement_Lookup__c) {
                exists = true;
                break;
            }
        }
        return exists;
    }

    /**
     * @description Fills the values for the PM Request.
     * @param opportunityPMRequest The PM Request to be filled.
     * @param agreement Current agreement.
     * @param agreementsInDBMap The agreements in the DB.
     */
    private void fillValues(Opportunity_PM_Request__c opportunityPMRequest,
            Apttus__APTS_Agreement__c agreement,
            Map<Id, Apttus__APTS_Agreement__c> agreementsInDBMap) {
        if (opportunityPMRequest != null && agreement != null && agreementsInDBMap != null) {
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

            opportunityPMRequest.Region__c = getMappedRegion(getAccount(agreementsInDBMap.get(agreement.Id)).Customer_Region__c);
            opportunityPMRequest.Lead_Sales_Rep_Email__c = opportunityPMRequest.Opportunity__r.Owner.Email;
            opportunityPMRequest.Sales_Rep_Name__c = opportunityPMRequest.Opportunity__r.Owner.Id;

            opportunityPMRequest.APAC__c = '0';
            opportunityPMRequest.EMEA__c = '0';
            opportunityPMRequest.Americas__c = '0';
            opportunityPMRequest.Canada__c = '0';

            if ('APAC'.equals(opportunityPMRequest.Region__c)) {
                opportunityPMRequest.APAC__c = getAccount(agreementsInDBMap.get(agreement.Id)).AccountNumber;
            } else if ('EMEA'.equals(opportunityPMRequest.Region__c)) {
                opportunityPMRequest.EMEA__c = getAccount(agreementsInDBMap.get(agreement.Id)).AccountNumber;
            } else if ('Americas'.equals(opportunityPMRequest.Region__c)) {
                opportunityPMRequest.Americas__c = getAccount(agreementsInDBMap.get(agreement.Id)).AccountNumber;
            } else if ('CANADA'.equals(opportunityPMRequest.Region__c)) {
                opportunityPMRequest.Canada__c = getAccount(agreementsInDBMap.get(agreement.Id)).AccountNumber;
            }

            if (getAccount(agreementsInDBMap.get(agreement.Id)) != null) {
                Boolean wholesale = getAccount(agreementsInDBMap.get(agreement.Id)).wholesale__c;
                if (wholesale) {
                    opportunityPMRequest.Channel__c = 'Yes';
                } else {
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
     * @param agreement The agreement.
     *
     * @return The account related to the agreement.
     */
    private Account getAccount(Apttus__APTS_Agreement__c agreement) {
        Account account = null;
        if (agreement != null) {
            /*if (agreement.Account__c != null && agreement.Account__r != null) {
                account = agreement.Account__r;
            } else*/
            if (agreement.Apttus__Account__c != null && agreement.Apttus__Account__r != null) {
                account = agreement.Apttus__Account__r;
            }
        }
        return account;
    }

    /**
     * @param agreement The agreement.
     * @param oldMap The oldMap (from trigger)
     *
     * @return Whether the status has changed or not.
     */
    private Boolean statusChanged(Apttus__APTS_Agreement__c agreement,
            Map<Id, Apttus__APTS_Agreement__c> oldMap) {
        Boolean statusChanged = false;
        if (agreement != null && oldMap != null) {
            Apttus__APTS_Agreement__c oldAgreement = oldMap.get(agreement.Id);
            if (oldAgreement != null) {
                if (!agreement.Apttus__Status_Category__c.equals(oldAgreement.Apttus__Status_Category__c)) {
                    statusChanged = true;
                }
            }
        }
        return statusChanged;
    }

    /**
     * @param agreement The agreement.
     *
     * @return Whether is in document execution stage or not.
     */
    private Boolean isInDocumentExecutionStage(Apttus__APTS_Agreement__c agreement) {
        Boolean isInDocumentExecutionStage = false;
        if (agreement != null) {
            if ('In Effect'.equals(agreement.Apttus__Status_Category__c)) {
                isInDocumentExecutionStage = true;
            }
        }
        return isInDocumentExecutionStage;
    }

    /**
     * @description This method creates a PM Request for every agreement that
     * comply with certain conditions.
     * @param newMap The new map of the agreements.
     * @param oldMap The old map of the agreements.
     */
    private void createPMRequest(Map<Id, Apttus__APTS_Agreement__c> newMap,
            Map<Id, Apttus__APTS_Agreement__c> oldMap) {
        //Check that the input is valid.
        if (newMap != null && oldMap != null) {

            List<Opportunity_PM_Request__c> pmrs = new List<Opportunity_PM_Request__c>();

            //We get the PM requests that are in the database that are linked to any of the input agreements.
            List<Opportunity_PM_Request__c> pmrsInDB = [SELECT Id, Agreement_Lookup__c FROM Opportunity_PM_Request__c WHERE Agreement_Lookup__c IN :newMap.keySet()];
            Set<Id> opportunityIds = new Set<Id>();

            //We get the different opportunities Ids.
            for (Apttus__APTS_Agreement__c agreement : newMap.values()) {
                if (agreement.Apttus__Related_Opportunity__c != null) {
                    opportunityIds.add(agreement.Apttus__Related_Opportunity__c);
                }
            }

            //Get the data from the opportunities as well as their line items.
            Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>(
            [
                    SELECT Id, Owner.Name, Owner.Email, Owner.User_Region__c, (
                            SELECT Id, Name, IsDeleted, Timeframe__c,
                                    Estimated_Contract_Duration__c, Product_Family__c, Product_Name__c, TotalPrice,
                                    West_Org__c, Opportunity.AccountId, Opportunity.Regions__c,
                                    Opportunity.Account.Region__c
                            FROM OpportunityLineItems
                    )
                    FROM Opportunity
                    WHERE Id IN :opportunityIds
            ]
            );

            Map<Id, Apttus__APTS_Agreement__c> agreementsInDBMap =
                    new Map<Id, Apttus__APTS_Agreement__c>
                            (
                            [
                                    SELECT Id,
                                            Apttus__Account__r.wholesale__c,
                                            Apttus__Account__r.Region__c,
                                            Apttus__Account__r.AccountNumber,
                                            Apttus__Account__r.Customer_Region__c
                                    FROM Apttus__APTS_Agreement__c
                                    WHERE Id IN :newMap.keySet()
                            ]
                            );

            //For each agreement in the newMap, we verify that it is
            //in the document execution stage, that there is no PM Request linked to the
            //agreement and that its status changed.
            for (Apttus__APTS_Agreement__c agreement : newMap.values()) {
                if (isInDocumentExecutionStage(agreement) && !existsPMRForAgreement(agreement, pmrsInDB) && statusChanged(agreement, oldMap)) {

                    Boolean hasIPProducts = false;
                    Boolean hasUCPRoducts = false;
                    Id AgreementID = agreement.Id;
                    Opportunity_PM_Request__c OPR = new Opportunity_PM_Request__c();
                    Id OppId = agreement.Apttus__Related_Opportunity__c;
                    List<OpportunityLineItem> opportunityLineItems = opportunityMap.get(OppId).OpportunityLineItems;

                    OPR.Opportunity__c = OppId;
                    OPR.Opportunity__r = opportunityMap.get(OppId);


                    // OPR.Line_of_Business__c = 'UC-Only';
                    OPR.RecordTypeId = Schema.SObjectType.Opportunity_PM_Request__c.getRecordTypeInfosByDeveloperName().get('UC_Implementation_PM_Request').getRecordTypeId();

                    OPR.Region__c = agreement.APTS_Region__c;
                    OPR.Agreement_Lookup__c = AgreementID;
                    if (getAccount(agreementsInDBMap.get(agreement.Id)) != null) {
                        OPR.Company_Name__c = getAccount(agreementsInDBMap.get(agreement.Id)).Id;
                    }
                    OPR.Revenue_Type__c = 'New';


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

                    fillValues(OPR, agreement, agreementsInDBMap);

                    pmrs.add(OPR);

                }
            }
            if (pmrs.size() > 0) {
                insert pmrs;
            }
        }
    }
}