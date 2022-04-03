/**
 * Created by SWE. Fernando Caldera on 5/13/2021.
 */

/**
 * @author SWE. Fernando Caldera
 * @description This class may serve as an all-sobject test data factory. It contains several
 * methods for test data creation, either specifying the data or getting a default-filled instance.
 */
@IsTest
public with sharing class TestDataFactory {
    private TestDataFactory() {
    }

    //TODO: Investigate opportunityAccessForAccountOwner field further.
    /**
     * @param name Name of the role
     * @param opportunityAccessForAccountOwner Missing info.
     * @param doSave Whether to save it or not.
     *
     * @return The created UserRole.
     */
    public static UserRole getUserRole(String name, String opportunityAccessForAccountOwner, Boolean doSave) {
        UserRole userRole = new UserRole(Name = name, OpportunityAccessForAccountOwner = opportunityAccessForAccountOwner);
        if (doSave) {
            insert userRole;
        }
        return userRole;
    }

    /**
     * @param doSave Whether to save it or not.
     *
     * @return A default-filled UserRole.
     */
    public static UserRole getUserRole(Boolean doSave) {
        return getUserRole('Test', 'Edit', doSave);
    }

    /**
     * @return The System Administrator UserRole.
     */
    public static UserRole getSystemAdministratorUserRole() {
        UserRole userRole = [SELECT Id, Name FROM UserRole WHERE Name = 'System Administrator'];
        return userRole;
    }

    /**
     * @return A random profile from salesforce.
     */
    public static Profile getProfile() {
        Profile profile = [SELECT Id FROM Profile LIMIT 1][0];
        return profile;
    }

    /**
     * @param doSave Whether to save it or not.
     *
     * @return A default-filled user.
     */
    public static User getUser(Boolean doSave) {
        return getUser('Test', 'Test', 'Test',
                'Test' + System.currentTimeMillis() + '@west.com.test',
                'Test' + System.currentTimeMillis() + '@west.com.test',
                getProfile(),
                'en_US',
                'en_US',
                'America/Chicago',
                'UTF-8',
                getSystemAdministratorUserRole(),
                getPMRequestPermissionSets(),
                doSave
        );
    }

    /**
     * @param firstName User's firstname.
     * @param lastName User's lastname.
     * @param alias User's alias.
     * @param username User's username with an email-like format. Eg: test@west.com.abcdefg
     * @param email User's email.
     * @param profile The profile for the assigned profile.
     * @param localeSidKey The locale Sid Key.
     * @param languageLocaleKey The language locale Key.
     * @param timeZoneSidKey The timezone Sid Key.
     * @param emailEncodingKey The email encoding key.
     * @param userRole The UserRole for the assigned UserRole.
     * @param permissionSets The permission sets.
     * @param doSave Whether to save it or not.
     *
     * @return The created User.
     */
    public static User getUser(String firstName, String lastName, String alias, String username,
            String email, Profile profile, String localeSidKey,
            String languageLocaleKey, String timeZoneSidKey,
            String emailEncodingKey, UserRole userRole,
            List<PermissionSet> permissionSets,
            Boolean doSave) {
        User user = new User(FirstName = firstName, LastName = lastName,
                Alias = alias, Username = username,
                Email = email, ProfileId = profile.Id, LocaleSidKey = localeSidKey,
                LanguageLocaleKey = languageLocaleKey, TimeZoneSidKey = timeZoneSidKey,
                EmailEncodingKey = emailEncodingKey, UserRoleId = userRole.Id,
                Profile = profile, UserRole = userRole,
                IsActive = true
        );
        if (doSave) {
            insert user;
            if (permissionSets != null) {
                List<PermissionSetAssignment> permissionSetAssignments = new List<PermissionSetAssignment>();
                for (PermissionSet permissionSet : permissionSets) {
                    PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment(
                            PermissionSetId = permissionSet.Id,
                            AssigneeId = user.Id
                    );
                    permissionSetAssignments.add(permissionSetAssignment);
                }
                insert permissionSetAssignments;
            }
        }
        return user;
    }

    /**
     * @param doSave Whether to save it or not.
     *
     * @return A default-filled Approval_Reject__c.
     */
    public static Approval_Reject__c getApprovalReject(Boolean doSave) {
        Approval_Reject__c approvalReject = new Approval_Reject__c();
        if (doSave) {
            insert approvalReject;
        }
        return approvalReject;
    }

    /**
     * @param customer The Id of an Account.
     * @param owner The user that owns this order.
     * @param doSave Whether to save it or not.
     *
     * @return The created Order_Header__c.
     */
    public static Order_Header__c getOrderHeader(Account customer, User owner, Boolean doSave) {
        Order_Header__c orderHeader = new Order_Header__c(
                Customer__r = customer,
                Customer__c = customer.Id,
                Owner__r = owner,
                Owner__c = owner.Id
        );
        if (doSave) {
            insert orderHeader;
        }
        return orderHeader;
    }

    /**
     * @param doSave Whether to save it or not.
     *
     * @return A default-filled Order_Header__c.
     */
    public static Order_Header__c getOrderHeader(Boolean doSave) {
        return getOrderHeader(getAccount(true), [SELECT Id, IsActive FROM User WHERE Alias = 'Test' LIMIT 1][0], doSave);
    }

    /**
     * @param name Name of the account.
     * @param doSave Whether to save it or not.
     *
     * @return A GUPA type account.
     */
    public static Account getAccount(String name, Boolean doSave) {
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Global Ultimate Parent Account').getRecordTypeId();
        Account account = new Account(Name = name, RecordTypeId = recordTypeId);
        if (doSave) {
            insert account;
        }
        return account;
    }

    /**
     * @param name Name of the account.
     * @param parent The parent account.
     * @param countryField The account's country.
     * @param customerRegion The customer's region.
     * @param doSave Whether to save it or not.
     *
     * @return The created account.
     */
    public static Account getAccount(String name, Account parent, String countryField,
            String customerRegion,
            Boolean doSave) {
        Account account = new Account(Name = name, Parent = parent, ParentId = parent.Id,
                Country_Field__c = countryField,
                Customer_Region__c = customerRegion
                );
        if (doSave) {
            insert account;
        }
        return account;
    }

    /**
     * @param doSave Whether to save it or not.
     *
     * @return A default-filled account.
     */
    public static Account getAccount(Boolean doSave) {

        return getAccount('Test', getAccount('Test', true), 'United States of America', 'AMERS', doSave);
    }

    /**
     * @param doSave Whether to save it or not.
     *
     * @return A default-filled ContractWO__c.
     */
    public static ContractWO__c getContractWO(Boolean doSave) {
        return getContractWO(getApprovalReject(true), getOrderHeader(true), 'Audio', 'Audio', getOpportunity(true), getAccount(true), 'APAC', doSave);
    }

    //TODO: Investigate approval_reject field further.
    /**
     * @param approval_Reject Missing info.
     * @param order_Header The Header of the order.
     * @param contract_type The contract type.
     * @param product The web product.
     * @param opportunity The opportunity related to this contract.
     * @param company_number The account for the contract.
     * @param region The region.
     * @param doSave Whether to save it or not.
     *
     * @return The created ContractWO__c.
     */
    public static ContractWO__c getContractWO(Approval_Reject__c approval_Reject, Order_Header__c order_Header, String contract_type, String product, Opportunity opportunity,
            Account company_number, String region, Boolean doSave) {
        ContractWO__c contractWO = new ContractWO__c(
                Approval_Reject__c = approval_Reject.Id,
                Order_Header__c = order_Header.Id,
                Approval_Reject__r = approval_Reject,
                Order_Header__r = order_Header,
                Contract_Type__c = contract_type,
                Product__c = product,
                Opportunity__r = opportunity,
                Opportunity__c = opportunity.Id,
                Company_Number__c = company_number.Id,
                Company_Number__r = company_number,
                Region__c = region
        );
        if (doSave) {
            insert contractWO;
        }
        return contractWO;
    }

    public static Opportunity getOpportunity(Boolean doSave) {
        return getOpportunity('Test', 'Closed Won', Date.today(), doSave);
    }

    /**
     * @param name The name of the opportunity.
     * @param stageName The name of the stage.
     * @param closeDate The close date.
     * @param doSave Whether to save it or not.
     * @return The created Opportunity.
     */
    public static Opportunity getOpportunity(String name, String stageName, Date closeDate, Boolean doSave) {
        Opportunity opportunity = new Opportunity(
                Name = name,
                StageName = stageName,
                CloseDate = closeDate
        );
        if (doSave) {
            insert opportunity;
        }
        return opportunity;
    }

    /**
     * @param doSave Whether to save it or not.
     *
     * @return A default-filled contact.
     */
    public static Contact getContact(Boolean doSave) {
        return getContact('Test', doSave);
    }

    /**
     * @param lastname The contact's lastname.
     * @param doSave Whether to save it or not.
     *
     * @return The created Contact.
     */
    public static Contact getContact(String lastname, Boolean doSave) {
        Contact contact = new Contact(
                LastName = lastname
        );
        if (doSave) {
            insert contact;
        }
        return contact;
    }

    public static Apttus__APTS_Agreement__c getApttusAPTSAgreement(Boolean doSave) {
        return getApttusAPTSAgreement(getOpportunity(true), 'APAC', getAccount(true), doSave);
    }

    /**
     * @param opportunity The opportunity Object.
     * @param aptsRegion The apts Region.
     * @param account The Account object.
     * @param doSave Whether to save it or not.
     *
     * @return The created agreement.
     */
    public static Apttus__APTS_Agreement__c getApttusAPTSAgreement(Opportunity opportunity, String aptsRegion, Account account, Boolean doSave) {
        Apttus__APTS_Agreement__c aptsAgreement = new Apttus__APTS_Agreement__c(
                Apttus__Related_Opportunity__r = opportunity,
                Apttus__Related_Opportunity__c = opportunity.Id,
                APTS_Region__c = aptsRegion,
                Apttus__Account__r = account,
                Apttus__Account__c = account.Id
        );
        if (doSave) {
            insert aptsAgreement;
        }
        return aptsAgreement;
    }

    /**
     * @return The List of PermissionSet for the PM Request.
     */
    public static List<PermissionSet> getPMRequestPermissionSets() {
        return [SELECT Id, Name FROM PermissionSet WHERE Name IN ('PM_Request', 'Intercall_Implementation_PMs')];
    }

}