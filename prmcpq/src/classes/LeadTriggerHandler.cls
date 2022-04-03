public with sharing class LeadTriggerHandler {
    public static final String PRM_INTEGRATION_USER_NAME = 'PRM Integration';
    public static final String CANADA = 'Canada';
    public static final String USA = 'United States of America';

    protected Boolean isBefore;
    protected Boolean isAfter;
    protected Boolean isInsert;
    protected Boolean isUpdate;
    protected Boolean isDelete;
    protected Boolean isUndelete;
    protected Boolean isExecute;
    protected List<Lead> newList;
    protected List<Lead> oldList;
    protected Map<Id, Lead> newMap;
    protected Map<Id, Lead> oldMap;

    public LeadTriggerHandler(Boolean isBefore, Boolean isAfter,
            Boolean isInsert, Boolean isUpdate, Boolean isDelete,
            Boolean isUndelete, Boolean isExecute,
            List<Lead> newList,
            List<Lead> oldList,
            Map<Id, Lead> newMap,
            Map<Id, Lead> oldMap) {
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

    public void execute() {
        if (isBefore && isInsert) {
            PRMDealSync(newList);
        }
    }

    private Boolean stateExists(List<Schema.PicklistEntry> customerStatePLEL, String state) {

        for (Schema.PicklistEntry customerStatePLE : customerStatePLEL) {
            if (customerStatePLE.getValue().equals(state) && customerStatePLE.isActive()) {
                return true;
            }
        }
        return false;
    }

    private void PRMDealSync(List<Lead> leads) {
        List<User> users = [SELECT Id FROM User WHERE Name = :PRM_INTEGRATION_USER_NAME];
        Id prmIntegrationUserId;
        if (users != null && users.size() > 0 && users[0] != null) {
            prmIntegrationUserId = users[0].Id;
        }

        Schema.DescribeFieldResult customerStateDFR = Lead.Customer_State__c.getDescribe();
        List<Schema.PicklistEntry> customerStatePLEL = customerStateDFR.getPicklistValues();
        Map<Object, List<String>> customerRegionMap = getDependentPickListValues(
                Lead.getSObjectType().getDescribe().fields.getMap().get('Customer_Region__c')
        );
        Map<Object, List<String>> customerLegalEntityMap = getDependentPickListValues(
                Lead.getSObjectType().getDescribe().fields.getMap().get('Customer_Legal_Entity__c')
        );
        for (Lead lead : leads) {
            if (System.UserInfo.getUserId() == prmIntegrationUserId) {

                fillCustomerCountry(lead);
                fillCustomerState(lead, customerStatePLEL);
                fillCustomerRegion(lead, customerRegionMap);
                fillCustomerLegalEntity(lead, customerLegalEntityMap);

                // ref - https://jira.dev.iconf.net/browse/SCE-567
                if (lead.LeadSource == 'Tech Partners') {
                    setSourcedFromPRM(lead);
                }
            }
        }
    }

    private void fillCustomerRegion(Lead lead, Map<Object, List<String>> customerRegionMap) {
        if (lead != null && customerRegionMap != null) {
            lead.Customer_Region__c = customerRegionMap.get(lead.Customer_Country__c).get(0);
        }
    }

    private void fillCustomerCountry(Lead lead) {
        lead.Customer_Country__c = lead.Country;
    }

    private void fillCustomerState(Lead lead, List<Schema.PicklistEntry> customerStatePLEL) {
        if (lead.Country == CANADA || lead.Country == USA && stateExists(customerStatePLEL, lead.State)) {
            lead.Customer_State__c = lead.State;
        }
    }

    private void fillCustomerLegalEntity(Lead lead, Map<Object, List<String>> customerLegalEntityMap) {
        if (lead != null && customerLegalEntityMap != null) {
            lead.Customer_Legal_Entity__c = customerLegalEntityMap.get(lead.Customer_Country__c).get(0);
        }
    }

    // ref - https://jira.dev.iconf.net/browse/SCE-567
    // 5.13.2021
    // Set field Sourced_from_PRM__c in Lead object to TRUE if the Lead.LeadSource field is equal to 'Tech Partners'
    private void setSourcedFromPRM(Lead lead) {
        try {
            lead.Sourced_from_PRM__c = true;
        } catch (Exception ex) {
            System.debug('LeadTriggerHelper function setSourcedFromPRM : Error ' + ex.getMessage());
        }
    }

    /**
     * @description This method receives the SObjectField of a
     * dependent field and returns a Map with the controlling field values
     * mapped to its dependent field valid values.
     * @param dependToken The SObjectField of the dependent field.
     *
     * @return Map with the controlling field values mapped
     * to the dependent field valid values.
     */
    public static Map<Object, List<String>> getDependentPickListValues(Schema.SObjectField dependToken) {
        Schema.DescribeFieldResult depend = dependToken.getDescribe();
        Schema.SObjectField controlToken = depend.getController();
        if (controlToken == null) return null;
        Schema.DescribeFieldResult control = controlToken.getDescribe();
        List<Schema.PicklistEntry> controlEntries =
                (control.getType() == Schema.DisplayType.BOOLEAN
                        ? null
                        : control.getPicklistValues()
                );

        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        Map<Object, List<String>> dependentPicklistValues = new Map<Object, List<String>>();
        for (Schema.PicklistEntry entry : depend.getPicklistValues()) {
            if (entry.isActive()) {
                List<String> base64chars =
                        String.valueOf
                                (((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')
                                ).split('');
                for (Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++) {
                    Object controlValue =
                            (controlEntries == null
                                    ? (Object) (index == 1)
                                    : (Object) (controlEntries[index].isActive() ? controlEntries[index].getValue() : null)
                            );
                    Integer bitIndex = index / 6, bitShift = 5 - Math.mod(index, 6);
                    if (controlValue == null
                            || bitIndex > base64chars.size() - 1
                            || (base64map.indexOf(base64chars[bitIndex]) & (1 << bitShift)) == 0
                            ) {
                        continue;
                    }
                    if (!dependentPicklistValues.containsKey(controlValue)) {
                        dependentPicklistValues.put(controlValue, new List<String>());
                    }
                    dependentPicklistValues.get(controlValue).add(entry.getValue());
                }
            }
        }
        return dependentPicklistValues;
    }
}