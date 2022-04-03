trigger LeadTrigger on Lead
(before insert, before update, after insert, after update) {
    List<Lead> leadList = Trigger.New;
    Map<Id, Lead> leadMap = Trigger.oldMap;
            
    if (Trigger.isInsert) {
        if (Trigger.isBefore) {
            new LeadTriggerHandler(
                    Trigger.isBefore,
                    Trigger.isAfter,
                    Trigger.isInsert,
                    Trigger.isUpdate,
                    Trigger.isDelete,
                    Trigger.isUndelete,
                    Trigger.isExecuting,
                    Trigger.new,
                    Trigger.old,
                    Trigger.newMap,
                    Trigger.oldMap
            ).execute();

            if(TriggerExecutionMgmt.BypassTrigger('Lead')){ 
                return;
            } else {
                LeadTriggerHelper.fixPhoneFormat(leadList);
                LeadTriggerHelper.recordStatusDuration(leadList, leadMap);
            }
        } else if (Trigger.isAfter) {
            if(TriggerExecutionMgmt.BypassTrigger('Lead')){ 
                return;
            } else {
                LeadTriggerHelper.setManagerFollowLead(true, leadList, leadMap);
                LeadTriggerHelper.leadAddToAdobeCampaign(true, leadList, leadMap);
            }
        }        
    } else if (Trigger.isUpdate) {
        if (Trigger.isBefore) {
            if(TriggerExecutionMgmt.BypassTrigger('Lead')){ 
                return;
            } else {
                LeadTriggerHelper.fixPhoneFormat(leadList);
                LeadTriggerHelper.recordStatusDuration(leadList, leadMap);
            }
        } else if (Trigger.isAfter) {
            if(TriggerExecutionMgmt.BypassTrigger('Lead')){ 
                return;
            } else {
                LeadTriggerHelper.changeOwnerFromSDK2LastModifiyBy(leadList);
                LeadTriggerHelper.setManagerFollowLead(false, leadList, leadMap);
                LeadTriggerHelper.leadAddToAdobeCampaign(false, leadList, leadMap);
            }
        }
    }
}