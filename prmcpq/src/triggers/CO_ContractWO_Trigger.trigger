trigger CO_ContractWO_Trigger on ContractWO__c (before update,after update, before insert, after insert, before delete) {
    new CO_ContractWO_TriggerHandler(
            Trigger.isBefore,
            Trigger.isAfter,
            Trigger.isInsert,
            Trigger.isUpdate,
            Trigger.isDelete,
            Trigger.isExecuting,
            Trigger.new,
            Trigger.old,
            Trigger.newMap,
            Trigger.oldMap
    ).execute();

    if(!trigger.isDelete){
    final Integer AP_REVIEW_CREDIT = 1;
    final Integer CONTRACT_VALIDATION = 2;
    final Integer AP_LEGAL = 3;
    final Integer AP_REVENUE_ASSURANCE = 4;
    final Integer AP_LEGAL_DOCUMENT_EXECUTION = 5;
    final Integer AP_ORDER_DESK = 6;
    final Integer AP_SITE_BCO_COMMISIONS = 7;
    final String APTTUS_CONTRACT_ACTIVATED = 'Activated';
    
    list<Case> lstCases = new list<Case>();
    
    final String LEGAL_STR = 'Legal';
    final String DOCEX_STR = 'Document Execution';
    final String CUSTOMER_SIGNATURE = 'Customer Signature';
    final string CONTRADMIN ='Contract Admin';
    final string CONTRADMIN2 ='Contract Admin2';
    final String APAC_REGION = 'APAC';
    final Integer AP_PM_ORDER_DESK = 7;
    final Integer AP_PM_LEGAL_DOCUMENT_EXECUTION = 6;
    // Create a map that stores all the objects that require editing 
    Map<Id, ContractWO__c > approvalStatements = new Map<Id, ContractWO__c >();
        
    // Create a map that stores all the objects that require manager field update
    Map<Id, Set<ContractWO__c> > contractManagers = new Map<Id, Set<ContractWO__c> >();
    // Create a map that stores all the objects that are on completed status
    Set<Id> approvalCompleted = new Set<Id>();
    Set<Id> approvalPriceSheetCompleted = new Set<Id>();

    // Create a Set that stores all the Order Headers to create
    // NOT LONGER IN USE: List<Order_Header__Share> sharedOrderHeaders = new List<Order_Header__Share>{};
    //Create a map that stores all the objects to query on
    Map<Id, ContractWO__c > contractOrders = new Map<Id, ContractWO__c >();
    
    //Used to move contracts from one approval process to another one
    String stepsBefore = CO_Util.getApprovalProcessSteps(true);
    String stepsAfter = CO_Util.getApprovalProcessSteps(false);
    system.debug('the step before  is'+stepsBefore );
    system.debug('the step  after is'+stepsAfter  );
    
    Map<Id, Apttus__apts_Agreement__c> mapOfAgreements = new Map<Id, Apttus__apts_Agreement__c>();
    
        
    List<ContractWO__c> contractOrderList = [SELECT Id,order_header__r.Owner__r.isActive,order_header__r.Owner__r.Id,
                                                    company_number__r.Owner.IsActive,company_number__r.Owner.Id,
                                                    company_number__r.id,order_header__r.id,(SELECT ID, Description, ParentId    
                                                                                             FROM ATTACHMENTS
                                                                                             WHERE Description = 'Signed Contract')
                                             FROM ContractWO__c WHERE id in :Trigger.new];
    
    contractOrders = new Map<Id, ContractWO__c >(contractOrderList);
    
    if (Trigger.isBefore ) {
       
        if  (Trigger.isInsert) {
            for (Integer i = 0; i < Trigger.new.size(); i++) {    
                ContractWO__c contract = Trigger.new[i];
                  if (!Co_Validations.isValidProduct(contract.product__c,       contract.product_audio__c, 
                                                   contract.product_video__c, contract.product_ancillary__c, 
                                                   contract.IS_Product__c, 
                                                   contract.multi_product__c, contract.product_west_cloud__c, 
                                                   contract.contract_type__c,contract.Ucaas__c)) {
                   contract.addError('Operation Cancelled: This contract does not have a valid product');
                }
            }        
        }
    
        if  (Trigger.isUpdate ){      
            //GET AGREEMENT OBJECTS TO VALIDATE
            for (apttus__apts_agreement__c agreement : [SELECT APTPS_Contract_Order__c, Billing_Contact__r.Contact_Terminated__c
                                                          FROM apttus__apts_agreement__c
                                                         WHERE APTPS_Contract_Order__c in :Trigger.new]) {
                mapOfAgreements.put(agreement.APTPS_Contract_Order__c, agreement);
            }
        
            
            Integer i = 0;
            For(ContractWO__c contract: trigger.new) {
                ContractWO__c contract_old = Trigger.old[i];
                i++;
                if(contract_old.Last_Approval_Step_Name__c == 'WCC'){
                    system.debug('old in WCC'+contract.Last_Approval_Step_Name__c);
                }
            
                //Remove SOQL to retrieve the order header active owner
                if (contractOrders.get(contract.id).order_header__r.Owner__r.isActive == false) {
                       contract.addError('Operation Cancelled: This contract is attached to inactive user.  Reassign it through the Order Header to an active user...');
                }
                if (contract.contract_active_owner__c != contractOrders.get(contract.id).order_header__r.Owner__r.Id) {
                    contract.contract_active_owner__c = contractOrders.get(contract.id).order_header__r.Owner__r.Id;
                      
                    if (!contractManagers.containsKey(contractOrders.get(contract.id).order_header__r.Owner__r.Id)){
                        Set<ContractWO__c> contractsTempSet = new Set<ContractWO__c>{contract};
                        contractManagers.put(contractOrders.get(contract.id).order_header__r.Owner__r.Id,contractsTempSet);
                    }else{
                        Set<ContractWO__c> contractsSet = contractManagers.get(contractOrders.get(contract.id).order_header__r.Owner__r.Id);
                        contractsSet.add(contract);
                        contractManagers.put(contractOrders.get(contract.id).order_header__r.Owner__r.Id,contractsSet);   
                    }
                }
                
                //VALIDATE AGREEMENT OBJECT
                Apttus__apts_agreement__c validateAgr = mapOfAgreements.get(contract.id);
                if (validateAgr != null && validateAgr.Billing_Contact__r.Contact_Terminated__c) {
                   contract.addError('Operation Cancelled: Billing Contact is terminated. Please, notify to the SalesRep.', false);
                }
  
  
                System.debug('Venkuram:Approval_Comment_Check__c = '+contract.Approval_Comment_Check__c);
                            
                if (contract.Approval_Comment_Check__c == 'Requested')
                { 
                  approvalStatements.put(contract.Id, contract);
                  // Reset the field value to null, 
                  // so that the check is not repeated,
                  // next time the object is updated
                  contract.Approval_Comment_Check__c = null; 
                }
                
                //Added for CMS-1622
                contract.Previous_Status__c = contract_old.Approver__c;
                
                system.debug('----trigger----contract.Last_Approval_Step__c'+contract.Last_Approval_Step__c );
                  system.debug('----trigger----contract.Last_Approval_Step_Name__c '+contract.Last_Approval_Step_Name__c );
                //system.debug('----trigger----contract.IsSignedContract__c'+contract.IsSignedContract__c );
                //******CUSTOMER SIGNATURE SIGNED CONTRACT AND REQUIRED DATE RELATED FUNTIONS****
                //validation for contract required date when approval reaches
                // customer signature stage.
                //This validation also checks for Contract required date grater then todays date                
                if (contract_old.Last_Approval_Step_Name__c == CUSTOMER_SIGNATURE  &&
                    contract.Last_Approval_Step__c > contract_old.Last_Approval_Step__c &&
                    contract.Contract_Required_Date__c == null && 
                    contract.Approver__c != 'ReSubmit' &&
                    contract.Region__c != APAC_REGION) {
                    contract.addError('Operation Cancelled: ' + Schema.getGlobalDescribe().get('ContractWO__c').getDescribe().fields.getMap().get('Contract_Required_Date__c').getDescribe().getLabel() + ' is mandatory.');                  
                }
                //validation for contract required date ends
                
               
                if (contract.Signed_Contract_at_customer_signature__c == false && contractOrders.get(contract.id).ATTACHMENTS.size()>0) {
                    contract.Signed_Contract_at_customer_signature__c = true;
                }
                
                
                if (contract_old.Last_Approval_Step_Name__c == CUSTOMER_SIGNATURE  &&
                    contract.Last_Approval_Step__c > contract_old.Last_Approval_Step__c &&
                    contract.Signed_Contract_at_customer_signature__c == false && 
                    contract.Approver__c != 'ReSubmit')                         
                    { 
                    //Validates if there is a signed contract (against apttus and attachment object)
                    if (CO_Util.hasSignedContract(contract.name) == false) {
                       contract.addError('You cannot proceed with the order, please import a signed contract or process it through eSignature button.');
                    }
                }

                //******CUSTOMER SIGNATURE SIGNED CONTRACT AND REQUIRED DATE RELATED FUNTIONS ENDS****

                //Storing all the completed contract to update the GRA Request if needed
                if (contract.Last_Approval_Step__c == -1 && contract.Global_Rate_Approval_Request__c)
                {
                    System.debug('Completed Contract Using GRA Request:'+contract.GRA_Request__c);
                    approvalCompleted.add(contract.GRA_Request__c);
                }else if (contract.Last_Approval_Step__c == -1 && contract.Rate_Definition__c == 'Price Sheet'){
                    approvalPriceSheetCompleted.add(contract.price_sheet__c);
                }
                
                
                //Check if the contract requires Contract Insurance
                contract.Required_Revenue_Insurance__c = /*(contract.Region__c == 'NA') ? True :*/ False ;
                contract.Last_update__c = date.today();
                
                contract.NA_Web_Special_Case__c = CO_Validations.isWebSpecialTerms(contract);
                
                if (contract.Contract_type__c == CO_Constants.STR_CT_VIDEO) {
                    contract.BJN_or_Vidyo__c = CO_Validations.isBJNorVidyo(contract);
                }
                
                if (contract.Contract_type__c == CO_Constants.STR_CT_VIDEO || contract.Contract_type__c == CO_Constants.STR_CT_DOLBY_AUDIO) {
                    contract.Current_Video_Approval_Step_Name__c = CO_Util.calCurrentVideoApprovalStepName(contract);
                }
                
                /*if(contract.contract_type__c == CO_Constants.STR_CT_WestIP || contract.contract_type__c == CO_Constants.STR_CT_WestIS ||contract.contract_type__c ==CO_Constants.STR_CT_MULTIPRODUCT ){
                   contract.step_name__c = CO_Util.getStepName(contract); 
                }
                
                if(contract.Product__c == CO_Constants.STR_DedicatedSupport){
                   contract.step_name__c = CO_Util.getStepname(contract);
                }
                
                if(contract.Product__c == CO_Constants.STR_DedicatedSupport || contract.Product__c == CO_Constants.CNST_WebEx_Trial ){
                   contract.step_name__c = CO_Util.getStepname(contract);
                }
                
                if(contract.Product__c == CO_Constants.STR_WebExCCA){
                   contract.step_name__c = CO_Util.getStepname(contract);
                }
                if(contract.NA_Web_Special_Case__c ){
                   contract.step_name__c = CO_Util.getStepName(contract); 
                }                                 
                //Change made by Venkatesh on 28th November 2018
                if(contract.Contract_Type__c  == CO_Constants.STR_CT_WESTCLOUD && contract.Region__c == CO_Constants.STR_EMEA){
                   contract.step_name__c = CO_Util.getStepname(contract);
                } */
                
               // contract.step_name__c = CO_Util.getStepName(contract);
               // system.debug('the stepname'+contract.step_name__c);
                              
                //Change made by Venkatesh on 22 July 2013
                contract.Last_Approval_Step__c = CO_StepSkipHandler.skipProductManagementStep(contract);
                        
                //WEB- WVC 336- 
                //Change made by Vinay on 22 Oct 2012
                //Modified by Venkatesh on 14th Aug 2013
                contract.Last_Approval_Step__c = CO_StepSkipHandler.skipContractValidationStep(contract);
                
                //Change made by Venkatesh on 17 December 2015
                contract.Last_Approval_Step__c = CO_StepSkipHandler.assignOrderDeskToWebExTrial(contract);                               
                
                //WEB
                //Change made by Vinay on 23 Aug 2012 | US 132
                System.debug('---contract.Product__c---'+ contract.Product__c);
                if (contract.Contract_type__c == CO_Constants.STR_CT_WEB) {

                    //For Web Product InterCall Unified Meetings, open a case and stop ContractWO from assigning further approver
                    if (contract.Product__c == CO_Constants.STR_InterCall_Unified_Meeting){
                        contract.Last_Approval_Step__c = CO_StepSkipHandler.skipOrderDeskStep(contract_old, contract);
                    }                   
                } 
                
                //Changes done by Venkatesh on 24 Oct 2013 for a production issue reported related to re-assignment;
                if (CO_Validations.isWebSpecialTerms(contract)){
                    //Automatically Change Approver when pending Product Management
                    //Automatically Change Approver once approved by WCC, pending Contract Validation
                    //Automatically Change Approver once approved by Commercial Validation, pending Legal
                    //Automatically Change Approver once approved by Document Execution, pending Order Desk
                    //Automatically Change Approver once approved by Order Desk, pending billing\commissions
                    if ((contract.Last_Approval_Step__c == 0 || contract.Last_Approval_Step__c == 2
                        || contract.last_Approval_Step__c == 3 || contract.last_Approval_Step__c == 5
                        || contract.Last_Approval_Step__c == 6 || contract.Last_Approval_Step__c == 7 ) 
                        && contract.last_Approval_Step__c != contract_old.last_Approval_Step__c) {
                        contract.Pending_For_Approver_Reassignment__c = true;
                    }
                }
                else 
                {
                    //Automatically Change Approver once approved by WCC, pending Contract Validation
                    //Automatically Change Approver once approved by Commercial Validation, pending Legal
                    if (contract.Contract_type__c  == CO_Constants.STR_CT_NDAMCA && contract.Last_Approval_Step__c == 0 
                        && contract.last_Approval_Step__c != contract_old.last_Approval_Step__c){
                        contract.Pending_For_Approver_Reassignment__c = true;
                    }
                    system.debug('prod issue test'+contract.Pending_For_Approver_Reassignment__c);
                    //Automatically Change Approver once approved by WCC, pending Contract Validation
                    //Automatically Change Approver once approved by Commercial Validation, pending Legal
                    if ((contract.Last_Approval_Step__c == 1 || contract.last_Approval_Step__c == 2 
                         || contract.last_Approval_Step__c == 3) 
                        && contract.last_Approval_Step__c != contract_old.last_Approval_Step__c){
                        contract.Pending_For_Approver_Reassignment__c = true;
                        system.debug('prod issue test1'+contract.Pending_For_Approver_Reassignment__c);
                    }
                    //Automatically Change Approver once approved by Document Execution, pending Order Desk
                    //Automatically Change Approver once approved by Document Execution, pending Order Desk
                    if ((contract.last_Approval_Step__c == 4 || contract.Last_Approval_Step__c == 5
                        || contract.Last_Approval_Step__c == 6) 
                        && contract.last_Approval_Step__c != contract_old.last_Approval_Step__c
                        && contract.Second_Commercial_Validation__c == false){
                           contract.Pending_For_Approver_Reassignment__c = true;
                    }        
                    if ((contract.last_Approval_Step__c == 5 || contract.Last_Approval_Step__c == 6
                        || contract.Last_Approval_Step__c == 7) 
                        && contract.last_Approval_Step__c != contract_old.last_Approval_Step__c
                        && contract.Second_Commercial_Validation__c == true){
                           contract.Pending_For_Approver_Reassignment__c = true;
                    }  
                }
                                   
                // VIDEO
                if (contract.Contract_type__c  == CO_Constants.STR_CT_VIDEO){
                    contract.Last_Approval_Step__c = CO_StepSkipHandler.skipVideoMiscellaneousSteps(contract_old, contract);

                    if (contract.last_Approval_Step__c != contract_old.last_Approval_Step__c &&
                        contract.Pending_For_Approver_Reassignment__c == false) {
                        contract.Pending_For_Approver_Reassignment__c = true;
                    }
                }
                
                // NDA - MCA PRODUCT TYPE
                if (contract.Contract_type__c  == CO_Constants.STR_CT_NDAMCA) {    
                    if (contract.last_Approval_Step__c != contract_old.last_Approval_Step__c &&
                        contract.Pending_For_Approver_Reassignment__c == false) {
                        contract.Pending_For_Approver_Reassignment__c = true;
                    }                             
                }
                
                // Ucaas - CSA Product type 
                if(contract.contract_type__c == CO_Constants.STR_CT_Ucaas ){
                   if (contract.last_Approval_Step__c != contract_old.last_Approval_Step__c &&
                        contract.Pending_For_Approver_Reassignment__c == false && contract.Last_Approval_Step__c == 230){
                        contract.Pending_For_Approver_Reassignment__c = true;
                        }
                }
                

                // CREATES THE APPROVAL ASSIGNEE FOR LEGAN AND DOC.EXE. STEPS
                //if (contract.Last_Approval_Step__c != contract_old.Last_Approval_Step__c) 
                system.debug('Venkuram:CO_ContractWO_Trigger: Old_Last_Approval_Step__c --> '+contract_old.Last_Approval_Step__c);
                system.debug('Venkuram:CO_ContractWO_Trigger: New_Last_Approval_Step__c --> '+contract.Last_Approval_Step__c); 
                system.debug('Venkuram:CO_ContractWO_Trigger: Old_Last_Approval_Step_Name__c --> '+contract_old.Last_Approval_Step_Name__c);
                system.debug('Venkuram:CO_ContractWO_Trigger: New_Last_Approval_Step_Name__c --> '+contract.Last_Approval_Step_Name__c);  
                                             
                if (contract.Last_Approval_Step_Name__c == 'Legal' || contract.Last_Approval_Step_Name__c == 'Document Execution') {
                     system.debug('Venkuram:CO_ContractWO_Trigger: Inside condition');
                     if (contract_old.Last_Approval_Step_Name__c != contract.Last_Approval_Step_Name__c) {
                         CO_Approval_Owner.addApprovalAssignee(contract, true);
                         system.debug('Venkuram_23022017: Before Update Condition');
                     } else {
                        CO_Approval_Owner.addApprovalAssignee(contract, false);
                         system.debug('Venkuram_02032017: after Update Condition');
                     }
                }  
                
                // CREATES THE APPROVAL ASSIGNEE FOR contract admin and Document execution {contract admin1}
                if ( contract.Ucaas__c =='UCaaS CSA/SA' && 
                    (contract.Last_Approval_Step_Name__c == 'Contract Admin' || contract.Last_Approval_Step_Name__c =='Contract Admin2') ) {
                     system.debug('Test:CO_ContractWO_Trigger: Inside condition');
                     if (contract_old.Last_Approval_Step_Name__c != contract.Last_Approval_Step_Name__c) {
                         CO_Approval_Owner.addApprovalAssigneecontadm(contract, true);
                         system.debug('test: Before Update Condition');
                         system.debug('test the assignee' +contract);
                     } else {
                        CO_Approval_Owner.addApprovalAssigneecontadm(contract, false);
                         system.debug('test: After Update Condition');
                     }
                }  
                
                        
                
                if (contract_old.approver__c.equals('ReSubmit') && contract.approver__c.equals('Pending')) {
                    contract.Pending_for_Approver_Reassignment__c = true;
                }   
                
                if (contract.approver__c.equals('ReSubmit') && contract_old.approver__c.equals('Pending')) {
                    if (contract.inactive_days__c == 90) {
                        contract.Approver__c = 'Closed';
                    }
                }      
                
                if (contract.approver__c.equals('Pending') && 
                   (contract_old.approver__c.equals('Pending Submit for Approval') || contract_old.approver__c.equals('ReSubmit'))) {
                   if (contract.skip_wcc__c || (contract.reject_from__c != null && contract.reject_from__c != 'WCC'))
                   {
                      contract.wcc_approved__c = true;
                   }
                }
                
                if (contract.Approver__c.equalsIgnoreCase('Contract Completed')) {
                   FeedItem post = new FeedItem();
                   post.ParentId = contract.id; 
                   post.Body = 'This contract has been completed.';
                   insert post;             
                   
                   contract.ActualApprover__c = '';
                   contract.Last_Approver__c = '';
                   contract.AssignedTo__c = '';                   
                }        
                
                // Updating the Is_Document_Attached__c when any Attchment added or deleted.
                contract.Is_Document_Attached__c = CO_Util.hasAttachment(contract); 
                 system.debug('the attachment in trigger'+contract.Is_Document_Attached__c);
                //Venkatesh Rambothu: Added for the CMS-1652
                if (contract.APTS_Apttus_Status__c != null &&
                    contract.Approver__c != null &&
                    contract.APTS_Apttus_Status__c != contract_old.APTS_Apttus_Status__c &&
                    contract.APTS_Apttus_Status__c == APTTUS_CONTRACT_ACTIVATED &&
                    contract.Approver__c == 'Pending' && 
                    contract.Last_Approval_Step_Name__c == 'Customer Signature'
                    ) {
                    if(contract.Contract_Required_Date__c == null) {
                        contract.Contract_Required_Date__c = System.today();
                    }
                }
                
                        // creating new record in CO_TCVQuotaRetirement.
                if(contract.QRF_Created__c == false && ((!(contract.contract_type__c != 'Non-Disclosure Agreement' || contract.Product_By_Contract_Type__c == 'WebEx Trial') && contract_old.Last_Approval_Step__c == -10 && contract.Last_Approval_Step__c == 6)
                    || ((contract_old.Last_Approval_Step_Name__c == 'Document Execution') 
                            && contract.Last_Approval_Step__c > contract_old.Last_Approval_Step__c) 
                   || (COntract.contract_type__c == 'UCaaS' && contract_old.Last_Approval_Step_Name__c == 'Contract Admin2'))) {
                                System.debug('inside TCV Class');
                    CO_TCVQuotaRetirement.createTCVQuotaRetirement(contract);
                       contract.QRF_Created__c = true;
                } 
                
                contract.step_name__c = CO_Util.getStepName(contract);
                system.debug('the second stepname'+contract.step_name__c);
           /*  
            // Auto populating PMR fields
            if(contract.PMR_Created__c == false && Contract.Ucaas__c == 'UCaaS CSA/SA' && contract_old.Last_Approval_Step__c == 4 && contract.Last_Approval_Step__c == 5){
                   || ((contract_old.Last_Approval_Step_Name__c == 'Customer Signature') 
                            && contract.Last_Approval_Step__c > contract_old.Last_Approval_Step__c) 
                   || (COntract.contract_type__c == 'UCaaS' && contract_old.Last_Approval_Step_Name__c == 'Sales /Cust Review')) 
                   
                     System.debug('inside PMR Class');
                    CO_PMRCreationForHoot.AutoCreatePMRequest(contract);
                       contract.PMR_Created__c = true;
            }
                */
            }
            //  Check Comments mandatory
            if (!approvalStatements.isEmpty())  
            {
                Id ContractOrderId;
               
                // Get the last approval process step for the approval processes, 
                // and check the comments.
                for (ProcessInstance pi : [SELECT TargetObjectId, 
                                            (SELECT Id, StepStatus, Comments 
                                             FROM StepsAndWorkitems
                                             ORDER BY CreatedDate DESC
                                              LIMIT 1 
                                              )
                                           FROM ProcessInstance
                                           WHERE TargetObjectId In 
                                                :approvalStatements.keySet()
                                           ORDER BY TargetObjectId,CreatedDate DESC
                                          ])
                { 
                  // We first need to make sure we are only checking for the first instance of a TargetObjectId
                  if (ContractOrderId != pi.TargetObjectId){
                      //Set ContractOrderId to the latest TargetObjectId
                      ContractOrderId = pi.TargetObjectId;
                      System.debug('Venkuram:StepsAndWorkitems '+pi.StepsAndWorkitems);
                      // If no comment exists, then prevent the object from saving.                 
                      if ((pi.StepsAndWorkitems[0].Comments == null || 
                           pi.StepsAndWorkitems[0].Comments.trim().length() == 0) && pi.StepsAndWorkitems[0].StepStatus == 'Rejected')
                      {
                        approvalStatements.get(pi.TargetObjectId).addError(
                         'Operation Cancelled: Please provide a reason ' + 
                         'for your rejection!');
                      }
                  }
                }  
            }
            
            
            //Check if we have GRA Request to update
            if (approvalCompleted.size()>0 || approvalPriceSheetCompleted.size()>0){
                //First getting the GRA directly assigned to the Contract Order
                System.debug('Completed Contract Using GRA Request:'+approvalCompleted.size());
                List<GRA_Request__c> GRARequests = [SELECT Status__c 
                                                    FROM GRA_Request__c 
                                                    WHERE id IN :approvalCompleted
                                                    AND Status__c in ('Approved - NOT in Metratech (Contract)','Approved - NOT in Metratech (Addendum)','Approved - NOT in Metratech')];            

                //Then getting the GRA assigned to a Price Sheet attached to the Contract Order
                System.debug('Completed Contract Using Price Sheet:'+approvalPriceSheetCompleted.size());
                List<Id> priceSheetGRARequestIds = new List<id>();
                
                for(Price_Sheet_Company_GRA_Request__c a : [SELECT GRA_Request__r.id
                                                            FROM Price_Sheet_Company_GRA_Request__c
                                                            WHERE Price_Sheet_Company_GRA__r.Price_Sheet_Company__r.Price_Sheet__c 
                                                            IN :approvalPriceSheetCompleted])
                {
                    priceSheetGRARequestIds.add(a.GRA_Request__r.id);
                } 
                GRARequests.addAll([SELECT Status__c 
                                    FROM GRA_Request__c 
                                    WHERE id IN :priceSheetGRARequestIds
                                    AND Status__c in ('Approved - NOT in Metratech (Contract)','Approved - NOT in Metratech (Addendum)','Approved - NOT in Metratech')]);

                System.debug('GRARequests:'+GRARequests.size());  
               for (GRA_Request__c GRARequest : GRARequests ){
                    System.debug('Update Completed Contract Using GRA Request:'+GRARequest.Id);
                    GRARequest.Status__c = 'Approved';
                    GRARequest.Update_MT__c = TRUE;
               }
               //Update the status of not in Metratech yet
               update GRARequests   ;
            }
            //Check if we have manager to update
            if (contractManagers.size() > 0){
                List<User> managers = [SELECT ManagerId FROM User WHERE id in :contractManagers.keySet()];
                if (managers.size() > 0) {
                      for (User manager : managers){
                        if (contractManagers.containsKey(manager.Id)){
                            for(ContractWO__c tempContract : contractManagers.get(manager.Id)){
                                tempContract.sales_Manager__c = manager.ManagerId;                                    
                            }
                        }
                      }                      
                }
            }
        }
    }
    else  //After Update 
    {
        Map<Id, String> contractIdApproverMap = new Map<Id, String>(); 
        //Update the Agreement Object status if exists
        for (Integer i = 0; i < Trigger.new.size(); i++) {
            if (Trigger.isUpdate) {
                ContractWO__c updatedContract = trigger.new[i];
                //if CONTRACT STATUS CHANGES, UPDATE THE AGREEMENT STATUS
                if (updatedContract.approver__c != trigger.OldMap.get(updatedContract.Id).approver__c) { 
                    contractIdApproverMap.put(Trigger.new[i].Id, Trigger.new[i].Approver__c); 
                }
            }
        }        
        List<Apttus__APTS_Agreement__c> agreementsToUpdateApprover = new List<Apttus__APTS_Agreement__c>();
        for(Apttus__APTS_Agreement__c agreement : [SELECT Id, CO_Approval_Status_Text__c, APTPS_Contract_Order__c FROM Apttus__APTS_Agreement__c WHERE APTS_Related_Contract_Order__c = :contractIdApproverMap.keySet()])
        {
            agreement.CO_Approval_Status_Text__c = contractIdApproverMap.get(agreement.APTPS_Contract_Order__c);
            agreementsToUpdateApprover.add(agreement);
        }
        if(!agreementsToUpdateApprover.isEmpty())
        {
            update agreementsToUpdateApprover;
        }
        
        CO_CreateCaseForContractWO  ccfc = new CO_CreateCaseForContractWO();
        List<Case> lstCasesAPAC = new List<Case>();
        List<Id> rejectedContractIdList = new List<Id>();
        for (Integer i = 0; i < Trigger.new.size(); i++) {
            if (Trigger.isUpdate) {
                System.debug('********* Contract:' + Trigger.old[i].Name);
                System.debug('********* Old Last_Approval_Step__c:' + Trigger.old[i].Last_Approval_Step__c);
                System.debug('********* New Last_Approval_Step__c:' + Trigger.new[i].Last_Approval_Step__c);
                System.debug('********* Old Last_Approval_Step_Name__c:' + Trigger.old[i].Last_Approval_Step_Name__c);
                System.debug('********* New Last_Approval_Step_Name__c:' + Trigger.new[i].Last_Approval_Step_Name__c);
                System.debug('********* New Pending_For_Approver_Reassignment__c :' + Trigger.new[i].Pending_For_Approver_Reassignment__c );
                System.debug('********* New Status:' + Trigger.new[i].Approver__c);
                System.debug('********* New Rejected from :' + Trigger.new[i].Reject_From__c);

                //CREATE CASES FOR APAC
                Case item = null;
                if (Trigger.new[i].Region__c == 'APAC') {
                   if (Trigger.new[i].Last_Approval_Step_Name__c != Trigger.old[i].Last_Approval_Step_Name__c &&
                       Trigger.new[i].Last_Approval_Step_Name__c == 'Commercial Validation') {
                      item = ccfc.createCaseForAPAC(Trigger.new[i]);
                   }
                   if (Trigger.new[i].Last_Approval_Step_Name__c != Trigger.old[i].Last_Approval_Step_Name__c &&
                       Trigger.new[i].Last_Approval_Step_Name__c == 'Order Desk') {
                      item = ccfc.createCaseForAPAC(Trigger.new[i]);
                   }
                   if (Trigger.new[i].Last_Approval_Step_Name__c != Trigger.old[i].Last_Approval_Step_Name__c &&
                       Trigger.new[i].Last_Approval_Step_Name__c != null &&
                       Trigger.new[i].Last_Approval_Step_Name__c.contains('BCO')) {
                       String sendToGroup = CO_Email_Addresses__c.getValues('APAC Commission email to').Queue_Target__c;
                       CO_EmailTemplate.sendEmailToGroup(Trigger.new[i].id, sendToGroup, UserInfo.getName() );
                   }                   
                } 
                if (item != null) {
                   lstCasesAPAC.add(item);
                }
            
                // UPDATES APPROVAL_ASSIGNEE
                if (Trigger.old[i].Last_Approval_Step_Name__c == 'Legal' || Trigger.old[i].Last_Approval_Step_Name__c == 'Document Execution') {
                   //Contract goes from Legal to next step 
                   if ( Trigger.old[i].Last_Approval_Step_Name__c == LEGAL_STR &&
                        Trigger.new[i].Last_Approval_Step_Name__c == DOCEX_STR){
                        //continue;  //NEXT ITERATION
                        system.debug('Venkuram_23021017: Inside Condition 1');
                   }
                   else
                   if ( Trigger.new[i].Last_Approval_Step__c != Trigger.old[i].Last_Approval_Step__c  && 
                        Trigger.new[i].Last_Approval_Step__c >  Trigger.old[i].Last_Approval_Step__c  &&
                        Trigger.new[i].Approver__c == 'Pending' && Trigger.old[i].Approver__c == 'Pending') {
                       CO_Approval_Owner.updateApprovalAssignee(Trigger.old[i], UserInfo.getUserId());
                       system.debug('Venkuram_23021017: Inside Condition 2');
                   }
                   else    
                   //contract is rejected in legal step
                   if ( Trigger.new[i].Last_Approval_Step__c == Trigger.old[i].Last_Approval_Step__c  && 
                        (Trigger.new[i].Approver__c == 'Rejected' || Trigger.new[i].Approver__c == 'ReSubmit') && Trigger.old[i].Approver__c == 'Pending') {
                       CO_Approval_Owner.updateApprovalAssignee(Trigger.old[i], UserInfo.getUserId());
                       system.debug('Venkuram_23021017: Inside Condition 3');
                   } 
                   else
                   if ((Trigger.new[i].Last_Approval_Step_Name__c == 'WCC' || Trigger.new[i].Last_Approval_Step_Name__c == 'Commercial Validation') &&
                        (Trigger.new[i].Approver__c == 'Pending' && Trigger.old[i].Approver__c == 'Pending' ) ) {
                       CO_Approval_Owner.updateApprovalAssignee(Trigger.old[i], UserInfo.getUserId());
                       system.debug('Venkuram_23021017: Inside Condition 4');
                   } 
                   
                }
                
                // UPDATES APPROVAL_ASSIGNEE FOR CONTRACT ADMIN
                 if ((Trigger.old[i].Last_Approval_Step_Name__c == 'Contract Admin'|| Trigger.old[i].Last_Approval_Step_Name__c == 'Contract Admin2')) {                
                   //Contract goes from contract Admin to next step 
                   if ( Trigger.old[i].Last_Approval_Step_Name__c == CONTRADMIN &&
                        Trigger.new[i].Last_Approval_Step_Name__c == CONTRADMIN2 ){
                        //continue;  //NEXT ITERATION
                        system.debug('Testcontractadmin1: Inside Condition 1');
                   }
                   else
                   if ( Trigger.new[i].Last_Approval_Step__c != Trigger.old[i].Last_Approval_Step__c  && 
                        Trigger.new[i].Last_Approval_Step__c >  Trigger.old[i].Last_Approval_Step__c  &&
                        Trigger.new[i].Approver__c == 'Pending' && Trigger.old[i].Approver__c == 'Pending') {
                       CO_Approval_Owner.updateApprovalAssigneecontadmin(Trigger.old[i], UserInfo.getUserId());
                       system.debug('Testcontractadmin2: Inside Condition 2');
                   }
                   else    
                   //contract is rejected in contract admin step
                   if ( Trigger.new[i].Last_Approval_Step__c == Trigger.old[i].Last_Approval_Step__c  && 
                        (Trigger.new[i].Approver__c == 'Rejected' || Trigger.new[i].Approver__c == 'ReSubmit') && Trigger.old[i].Approver__c == 'Pending') {
                       CO_Approval_Owner.updateApprovalAssigneecontadmin(Trigger.old[i], UserInfo.getUserId());
                       system.debug('Testcontractadmin3: Inside Condition 3');
                   } 
                   else
                   if ((Trigger.new[i].Last_Approval_Step_Name__c == 'WCC' || Trigger.new[i].Last_Approval_Step_Name__c == 'Commercial Validation') &&
                        (Trigger.new[i].Approver__c == 'Pending' && Trigger.old[i].Approver__c == 'Pending' ) ) {
                       CO_Approval_Owner.updateApprovalAssigneecontadmin(Trigger.old[i], UserInfo.getUserId());
                       system.debug('Testcontractadmin4: Inside Condition 4');
                   } 
                   
                }
            }    
            

            if (Trigger.new[i].Approver__c == 'Rejected'){
                rejectedContractIdList.add(Trigger.new[i].Id);                
            }
                        

            if (Trigger.new[i].APTS_Apttus_Status__c != null &&
                Trigger.new[i].Approver__c != null &&
                Trigger.new[i].APTS_Apttus_Status__c != Trigger.old[i].APTS_Apttus_Status__c &&
                Trigger.new[i].APTS_Apttus_Status__c == APTTUS_CONTRACT_ACTIVATED &&
                Trigger.new[i].Approver__c == 'Pending') {
                //CO_ApttusInterface.doApproveContract(Trigger.new[i]); //Venkatesh Rambothu: commented for the CMS-1402
            }
            
            //Venkatesh Rambothu: Added for the CMS-1379
            if (Trigger.new[i].APTS_Apttus_Status__c != null &&
                Trigger.new[i].Approver__c != null &&
                Trigger.new[i].APTS_Apttus_Status__c != Trigger.old[i].APTS_Apttus_Status__c &&
                Trigger.new[i].APTS_Apttus_Status__c == APTTUS_CONTRACT_ACTIVATED &&
                Trigger.new[i].Approver__c == 'Pending' && 
                Trigger.new[i].Last_Approval_Step_Name__c == 'Customer Signature'
                ) {
                ApexPages.StandardController sc = new ApexPages.StandardController(Trigger.new[i]);
                CO_ContractNavigationExtension coNavigation = new CO_ContractNavigationExtension(sc);
                coNavigation.doApproveContract();
                System.debug('********* CO Moved to DE step *********');
            }

            if (trigger.isUpdate) {
                String moveContract = CO_Util.moveToFollowingApprovalProcess(Trigger.new[i], Trigger.old[i], stepsBefore, stepsAfter);
                system.debug('the update trigger'+moveContract );
                
                if (moveContract != null ) {
                    CO_Approval.submitContractFuture(Trigger.new[i].id, moveContract);
                    system.debug('the update trigger1'+moveContract );
                }
            }
            //The previous call should replace all these calls            
            //CMS-1074
            //Changes made by Venkatesh on 20th May 2015
            //CMS-1169
            /*
            if (
                Trigger.new[i].Approver__c == 'Pending' && 
                Trigger.new[i].Last_Approval_Step_Name__c == 'Document Execution' && 
                Trigger.new[i].Pending_For_Approver_Reassignment__c == true 
                ) {
                    if (Trigger.new[i].Reject_From__c != 'DocEx') {
                        System.debug('********* Inside the DocEx-submission condition *********');
                        CO_Approval.submitContractFuture(Trigger.new[i].id,'Contract submitted by Sales');
                    } else {
                        System.debug('********* Inside the DocEx-re-submission condition *********');
                        CO_Approval.submitContractFuture(Trigger.new[i].id,'Contract submitted back from rejected step by System');
                    }
            }
            
            //Changes made by Venkatesh on 16th December 2015
            //CMS-1348
            if (
                Trigger.new[i].Approver__c == 'Pending' && 
                Trigger.new[i].Last_Approval_Step_Name__c == '2ndComm.Val.' && 
                Trigger.new[i].Pending_For_Approver_Reassignment__c == true 
                ) {
                    if (Trigger.new[i].Reject_From__c != '2CV') {
                        System.debug('********* Inside the 2nd Commercial Vlidation-submission condition *********');
                        CO_Approval.submitContractFuture(Trigger.new[i].id,'Contract submitted by Sales');
                    } else {
                        System.debug('********* Inside the 2nd Commercial Vlidation-re-submission condition *********');
                        CO_Approval.submitContractFuture(Trigger.new[i].id,'Contract submitted back from rejected step by System');
                    }
            }

            //CMS-1169
            //Changes made by Venkatesh on 19th August 2015
            if (
                Trigger.new[i].Approver__c == 'Pending' && 
                Trigger.new[i].Pending_For_Approver_Reassignment__c == true && 
                Trigger.new[i].Reject_From__c != null &&
                Trigger.new[i].Last_Approval_Step_Name__c != null &&
                ((Trigger.new[i].Last_Approval_Step_Name__c.contains('BCO') && (Trigger.new[i].Reject_From__c == 'BCO' || Trigger.new[i].Reject_From__c == 'Commision' || 
                    Trigger.new[i].Reject_From__c == 'BSC' || Trigger.new[i].Reject_From__c == 'SiteVal') ) ||     
                    (Trigger.new[i].Last_Approval_Step_Name__c == 'Order Desk' && Trigger.new[i].Reject_From__c == 'OrderDesk'))
                ) {
                System.debug('********* Inside the re-submission condition *********');
                CO_Approval.submitContractFuture(Trigger.new[i].id,'Contract submitted back from rejected step by System');
            } 
            */
            
        } //for

        //We must retrieve the coresponding reject
        List<Approval_Reject__c> rejectsToUpdate = new List<Approval_Reject__c>();
        for(ContractWO__c rejectTo : [SELECT Id, Name, Contract_Type__c, Approval_Reject__r.Id, Approval_Reject__r.Final_Reject__c, Approval_Reject__r.Name,
                                        Approval_Reject__r.Reject_To__c, last_approval_step__c, Approver__c, Product__c  
                                        FROM ContractWO__c where Id = :rejectedContractIdList])
        {
         system.debug('the reject to'+rejectTo.Approval_Reject__r.Reject_To__c);
            // Execute commands           
            if ((rejectTo.Approval_Reject__r.Reject_To__c != 'Sales')
            && (rejectTo.Approval_Reject__r.Reject_To__c != '')
            && (rejectTo.Approval_Reject__r.Reject_To__c != null)
            && (!rejectTo.Approval_Reject__r.Final_Reject__c)) {
                System.debug('rejectTo:' + rejectTo.last_Approval_Step__c);
                // create the new approval request to submit
                CO_Approval.submitContract(rejectTo.Id,'Auto ReSubmitted for approval to ' + rejectTo.Approval_Reject__r.Reject_To__c + '. Please approve.');
                
                // once resubmited we can reset the reject object
                Approval_Reject__c rejectToUpdate = rejectTo.Approval_Reject__r;
                rejectToUpdate.Reject_To__c = 'Sales';
                rejectsToUpdate.add(rejectToUpdate);
            }
        }
        if(!rejectsToUpdate.isEmpty())
        {
            update rejectsToUpdate;
        }
        
        if (lstCasesAPAC.size()>0) {
                INSERT lstCasesAPAC;         
        } 
        CO_EmailTemplate.sendSpecialMails(Trigger.new, Trigger.oldMap, Trigger.isInsert, Trigger.isUpdate, Trigger.isAfter);
        
        system.debug('After Update');
    }    
    }
    if(trigger.isBefore && trigger.isDelete){
    
        id adobeCoId = null;
        id webcastCoId = null;
        for(contractWo__c CO: Trigger.old){
        System.debug('inside for loop');
         if(CO.Contract_type__c == 'web' && CO.Product__c == 'Adobe Connect' && (CO.Pricing_Model__c == 'Named Host'|| CO.Pricing_Model__c == 'Concurrent Users'||CO.Pricing_Model__c == 'Shared Webinar Rooms'))
            {
                 adobeCoId = CO.id;   
             }
             if( CO.Contract_type__c == 'Ancillary/Event Services' && CO.Product_Ancillary__c== 'Digital Media Services' && 
                         (CO.SubProduct_Ancillary__c !='Webcast Pro MEC' ||  CO.SubProduct_Ancillary__c !='Webcast Pro MSC')){
                   webcastCoId   = CO.id;     
                         }  
        }
        if(adobeCoId != null){
        List<Adobe_Contract_Rate__c> adobeRecord = [select id from Adobe_Contract_Rate__c where contract_order__c =: adobeCoId ];
        
        system.debug('adobe List :'+adobeRecord);
        if(!adobeRecord.isEmpty()){
            Delete adobeRecord;
        system.debug('deleted adobe'+adobeRecord);
         }
    }
    if(webcastCoId != null){
        List<Webcast_Contract_Rates__c> webcastRecord = [select id from Webcast_Contract_Rates__c where contract_order__c =: webcastCoId ]; 
           if(!webcastRecord.isEmpty()){
                delete webcastRecord;  
          }
    }
 
   }
    if(trigger.isUpdate && trigger.isAfter){
        Map<id,contractWo__c>oldCon = trigger.oldMap;
        List<Opportunity>oppsToUpdate = new List<Opportunity>();
        for(contractWo__c c: trigger.new){
            if(c.Opportunity_Closed_Won__c != oldCon.get(c.id).Opportunity_Closed_Won__c && c.Opportunity_Closed_Won__c){
                oppsToUpdate = [select id,name,StageName,Opportunity_WinLost_Reason__c,Win_Loss_Competitor__c from opportunity where id =: c.Opportunity__c];
                    if(oppsToUpdate.size() > 0){
                         for(opportunity o: oppsToUpdate){
                            o.StageName = 'Closed Won';
                            o.Opportunity_WinLost_Reason__c = 'Price';
                            o.Win_Loss_Competitor__c = 'fsdfg';
                        }
                    }
               
                }
            }
        
        if(oppsToUpdate.size() > 0){
            update oppsToUpdate;
        }
    }
}