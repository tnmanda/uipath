public with sharing class LeadTriggerHelper {
    public static void setManagerFollowLead(boolean isInsert, List<Lead> leadList, Map<Id, Lead> leadMap) {
        Map<Id, Id> leadIdOwnerMaps = new Map<Id, Id>();
        Map<Id, Id> userIdManagerMaps = new Map<Id, Id>();
        Map<Id, Integer> managerIdSubscribeCountMaps = new Map<Id, Integer>();
        Map<Id, Set<String>> leadIdFollowerMaps = new Map<Id, Set<String>>();
        List<EntitySubscription> followersToAdd = new List<EntitySubscription>();

        //Need to update this value if it is increased in the future
        Integer MAX_SUBSCRIBE_COUNT = 500;    

        for(Lead lead : leadList) {
            if(isInsert) {
                if(lead.LeadSource == 'EMEA 2013 Splits Gold Rush') {
                    leadIdOwnerMaps.put(lead.Id, lead.OwnerId);
                    userIdManagerMaps.put(lead.OwnerId, null);
                }
            } else {            
                Lead oldLead = leadMap.get(lead.Id);
                if((lead.LeadSource == 'EMEA 2013 Splits Gold Rush') && ((lead.LeadSource != oldLead.LeadSource) || (lead.OwnerId != oldLead.OwnerId))) {
                    leadIdOwnerMaps.put(lead.Id, lead.OwnerId);
                    userIdManagerMaps.put(lead.OwnerId, null);
                }
            }
        }   

        try  {             
            //Get Manager's Id
            for (User u : [select Id, IsActive, Manager.Id, Manager.IsActive FROM User where Id = :userIdManagerMaps.keySet()]) {
                if(u.IsActive && u.Manager.IsActive) {
                    userIdManagerMaps.put(u.Id, u.Manager.Id); 
                    managerIdSubscribeCountMaps.put(u.Manager.Id, 0);
                }
            }

            //Get ManagerSet for comparing soon
            for (EntitySubscription es : [select Id, ParentId, SubscriberId FROM EntitySubscription where SubscriberId = :managerIdSubscribeCountMaps.keySet() and ParentId = :leadIdOwnerMaps.keySet() order by ParentId]) {
                Set<String> currentFollowerSet = leadIdFollowerMaps.get(es.ParentId);
                if(currentFollowerSet == null) {
                    leadIdFollowerMaps.put(es.ParentId, new Set<String>{es.SubscriberId});
                } else {
                    if(!currentFollowerSet.contains(es.SubscriberId)) {
                        currentFollowerSet.add(es.SubscriberId);
                    }
                }
            }  

            //Get Manager's subscribe count
            for(AggregateResult ar : [select COUNT(Id) FollowerCount, SubscriberId FROM EntitySubscription WHERE SubscriberId = :managerIdSubscribeCountMaps.keySet() GROUP BY SubscriberId]) {
                managerIdSubscribeCountMaps.put((Id)ar.get('SubscriberId'), (Integer)ar.get('FollowerCount'));
            }   

            //Add Manager who hasn't followed yet
            For(Id parentId : leadIdOwnerMaps.keySet()) {
                Id ownerId = leadIdOwnerMaps.get(parentId);
                if(ownerId != null) {
                    Id managerId = userIdManagerMaps.get(ownerId);
                    if(managerId != null) {
                        Integer currentSubscribeCount = managerIdSubscribeCountMaps.get(managerId);
                        if(currentSubscribeCount < MAX_SUBSCRIBE_COUNT) {
                            Set<String> managerSet = leadIdFollowerMaps.get(parentId);
                            if((managerSet == null) || (!managerSet.contains(managerId))) {
                                EntitySubscription newES = new EntitySubscription(); 
                                newES.ParentId = parentId;     
                                newES.SubscriberId = managerId; 
                                followersToAdd.add(newES); 
                                //Increase the SubscribeCount
                                managerIdSubscribeCountMaps.put(managerId, ++currentSubscribeCount);
                            }
                        }
                    }
                }
            }

            if(followersToAdd.size() > 0) {
                insert followersToAdd;
            }
        } catch (exception e) {
            ExceptionHandler.e('TriggerHelper', 'SetManagerFollowLeadHelper', e);
        }
    }
    
    public static void fixPhoneFormat(List<Lead> leadList) {
        for (Lead r : leadList) {               
            // Fix Phone Number issues
            if(r.Lead_Type__c!='WDMS' && r.Phone != null&&r.Phone.length() > 4) {
                r.Phone = PhoneNumberReformat.FixPhoneNumber(r.Phone);
            }
        }
    }
    
    public static void recordStatusDuration(List<Lead> leadList, Map<Id, Lead> leadMap) {
        for (Lead l : leadList) {            
            if(leadMap != null) {
                Lead oldLead = leadMap.get(l.Id);
                if(l.Status == oldLead.Status && l.Ready_to_Convert__c == oldLead.Ready_to_Convert__c) {
                    continue;
                }   
            }

            if(l.Status == 'Open' && l.Ready_to_Convert__c != true) {
                l.TimeWhenInOpen__c = datetime.now();
                l.TimeWhenOutOpen__c = null;
            }
            if(l.Status == 'Attempting to Contact' && l.Ready_to_Convert__c != true) {
                l.TimeWhenOutAttemptingToContact__c = null;
            }
        }
    }
    
    public static void changeOwnerFromSDK2LastModifiyBy(List<Lead> leadList) {
        String SFDCSDKUser='00560000000mgrH';
        String EloquaIntegrationUser='00560000000nOVr';
        Map<ID, Lead> leads2Check=new Map<ID, Lead>();
        Integer i=0;

        for(Lead l:leadList) {
            if(l.ownerID==SFDCSDKUser) {
                leads2Check.put(l.Id,null);
            }
        }

        if(leads2Check.size()>0) {
            List<Lead> leads=[select ID, OwnerID, LastModifiedById from Lead where ID=:leads2Check.keySet()];
            List<Lead> leads4Update=new List<Lead>();

            for(Lead l:leads) {
                //bypass the reassign owner logic if the running user is SFDC SDK itself or Eloqua Integration        
                if(l.LastModifiedById!=SFDCSDKUser&&l.LastModifiedById!=EloquaIntegrationUser) {
                    l.OwnerID=l.LastModifiedById; 
                    leads4Update.add(l);
                }
            }

            if(leads4Update.size()>0) update leads4Update;
        }
    }
    
    public static void leadAddToAdobeCampaign(boolean isInsert, List<Lead> leadList, Map<Id, Lead> leadMap) {
        Set<Id> adobeSF2SFleadIds = new Set<Id>();
        Set<Id> existingleadIds = new Set<Id>();
        List<CampaignMember> campaignMembersToAdd = new List<CampaignMember>();
        
        For(Lead lead : leadList)
        {
            if(isInsert)
            {
                if(lead.Lead_Source_Other__c == 'Adobe SF2SF')
                {
                    adobeSF2SFleadIds.add(lead.Id);
                }
            }
            else
            {            
                if((lead.Lead_Source_Other__c == 'Adobe SF2SF') && (lead.LeadSource != leadMap.get(lead.Id).LeadSource))
                {
                    adobeSF2SFleadIds.add(lead.Id);
                }
            }
        }

        try 
        {
            List<Campaign> campaigns = [SELECT Id FROM Campaign WHERE Name = 'EMEA UK 2013 Adobe Ongoing'];
            if(campaigns.size() == 1) 
            {
                Campaign adobeOngoingCampaign = campaigns[0];                      
                For(CampaignMember campaignMember : [SELECT LeadId FROM CampaignMember WHERE CampaignId = :adobeOngoingCampaign.Id and LeadId = :adobeSF2SFleadIds])
                {           
                    existingleadIds.add(campaignMember.LeadId); 
                } 
                   
                adobeSF2SFleadIds.removeAll(existingleadIds);
                For(Id leadId : adobeSF2SFleadIds)
                {
                    CampaignMember cm = new CampaignMember();
                    cm.CampaignId = adobeOngoingCampaign.Id;
                    cm.LeadId = leadId;
                    campaignMembersToAdd.add(cm);
                } 
                
                if(campaignMembersToAdd.size() > 0)       
                {
                    insert campaignMembersToAdd;
                }  
            }
        }
        catch (exception e) 
        {
            ExceptionHandler.e('LeadTriggerHelper', 'LeadAddToAdobeCampaign', e);
        }
    }
}