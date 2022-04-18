public class ITCQuoteExtension {
    
    //String[] locations = new String[]{};
    String accountName;
    String accountId;

    public String itcQuoteName{get; set;}
    public String itcTerm{get; set;}
    public String itcQuoteCurrency{get; set;}
    public String itcQuoteType{get; set;}
    public String itcLocation{get; set;}
    
    
    //If multiselect is false, locations must be of type String
    public String locations{get; set;}

    public String solutionTypes {get; set;}

    public Case myCase{get; set;}

    private ApexPages.StandardController sctrl;

    public string services{get; set;}
    public Date serviceEffDate {get; set;}
    public Date circuitEffDate {get; set;}
    public Date equipmentEffDate {get; set;}

    public string rPAStatus {get; set;}

    public ITCQuoteExtension(ApexPages.StandardController stdController) 
    {    
        this.sctrl = stdController;
        this.myCase= (Case)stdController.getRecord();
        init();
    }
    
    public void init()
    {
        Case c=[select id, Company_Name__c, AccountId  from case where Id=:myCase.Id];
        this.accountName = c.Company_Name__c;
        this.accountId = c.AccountId;
        itcQuoteType = 'Cancellation';
        itcTerm = '12';

        Account a=[select id, name, CurrencyIsoCode  from Account where id=:c.AccountId];
        itcQuoteCurrency =  a.CurrencyIsoCode;

    }
    

    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>();
        
        string selectedOpt = '';
        //rightvalues.clear();

        for (Location__c a : [select id, name, Account__c, Address_2__c, Street_Number__c, Street_Name__c, City__c, State__c, Country__c from Location__c where Account__c=:accountId and Address_2__c <> '' order by Address_2__c ]  ) 
        {
            if ( a != null)
            {
                options.add(new SelectOption(a.id, a.Street_Number__c + ' ' + a.Street_Name__c + ' ' + a.City__c + ' ' + a.State__c + ' ' + a.Country__c));
            }
        }
        
        return options;
    }
    
    public void setLocations(String locations) {
        this.locations = locations;
    }
    
    public void setsolutionTypes(String solutionTypes){
        this.solutionTypes = solutionTypes;
    }

    public String getCompanyName(){
        return accountName;
    }
    public String getLocations() {
        return locations;
    }

    public String getCaseId(){
        return myCase.id;
    }

    public List<SelectOption> getsolutionType(){
        List<SelectOption> opt = new List<SelectOption>();
        schema.DescribeFieldResult fd = ITC_Cancel_Quote__c.Solution_Type__c.getdescribe();
        List<Schema.PicklistEntry>  pc = fd.getpicklistvalues();
        for(schema.picklistentry f: pc){
        
            opt.add(new selectoption(f.getlabel(),f.getvalue()));
        }
        return opt;
    }

    public List<SelectOption> getRPAStatuses(){
        List<SelectOption> opt = new List<SelectOption>();
        schema.DescribeFieldResult fd = ITC_Cancel_Quote__c.RPA_Status__c.getdescribe();
        List<Schema.PicklistEntry>  pc = fd.getpicklistvalues();
        for(schema.picklistentry f: pc){
        
            opt.add(new selectoption(f.getlabel(),f.getvalue()));
        }
        return opt;
    }

    // equipments
    /*
    public List<SelectOption> getequipment(){
        List<SelectOption> opt = new List<SelectOption>();

        String sLocationId = '';

        return opt;
        
    }
    */

    public List<string> getequipmentaslist(){
        List<string> opt = new List<string>();
        
        String sLocationId = '';

        if (!String.isNotEmpty(this.locations)){
            opt.add('None');
            return opt;
            //return null;
        }
        else{
            //opt.add('All');

            Location__c[] l=[select id, name, ITC_Location_ID__c from Location__C where id=:locations];
            if (l.size() > 0){
                sLocationId = l[0].ITC_Location_ID__c;
            }

            //opt.add(sLocationId);
            //ITC_Equipment__c[] itcEquipment = [SELECT Name, ITC_Id__c,ITC_mid__c,ITC_cid__c,ITC_lid__c FROM ITC_Equipment__c where ITC_lid__c=:sLocationId];
            ITC_Equipment__c[] itcEquipment = [SELECT Name, ITC_Id__c,ITC_mid__c,ITC_cid__c,ITC_lid__c FROM ITC_Equipment__c where ITC_lid__c=:sLocationId + '.000000000000000'];
            if (itcEquipment.size() > 0){
                for (ITC_Equipment__c e : itcEquipment){
                    string itcId = e.ITC_mid__c.remove('.000000000000000');

                    //opt.add(itcId);
                    Product2[] p = [select id, Name, CPQ_Product__c, ITC_Display_On_Quote__c from Product2 where CPQ_Product__c = false and ITC_Id__c=:itcId];
                    if ( p.size() > 0 ){
                        //opt.add(p[0].Name);
                        
                        boolean add = true;
                        boolean addAllItem = true;

                        for(string str : rightvaluesE){
                            if(str ==  p[0].Name){
                                add = false;
                            }
                            if(str == 'All'){
                                addAllItem = false;
                            }
                        }
                        if(add) {
                            opt.add(p[0].Name);
                        }
                        if(addAllItem){
                            opt.add('All');
                        }
                    }
                }
            }
        }
        return opt;
    }

    public List<string> getcircuitaslist(){
        List<string> opt = new List<string>();
        
        String sLocationId = '';

        if (!String.isNotEmpty(this.locations)){
            opt.add('None');
            return opt;
            //return null;
        }
        else {
            //opt.add('All');

            Location__c[] l=[select id, name, ITC_Location_ID__c from Location__C where id=:locations];
            if (l.size() > 0){
                sLocationId = l[0].ITC_Location_ID__c;
            }
            
            ITC_Circuit__c[] itcCircuit = [SELECT Name,ITC_Id__c,ITC_Circuit_Location_Id__c,Inactive__c FROM ITC_Circuit__c where ITC_Circuit_Location_Id__c=:sLocationId];
            if (itcCircuit.size() > 0){
                for (ITC_Circuit__c c : itcCircuit){
                    
                    boolean add = true;
                    boolean addAllItem = true;

                    for(string str : rightvaluesC){
                        if(str ==  c.Name){
                            add = false;
                        }
                        if(str == 'All'){
                            addAllItem = false;
                        }
                    }
                    if(add) {
                        opt.add(c.Name);
                    }
                    if(addAllItem){
                        opt.add('All');
                    }
                }
            }
        }
        return opt;
    }

    public List<string> getserviceaslist(){
        List<string> opt = new List<string>();
        
        String sLocationId = '';
        String sBillingId = '';
        
        if (!String.isNotEmpty(this.locations)){
            opt.add('None');
            return opt;
            //return null;
        }
        else {
            //
            // get loc id
            // select id, name, ITC_Location_ID__c from Location__C where Name = 'LOC-00005178'
            Location__c[] l=[select id, name, ITC_Location_ID__c from Location__C where id=:locations];
            if (l.size() > 0){
                sLocationId = l[0].ITC_Location_ID__c;
            }

            // get billing id
            // SELECT id, name, Location_ID__c, ITC_Billing_ID__c FROM ITC_Billing__c where Location_ID__c = '140074'
            ITC_Billing__c[] itcBilling = [SELECT id, name, Location_ID__c, ITC_Billing_ID__c FROM ITC_Billing__c where Location_ID__c=:sLocationId];
            if (itcBilling.size() > 0){
                sBillingId = itcBilling[0].ITC_Billing_ID__c;
            }

            // get billing services IDs
            // SELECT id, name, ITC_Billing_Services_ID__c, ITC_Billing_ID__c, ITC_Service_ID__c FROM ITC_Billing_Service__c where ITC_Billing_ID__c = '97978'
            ITC_Billing_Service__c[] sBillingServicesIds = [SELECT id, name, ITC_Billing_Services_ID__c, ITC_Billing_ID__c, ITC_Service_ID__c FROM ITC_Billing_Service__c where ITC_Billing_ID__c=:sBillingId];
            if (sBillingServicesIds.size() > 0){
                for (ITC_Billing_Service__c ibc : sBillingServicesIds){
                    Product2[] p = [select id, Name, CPQ_Product__c, ITC_Display_On_Quote__c from Product2 where CPQ_Product__c = false and ITC_Id__c=:ibc.ITC_Service_ID__c];
                    if ( p.size() > 0 )
                    {

                        boolean add = true;
                        boolean addAllItem = true;

                        for(string str : rightvalues){
                            if(str ==  p[0].Name){
                                add = false;
                            }
                            if(str == 'All'){
                                addAllItem = false;
                            }
                        }
                        if(add) {
                            opt.add(p[0].Name);
                        }
                        if(addAllItem){
                            opt.add('All');
                        }
                    }   
                }
            }
            return opt;
        }
    }
    // services
    public List<SelectOption> getservice(){
        List<SelectOption> opt = new List<SelectOption>();
        
        String sLocationId = '';
        String sBillingId = '';
        
        if (!String.isNotEmpty(this.locations)){
            opt.add(new SelectOption('None', 'None'));
            return opt;
            //return null;
        }
        else {
            opt.add(new SelectOption('All', 'All'));
            // get loc id
            // select id, name, ITC_Location_ID__c from Location__C where Name = 'LOC-00005178'
            Location__c[] l=[select id, name, ITC_Location_ID__c from Location__C where id=:locations];
            if (l.size() > 0){
                sLocationId = l[0].ITC_Location_ID__c;
            }

            // get billing id
            // SELECT id, name, Location_ID__c, ITC_Billing_ID__c FROM ITC_Billing__c where Location_ID__c = '140074'
            ITC_Billing__c[] itcBilling = [SELECT id, name, Location_ID__c, ITC_Billing_ID__c FROM ITC_Billing__c where Location_ID__c=:sLocationId];
            if (itcBilling.size() > 0){
                sBillingId = itcBilling[0].ITC_Billing_ID__c;
            }

            // get billing services IDs
            // SELECT id, name, ITC_Billing_Services_ID__c, ITC_Billing_ID__c, ITC_Service_ID__c FROM ITC_Billing_Service__c where ITC_Billing_ID__c = '97978'
            ITC_Billing_Service__c[] sBillingServicesIds = [SELECT id, name, ITC_Billing_Services_ID__c, ITC_Billing_ID__c, ITC_Service_ID__c FROM ITC_Billing_Service__c where ITC_Billing_ID__c=:sBillingId];
            if (sBillingServicesIds.size() > 0){
                for (ITC_Billing_Service__c ibc : sBillingServicesIds){
                    Product2[] p = [select id, Name, CPQ_Product__c, ITC_Display_On_Quote__c from Product2 where CPQ_Product__c = false and ITC_Id__c=:ibc.ITC_Service_ID__c];
                    if ( p.size() > 0 )
                    {
                        opt.add(new SelectOption(p[0].Name, p[0].Name));   
                    }   
                }
            }
         
            
            return opt;
        }
    }
    
    public PageReference refreshPage(){
        PageReference cancel;
        this.locations = locations;
        return cancel;
    }
    public String getservices(){
        return this.services;
    }
    public void setservices(string services){
        this.services = services;
    }

    public PageReference submitQuote() {
        ITC_Cancel_Quote__c newQuote = new ITC_Cancel_Quote__c ();
        newQuote.Name = this.itcQuoteName;
        newQuote.Case__c = myCase.id;

        Location__c[] loc=[select id, name from Location__c where id=:this.locations];
        if (loc.size() > 0){
            newQuote.Location__c = loc[0].id;
        }
        newQuote.CurrencyIsoCode = this.itcQuoteCurrency;
        newQuote.Quote_Type__c = this.itcQuoteType;
        newQuote.Term__c = decimal.valueOf(this.itcTerm);
        newQuote.Solution_Type__c = this.solutionTypes;

        // set services
        string optionvalues = RightValues.toString();
        optionvalues = optionvalues.replace('[','').replace(']','').replace(',', ';').replace('{','').replace('}','');
        newQuote.Service__c = optionvalues;

        newQuote.Service_Effectivity_Date__c = this.ServiceEffDate;

        // set circuits
        optionvalues = RightValuesC.toString();
        optionvalues = optionvalues.replace('[','').replace(']','').replace(',', ';').replace('{','').replace('}','');
        newQuote.Circuits__c = optionvalues;

        newQuote.Circuit_Effectivity_Date__c = this.circuitEffDate;

        //set equipments
        optionvalues = RightValuesE.toString();
        optionvalues = optionvalues.replace('[','').replace(']','').replace(',', ';').replace('{','').replace('}','');
        newQuote.Equipments__c = optionvalues;

        newQuote.Equipment_Effectivity_Date__c = this.equipmentEffDate;

        newQuote.RPA_Status__c = RPAStatus;

        insert newQuote;

        //PageReference ref = sctrl.save();
        PageReference ref;

        return ref;
        
    }
  
    public string getrightArrow(){
        String rightArrow = '<div style="font-size: 25px;">&#129094;</div>';
        return rightArrow;
    }
    public string getleftArrow(){
        String leftArrow = '<div style="font-size: 25px;">&#129092;</div>';
        return leftArrow;
    }

    // start multi select
    Public List<string> leftselected{get;set;}
    Public List<string> rightselected{get;set;}
    Set<string> leftvalues = new Set<string>();
    Set<string> rightvalues = new Set<string>();

    //circuits
    Public List<string> leftselectedC{get;set;}
    Public List<string> rightselectedC{get;set;}
    Set<string> leftvaluesC = new Set<string>();
    Set<string> rightvaluesC = new Set<string>();

    //equipments
    Public List<string> leftselectedE{get;set;}
    Public List<string> rightselectedE{get;set;}
    Set<string> leftvaluesE = new Set<string>();
    Set<string> rightvaluesE = new Set<string>();

    public void multiselect(string listType){
        List<String> originalvalues;

        string loc = '';
        if (String.isNotEmpty(this.locations)){
            loc = this.locations;
            
        }
        
        if(listType == 'Service'){
            leftvalues.clear();
            originalvalues = getserviceaslist();
            leftselected = new List<String>();
            rightselected = new List<String>();
            leftvalues.addAll(originalValues);
            
            
        }  
        if(listType == 'Circuit'){
            leftvaluesC.clear();
            originalvalues = getcircuitaslist();
            leftselectedC = new List<String>();
            rightselectedC = new List<String>();
            leftvaluesC.addAll(originalValues);
            
        }

        if(listType == 'Equipment'){
            leftvaluesE.clear();
            originalvalues = getequipmentaslist();
            leftselectedE = new List<String>();
            rightselectedE = new List<String>();
            leftvaluesE.addAll(originalValues);
            
        }

    }
    
    

    // service
    public List<SelectOption> getunSelectedValues(){
        multiselect('service');
        
        List<SelectOption> options = new List<SelectOption>();
        List<string> tempList = new List<String>();
        tempList.addAll(leftvalues);
        tempList.sort();

        
        for(string s : tempList){
            options.add(new SelectOption(s,s));
        }   
        return options;
    }

    public List<SelectOption> getSelectedValues(){
        List<SelectOption> options1 = new List<SelectOption>();
        List<string> tempList = new List<String>();
        tempList.addAll(rightvalues);
        tempList.sort();
        for(String s : tempList) {
            options1.add(new SelectOption(s,s));
        }
        return options1;
    }

    public PageReference selectclick(){
        rightselected.clear();
        for(String s : leftselected){
            leftvalues.remove(s);
            rightvalues.add(s);
        }
        return null;
    }
     
    public PageReference unselectclick(){
        leftselected.clear();
        for(String s : rightselected){
            rightvalues.remove(s);
            leftvalues.add(s);
        }
        return null;
    }

    //circuits
    public List<SelectOption> getunSelectedValuesC(){
        multiselect('Circuit');
        
        List<SelectOption> options = new List<SelectOption>();
        List<string> tempList = new List<String>();
        tempList.addAll(leftvaluesC);
        tempList.sort();

        for(string s : tempList){
            options.add(new SelectOption(s,s));
        }   
        return options;
    }
    
    public List<SelectOption> getSelectedValuesC(){
        List<SelectOption> options1 = new List<SelectOption>();
        List<string> tempList = new List<String>();
        tempList.addAll(rightvaluesC);
        tempList.sort();
        for(String s : tempList) {
            options1.add(new SelectOption(s,s));
        }
        return options1;
    }

    public PageReference selectclickC(){
        rightselectedC.clear();
        for(String s : leftselectedC){
            leftvaluesC.remove(s);
            rightvaluesC.add(s);
        }
        return null;
    }
     
    public PageReference unselectclickC(){
        leftselectedC.clear();
        for(String s : rightselectedC){
            rightvaluesC.remove(s);
            leftvaluesC.add(s);
        }
        return null;
    }
    
    //equipments
    public List<SelectOption> getunSelectedValuesE(){
        multiselect('Equipment');
        
        List<SelectOption> options = new List<SelectOption>();
        List<string> tempList = new List<String>();
        tempList.addAll(leftvaluesE);
        tempList.sort();

        for(string s : tempList){
            options.add(new SelectOption(s,s));
        }   
        return options;
    }
    
    public List<SelectOption> getSelectedValuesE(){
        List<SelectOption> options1 = new List<SelectOption>();
        List<string> tempList = new List<String>();
        tempList.addAll(rightvaluesE);
        tempList.sort();
        for(String s : tempList) {
            options1.add(new SelectOption(s,s));
        }
        return options1;
    }

    public PageReference selectclickE(){
        rightselectedE.clear();
        for(String s : leftselectedE){
            leftvaluesE.remove(s);
            rightvaluesE.add(s);
        }
        return null;
    }
     
    public PageReference unselectclickE(){
        leftselectedE.clear();
        for(String s : rightselectedE){
            rightvaluesE.remove(s);
            leftvaluesE.add(s);
        }
        return null;
    }


    public set<string> getRightValues(){
        return rightvalues;
    }
    public set<string> getRightValuesC(){
        return rightvaluesC;
    }
    public set<string> getRightValuesE(){
        return rightvaluesE;
    }
}

