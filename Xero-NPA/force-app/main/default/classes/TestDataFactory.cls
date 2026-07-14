/*
 * Author:       Alfonso Maquilan
 * Created Date: May 10, 2021
 * Description:  Test Data Factory for Apex Test Classes
 * Test Class:   N/A
 * History: 	 May 10, 2021 - Creation
*/
public class TestDataFactory 
{
	public class PricebookEntryParameters
    {
        public String PricebookId; 
        public String ProductId;
        public Decimal UnitPrice;
    }
    
    public class OpportunityLineItemParameters
    {
        public String OppId;
        public String PbeId;
        public Decimal Quantity;
        public Decimal PbeUnitPrice;
    }
    
    public static List<Account> CreateAccount(Integer qty , Boolean isInsert)
    {
        List<Account> accountList = new List<Account>();
        
        for(Integer ctr = 0; ctr < qty; ctr++)
        {
            Account accountRecord = new Account();
            accountRecord.Name = 'testAccount' + ctr;
            
            accountList.add(accountRecord);
        }
        
        if(isInsert) 
            Insert accountList;
        return accountList;
    }
    
    public static List<Account> CreateAccounts(Integer quantity , Boolean isInsert)
    {
        List<Account> accountsToInsert = new List<Account>();
        
        for(Integer ctr = 0; ctr < quantity; ctr++)
        {
            Account newAccount = new Account();
            newAccount.Name = 'testAccount' + ctr;
            newAccount.Phone = '22222';
            newAccount.Fax = '33333';
            newAccount.ShippingStreet = 'testStreet' + ctr;
            newAccount.ShippingCity = 'testCity' + ctr;
            newAccount.ShippingState = 'testState' + ctr;
            newAccount.ShippingPostalCode = 'testPostalCode' + ctr;
            newAccount.ShippingCountry = 'testCountry' + ctr;
            newAccount.XeroId__c = '11111' + String.valueOf(ctr);
            accountsToInsert.add(newAccount);
        }
        
        if(!accountsToInsert.isEmpty() && isInsert) Insert accountsToInsert;
        
        return accountsToInsert;
    }
    
    public static List<Contact> createContacts(List<Account> acctList, Boolean isInsert)
    {
        List<Contact> conList = new List<Contact>();
        Integer ctr = 0;
        for(Account acc :  acctList)
        {
            Contact con = new Contact();
            con.FirstName = 'Fname '+ctr;
            con.LastName = 'LName '+ctr;
            con.AccountId = acc.Id;
            con.Email = 'sample'+ctr+'@email.com';
            con.MobilePhone = '1234567890';
            conList.add(con);
            ctr++;
        }
        if(isInsert)
            insert conList;
        return conList;
    }


    public static List<Contact> CreateContacts(Integer quantity , String acctId, Boolean isInsert)
    {
        List<Contact> contactsToInsert = new List<Contact>();
        
        for(Integer ctr = 0; ctr < quantity; ctr++)
        {
            Contact newContact = new Contact();
            newContact.FirstName = 'testFirstName';
            newContact.LastName = 'testLastName' + ctr;
            newContact.AccountId = acctId;   
            newContact.OwnerId = UserInfo.getUserId();
            system.debug('newContact.OwnerId :: ' + newContact.OwnerId);
            contactsToInsert.add(newContact);
        }
        
        if(!contactsToInsert.isEmpty() && isInsert) Insert contactsToInsert;
        
        return contactsToInsert;
    }
    
    public static List<Opportunity> CreateOpportunities(Integer quantity , String acctId , String conId , Boolean isInsert)
    {
        List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
        
        for(Integer ctr = 0; ctr < quantity; ctr++)
        {
            Opportunity newOpportunity = new Opportunity();
            newOpportunity.Name = 'testOpportunity' + ctr;
            newOpportunity.StageName = CONSTANTS_BRIC.OPPORTUNITY_STAGE_PROSPECTING;
            newOpportunity.CloseDate = System.today();
            newOpportunity.AccountId = acctId;
            newOpportunity.ContactId = conId;
            opportunitiesToInsert.add(newOpportunity);
        }
        
        if(!opportunitiesToInsert.isEmpty() && isInsert) Insert opportunitiesToInsert;
        
        return opportunitiesToInsert;
    }
    
    public static List<Product2> CreateProducts(Integer quantity , Boolean isInsert)
    {
        List<Product2> productsToInsert = new List<Product2>();
        
        for(Integer ctr = 0; ctr < quantity; ctr++)
        {
            Product2 newProduct = new Product2();
            newProduct.Name = 'testProduct' + ctr;
            newProduct.ProductCode = 'testCode' + ctr;
            newProduct.isActive = TRUE;
            productsToInsert.add(newProduct);
        }
        
        if(!productsToInsert.isEmpty() && isInsert) Insert productsToInsert;
        
        return productsToInsert;
    }
    
