/**
 * @description Trigger on the Apttus_APTS_Agreement object.
 */
trigger Apttus_APTS_Agreement_c_Trigger on Apttus__APTS_Agreement__c (before insert,
        before update, before delete,
        after insert, after update, after delete
) {
    new Apttus_APTS_Agreement_c_TriggerHandler(Trigger.isBefore, Trigger.isAfter, Trigger.isInsert,
            Trigger.isUpdate, Trigger.isDelete, Trigger.isUndelete, Trigger.isExecuting,
            Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap).execute();
}