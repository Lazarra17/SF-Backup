public class MYOB_GetContactsBatch implements Database.Batchable<MYOB_RestResponseCollection.Contact>,Database.AllowsCallouts, Database.Stateful
{
    public Map<String,Account> accountMYOBUIDMap;
    public Map<String,Account> accountNameMap;
    public Map<String,List<String>> accContactListMap;
    public Set<String> MYOBUIDs;
    public String paramString;
    
    public MYOB_GetContactsBatch(String params){
        
        accountMYOBUIDMap = new Map<String,Account>();
        accountNameMap = new Map<String,Account>();
        MYOBUIDs = new Set<String>();
        accContactListMap = new Map<String,List<String>>();
        
        List<Account> accountList = [SELECT Id, Name, MYOB_GUID__c,Type FROM Account WHERE Type = 'Customer'];
        if(accountList.size() > 0){
            for(Account acc : accountList){
                if(acc.MYOB_GUID__c != NULL && acc.MYOB_GUID__c != '') accountMYOBUIDMap.put(acc.MYOB_GUID__c, acc);
                accountNameMap.put(acc.Name, acc); 
            }
        }
        paramString = params;
        
    }
    
    public Iterable<MYOB_RestResponseCollection.Contact> start(Database.BatchableContext context)
    {   
        
        MYOB_API_Setting__mdt apiSettings = [SELECT Client_ID__c, Endpoint__c,Company_File_ID__c 
                                             FROM MYOB_API_Setting__mdt
                                             WHERE DeveloperName = 'Default'];
        String clientID = apiSettings?.Client_ID__c;
        String endpoint = apiSettings?.Endpoint__c;
        String companyFileID = apiSettings?.Company_File_ID__c;
        
        MYOBProcessingSettings__c MYOBProcessingSettings = MYOBProcessingSettings__c.getOrgDefaults();
        String modifiedSince = getUTCDateTime(MYOBProcessingSettings?.Contact_Sync_Date_Time__c);
        
        if(apiSettings == NULL || endpoint == NULL || modifiedSince == NULL) return new List<MYOB_RestResponseCollection.Contact>();
        
        Map<String , String> requestHeader = MYOB_RequestUtilities.ConstructRequestHeaders(clientID);
        
        String lastModifiedParam = '';        
        lastModifiedParam = EncodingUtil.urlEncode(MYOB_CONSTANTS.INTEGRATION_MYOB_FILTER_LASTMODIFIED + MYOB_CONSTANTS.INTEGRATION_MYOB_FILTER_DATETIME +
                                                   MYOB_CONSTANTS.GENERIC_SINGLE_QUOTE + modifiedSince +  MYOB_CONSTANTS.GENERIC_SINGLE_QUOTE, 'UTF-8');
        if(paramString == '') paramString = MYOB_CONSTANTS.INTEGRATION_MYOB_FILTER + lastModifiedParam;
            
        HttpResponse getResponse = RestHandler.ExecuteRequest(requestHeader, endpoint + '/' + companyFileId + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER
                                                              + '?' + paramString, null, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_GET);      
		
        String getResponseBodyString = getResponse?.getBody();   
        System.debug('Response'+getResponseBodyString);
        Utilities.CreateRequestResponseLog(MYOB_CONSTANTS.INTEGRATION_REST_METHOD_GET, null, getResponse?.getBody(), getResponse?.getStatusCode(), MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER
                                           + '?' +paramString);
        if(!MYOB_RequestUtilities.CheckResponseBodyValidity(getResponse?.getStatusCode() , getResponseBodyString))
        {
            paramString = '';
            return new List<MYOB_RestResponseCollection.Contact>();
        }

        
       
        
        MYOB_RestResponseCollection.ContactResponseBody myobContact = (MYOB_RestResponseCollection.ContactResponseBody)JSON.deserialize(getResponseBodyString, MYOB_RestResponseCollection.ContactResponseBody.class);
        List<MYOB_RestResponseCollection.Contact> myobContactItems = new List<MYOB_RestResponseCollection.Contact>();
        system.debug('myobContact'+myobContact);
        if(myobContact == NULL){
            paramString = '';
            return new List<MYOB_RestResponseCollection.Contact>();
        }else if(myobContact.Items?.size() > 0 ){
            paramString = myobContact.NextPageLink;
            paramString = paramString?.substringAfter('?');
            
            myobContactItems =  myobContact.Items;        
        }else{
            paramString = '';
            return new List<MYOB_RestResponseCollection.Contact>();
        }

        system.debug('myobContactItems :: ' + myobContactItems);         
        return myobContactItems;    
    }
    
    
    public void execute(Database.BatchableContext context, List<MYOB_RestResponseCollection.Contact> myobConList)
    {
        List<Account> accountsForUpsert = new List<Account>();
        
        if(myobConList != NULL && myobConList.size() > 0){
            for(MYOB_RestResponseCollection.Contact myobContactItem : myobConList) {
                MYOBUIDs.add(myobContactItem.UID);
                accountsForUpsert.add(setAccountRecord(myobContactItem));
            }
            
            if(accountsForUpsert.size() > 0){
                try{
                    system.debug('accountsForUpsert:'+accountsForUpsert);
                    Database.upsert(accountsForUpsert,false);
                    
                }catch(Exception err){
                    Utilities.CreateExceptionLog(err,'MYOB_GetContactsBatch');
                }
            }
        }
    }
    
    public void finish(Database.BatchableContext context) {
        MYOBProcessingSettings__c MYOBProcessingSettings = MYOBProcessingSettings__c.getOrgDefaults();
        if(MYOBProcessingSettings != NULL)
        {
            MYOBProcessingSettings.Contact_Sync_Date_Time__c = System.now();
            Database.Update(MYOBProcessingSettings);
        }
        system.debug('finish paramString : ' + paramString);
        
        if(paramString != '' && paramString != null){
            Database.executeBatch(new MYOB_GetContactsBatch(paramString));
            
        }else{
            
            //Reschedule then delete the previous job for cleaner 
            List<CronTrigger> scheduledJobs = [SELECT Id FROM CronTrigger 
                                               WHERE CronJobDetail.Name LIKE '%MYOB_GetContactsBatch%'];
            for (CronTrigger job : scheduledJobs) {
                try {
                    System.abortJob(job.Id);
                } catch (Exception e) {
                    System.debug('Job already processed or removed: ' + e.getMessage());
                }
            }
            Datetime nextRun = System.now().addMinutes(15);
            String cronStr = nextRun.format('s m H d M ? yyyy');
            System.schedule('MYOB_GetContactsBatch', cronStr, new MYOB_ContactBatchSchedulable());
        } 
    }
    
    public Account setAccountRecord(MYOB_RestResponseCollection.Contact myobContactItem){
        
        Account accountRecord = new Account();
        if(accountMYOBUIDMap?.get(myobContactItem.UID) != NULL) accountRecord.Id = accountMYOBUIDMap.get(myobContactItem.UID)?.Id;
        if(accountRecord.Id == NULL){
           if(accountNameMap?.get(myobContactItem.CompanyName)?.MYOB_GUID__c == NULL || 
              accountNameMap?.get(myobContactItem.CompanyName)?.MYOB_GUID__c == ''){
                  accountRecord.Id = accountNameMap?.get(myobContactItem.CompanyName)?.Id;
              }else{
                   accountRecord.Id = NULL;
              }
        }
        
        system.debug('myobContactItem.CompanyName'+myobContactItem.CompanyName);
        string name= '';
        name=myobContactItem.firstname+' '+myobContactItem.lastname;
        if(myobContactItem.CompanyName!=null && myobContactItem.CompanyName!=''){
          accountRecord.Name = myobContactItem.CompanyName!=null?myobContactItem.CompanyName:name;  
        }else{
            accountRecord.Name = name; 
        }
        accountRecord.Type = MYOB_CONSTANTS.ACCOUNT_TYPE_CUSTOMER;
        accountRecord.MYOB_GUID__c = myobContactItem.UID;
        accountRecord.External_Accounting_Id__c = myobContactItem.UID;
        accountRecord.Active_bric__c = myobContactItem.IsActive;
        accountRecord.MYOB_RowVersion__c = myobContactItem.RowVersion;
        accountRecord.Description = myobContactItem.Notes;        
        accountRecord.MYOB_Display_ID_bric__c = myobContactItem.DisplayID;
        
        MYOB_RestResponseCollection.SellingDetail sellingDetail = myobContactItem.SellingDetails;                
        accountRecord.ABN_Bric__c = sellingDetail?.ABN;  
        
        if(myobContactItem.Addresses?.size() > 0){
            for(MYOB_RestResponseCollection.Address addressItem : myobContactItem.Addresses){
                if(addressItem.Location == 1){
                    accountRecord.BillingCity = addressItem.City;
                    accountRecord.BillingCountry = addressItem.Country;
                    accountRecord.BillingPostalCode = addressItem.PostCode;
                    accountRecord.BillingState = addressItem.State;
                    accountRecord.BillingStreet = addressItem.Street;
                    accountRecord.Phone = addressItem.Phone1;
                    accountRecord.Fax = addressItem.Fax;
                    accountRecord.Website = addressItem.Website;
                    List<String> emailList = new List<String>();
                    String singleEmail = '';
                    if(addressItem.Email != '' && addressItem.Email != null){
                        if(addressItem.Email.contains(';')) emailList = addressItem.Email.split(';');
                        else emailList.add(addressItem.Email);
                        singleEmail = emailList[0];
                    }
                    accountRecord.MYOB_Email__c = singleEmail;
                    accountRecord.MYOB_Emails_bric__c = addressItem.Email;
                    accountRecord.MYOB_Contact_Name__c = addressItem.ContactName;
                    
                }else if(addressItem.Location == 2){
                    accountRecord.ShippingCity = addressItem.City;
                    accountRecord.ShippingCountry = addressItem.Country;
                    accountRecord.ShippingPostalCode = addressItem.PostCode;
                    accountRecord.ShippingState = addressItem.State;
                    accountRecord.ShippingStreet = addressItem.Street;
                }
            }
        }
        system.debug('accountRecord:'+accountRecord);
        return accountRecord;
        
    }
    
    public static String getUTCDateTime(DateTime dt){
        Datetime GMTDate = Datetime.newInstance(
            dt.year(),
            dt.month(),
            dt.day(),
            dt.hour(),
            dt.minute(),
            dt.second());
        String formatted = GMTDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss');
        return formatted;
    }

    
}