    public static List<PricebookEntry> CreatePricebookEntries(Integer quantity , PricebookEntryParameters Params, Boolean isInsert)
    {
        List<PricebookEntry> pricebookEntriesToInsert = new List<PricebookEntry>();
        
        for(Integer ctr = 0; ctr < quantity; ctr++)
        {
            PricebookEntry newPricebookEntry = new PricebookEntry();
            newPricebookEntry.Pricebook2Id = Params.PricebookId;
            newPricebookEntry.Product2Id = Params.ProductId;
            newPricebookEntry.UnitPrice = Params.UnitPrice;
            newPricebookEntry.IsActive = TRUE;
            pricebookEntriesToInsert.add(newPricebookEntry);
        }
        
        if(!pricebookEntriesToInsert.isEmpty() && isInsert) Insert pricebookEntriesToInsert;
        
        return pricebookEntriesToInsert;
    }

    public static List<Opportunity> CreateOpportunity(Integer qty , String accountId , Boolean isInsert)
    {
        List<Opportunity> opportunityList = new List<Opportunity>();
        
        for(Integer ctr = 0; ctr < qty; ctr++)
        {
            Opportunity opportunityRec = new Opportunity();
            opportunityRec.Name = 'testOpportunity' + qty;
            opportunityRec.StageName = 'Qualification';
            opportunityRec.CloseDate = System.today().addDays(30);
            opportunityRec.AccountId = accountId;
            
            opportunityList.add(opportunityRec);
        }
        
        if(isInsert) 
            Insert opportunityList;
        return opportunityList;
    }
    
