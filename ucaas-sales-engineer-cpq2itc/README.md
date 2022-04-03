# UcaaS - Sales Engineer - CPQ2ITC

# Process Description
**DISPATCHER:**
**more details needed**
1. Connect to Salesforce
2. Get quotes (Get Data SOQL)
3. For each quote:
      3.1  Get Contact details (Get Data SOQL)  
      3.2  Initialize Quote  
      3.3  Get Quote Line (Get Data SOQL)  
      3.4  For each line assign Service data (as dictionary)  
      3.5  For each line assign Location data (as dictionary)  
      3.6  Add Queue Item

**PERFORMER:**
**more details needed**
1. Data validation
2. Log in to ITC
3. Add New Quote
      3.1  Initialize Quote  
      3.2  Add Contacts
4. Add all Locations
5. For each Service:
      5.1  If Service Type = Service: Add Service  
      5.2  If Service Type = Equipment: Add Equipment  
      5.3  If Service Type = Circuit: Add Circuit  
6. Update Salesforce with new company and location Id


# Solution Design
**CPQ2ITC_Dispatcher**
**more details needed - arguments**
- CreateITCData


**CPQ2ITC_Performer**
**more details needed - arguments**
- ITC_Login
- AddQuote
- AddLocation
- AddService
- AddEquipment
- AddCircuit



# Business Instruction

**Process triggers**  
**more details needed**
... 
*Dispatcher* process which is scheduled in regular intervals will populate the queue.  
As soon as the queue is populated *Performer* process will be triggered on one/many machines in order to complete each task.  

Input file format:  
N/A

**Notification messages**  
Dispatcher robot will send a completion message after each failed/successful queue population.  
Status of all requested tasks can be checked/extracted from the queue.

**Common Business Exceptions**  
Cases returned with Business Exception are out of scope of the project and should be handed manually. Here are some more common examples:



**Used Assets**
- *ITCLoginCredential* - Smoothstone ITC credentials
- *UcaaS_CE_ITCUrl* - Smoothstone ITC url
- *Connection_SalesforceConsumerIducaas* - Consumer Key and Consumer Secret for Salesforce connection
- *Connection_SalesforceAPICredentialsIducaas* - User Name and Password for Salesforce connection
- *CPQ2ITC_NotificationReceiver* - Receivers for which notification will be send in case of a termination, new report or successful population.

**Additional information**  



## DATA VALIDATION
***to be confirmed***  
Fields that must not be empty in queue item (from SF):  
1. InitializeQuote:
"OpportunityID", "OpportunityName", "ContractCurrency", "ContractCountry", "ContractTermInMonths", "CompanyName", "SolutionType", "TechnicalContactName", "TechnicalContactPhone", "TechnicalContactEmail"
2. Locations:
"LocationId", "ItcLocationName", "StreetName", "City", "State", "ZipCode", "LocationDID"
3. Services:
"ItcServiceName", "ServiceType", "ServiceCategory", "Quantity", "Rate"

## ACCESSES
**Salesforce:**  
consumerKey:
3MVG9TYG6AjyhS_LYV1oaWw3AtVi8nMlqgZTIgEtaZBAlXXohYeD_hJI2Z.kkp5TbJEnbCM82wAsl7KrvlH9t  
consumerSecret:
957A756C902173A7F7A5DF4CA05AC9E20AC0F7E80334A8028808F729C5E24D8D  
userName:
automationbot@west.com.iducaas  
pwd:
169triMON$  

**ITC**  
Dev
Username: automationbot@west.com
Password: Changeme$1

Production
Username: automationbot@west.com
Password: Changeme1!

**ITC DB:**  
jdbc:mysql://itcdb-dev.lab.smst.local:3306/sap_dev  
salesforcedev
hKH4bAAmJzDM8wq2