    public static List<OpportunityLineItem> CreateOpportunityLineItems(Integer quantity , OpportunityLineItemParameters params, Boolean isInsert)
    {
        List<OpportunityLineItem> opportunityLineItemsToInsert = new List<OpportunityLineItem>();
        
        for(Integer ctr = 0; ctr < quantity; ctr++)
        {
            OpportunityLineItem newOpportunityLineItem = new OpportunityLineItem();
            newOpportunityLineItem.OpportunityId = params.OppId;
            newOpportunityLineItem.PricebookEntryId = params.PbeId;
            newOpportunityLineItem.Quantity = params.Quantity;
            newOpportunityLineItem.TotalPrice = params.PbeUnitPrice;
            opportunityLineItemsToInsert.add(newOpportunityLineItem);
        }
        
        if(!opportunityLineItemsToInsert.isEmpty() && isInsert) Insert opportunityLineItemsToInsert;
        
        return opportunityLineItemsToInsert;
    }
/*
    public static List<ServiceResource> createServiceResources(Integer qty, String userId, Boolean isInsert)
    {
        List<ServiceResource> srList = new List<ServiceResource>();
        for(Integer x = 0; x < qty; x++)
        {
            ServiceResource sr = new ServiceResource();
            sr.Name = 'Resource '+x;
            sr.RelatedRecordId = userId;
            sr.isActive = true;
            //sr.ResourceType = 'Technician';
            srList.add(sr);
        }
        if(isInsert)
            insert srList;
        return srList;
    }


    public static List<WorkType> createWorkType(Integer qty, String operatingHoursId, Integer durationHours, Boolean isInsert)
    {
        List<WorkType> wtList = new List<WorkType>();
        for(Integer x = 0; x < qty; x++)
        {
            WorkType wt = new WorkType();
            wt.Name = 'Topic '+x;
            wt.DurationType = 'Hours';
            wt.EstimatedDuration = Decimal.valueOf(durationHours);
            wtList.add(wt);
        }
        if(isInsert)
            insert wtList;
        return wtList;
    }

    public static List<ServiceTerritory> createTerritories(Integer qty, String operatingHoursId, Boolean isInsert)
    {
        List<ServiceTerritory> stList = new List<ServiceTerritory>();
        for(Integer x = 0; x < qty; x++)
        {
            ServiceTerritory st = new ServiceTerritory();
            st.Name = 'Territory '+x;
            st.OperatingHoursId = operatingHoursId;
            st.isActive = true;
            stList.add(st);
        }
        if(isInsert)
            insert stList;
        return stList;
    }

    public static List<ServiceTerritoryMember> createTerritoryMembers(List<ServiceResource> srList, String territoryId, String operatingHoursId, Boolean isInsert)
    {
        List<ServiceTerritoryMember> stmList = new List<ServiceTerritoryMember>();
        for(ServiceResource sr : srList)
        {
            ServiceTerritoryMember stm = new ServiceTerritoryMember();
            stm.ServiceResourceId = sr.Id;
            stm.OperatingHoursId = operatingHoursId;
            stm.ServiceTerritoryId = territoryId;
            //stm.TerritoryType = 'Primary';
            stm.EffectiveStartDate = Datetime.newInstance(Date.today().year(), Date.today().month(), 1, 0, 0, 0);
            stmList.add(stm);
        }
        if(isInsert)
            insert stmList;
        return stmList;
    }

    public static List<OperatingHours> createOperatingHours(Integer qty, String strTimeZone, Boolean isInsert)
    {
        List<OperatingHours> ohList = new List<OperatingHours>();
        for(Integer x = 0; x < qty; x++)
        {
            OperatingHours oh = new OperatingHours();
            oh.Name = 'Operating Hours '+x;
            oh.TimeZone = strTimeZone;
            ohList.add(oh);
        }
        if(isInsert)
            insert ohList;
        return ohList;
    }

    public static List<TimeSlot> createTimeSlots(String operatingHoursId, Time startTime, Time endTime, Boolean isInsert)
    {
        List<TimeSlot> tsList = new List<TimeSlot>();
        Map<Integer, String> mapOfDays = new Map<Integer, String>{0 => 'Monday',
                                                                  1 => 'Tuesday',
                                                                  2 => 'Wednesday',
                                                                  3 => 'Thursday',
                                                                  4 => 'Friday'};

        for(Integer x = 0; x < 5; x++)
        {
            TimeSlot ts = new TimeSlot();
            ts.DayOfWeek = mapOfDays.get(x);
            ts.StartTime = startTime;
            ts.EndTime = endTime;
            ts.Type = 'Normal';
            ts.OperatingHoursId = operatingHoursId;
            tsList.add(ts);
        }
        if(isInsert)
            insert tsList;
        return tsList;
    }
    
    public static List<ServiceAppointment> createServiceAppointments(Integer qty, ServiceAppointmentValues sv, Boolean isInsert)
    {
        List<ServiceAppointment> saList = new List<ServiceAppointment>();
        for(Integer x = 0; x < qty; x++)
        {
            ServiceAppointment sa = new ServiceAppointment();
            sa.EarliestStartTime = System.now();
            sa.DueDate = System.now().addDays(7);
            sa.ParentRecordId = sv.oppId;
            sa.Status = 'None';
            sa.SchedStartTime = System.now().addDays(1);
            sa.SchedEndTime = System.now().addDays(7);
            //sa.WorkTypeId = sv.workTypeId;
         	sa.ContactId = sv.contactId;
            sa.ServiceTerritoryId = sv.territoryId;
            saList.add(sa);
        }
        if(isInsert)
            insert saList;
        return saList;
    }
    
    public static List<ContentVersion> createContentVersions(Integer qty, Boolean isInsert)
    {
        List<ContentVersion> cvList = new List<ContentVersion>();
        
        for(Integer x = 0; x < qty; x++)
        {
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Test Image '+x;
            cv.PathOnClient = 'TestImage'+x+'.jpg';
            cv.VersionData = Blob.valueOf('Test Content');
            cv.IsMajorVersion = true;
            cvList.add(cv);
        }
        if(isInsert)
            insert cvList;
        return cvList;
    }
    
	public static List<ContentDocumentLink> createContentDocumentLinks(Set<String> setOfCdIds, String saId, Boolean isInsert)
    { 
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
        for(String cdId : setOfCdIds)
        {
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = saId;
            cdl.ContentDocumentId = cdId;
            cdl.shareType = 'V';
			cdlList.add(cdl);
        }
        if(isInsert)
            insert cdlList;
        return cdlList;
    }
    
    public static List<Field_Images_Bric__c> createFieldImages(Set<String> setOfCdIds, String saId, Boolean isInsert)
    {
        List<Field_Images_Bric__c> imgList = new List<Field_Images_Bric__c>();
        for(String cdId : setOfCdIds)
        {
            Field_Images_Bric__c img = new Field_Images_Bric__c();
			img.Image_ID_Bric__c = cdId;
			img.Service_Appointment_Bric__c = saId; 
            imgList.add(img);
    	}
        if(isInsert)
            insert imgList;
        return imgList;
    }
    
    public static List<AssignedResource> createAssignedResources(String saId, String srId, Boolean isInsert)
    {
        List<AssignedResource> arList = new List<AssignedResource>();
        AssignedResource ar = new AssignedResource();
        ar.ServiceAppointmentId = saId;
        ar.ServiceResourceId = srId;
        arList.add(ar);
        if(isInsert)
            insert arList;
        return arList;
    }
    
    public class ServiceAppointmentValues
    {
        public String oppId {get; set;}
        public String territoryId {get; set;}
        public String workTypeId {get; set;}
        public String contactId {get; set;}
        public DateTime schedStartTime {get; set;}
        public DateTime schedEndTime {get; set;}
    }
*/
}