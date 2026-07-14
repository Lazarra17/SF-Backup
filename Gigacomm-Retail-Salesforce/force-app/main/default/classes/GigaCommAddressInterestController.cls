/*
Author: Bricoleur Technology
Date: 
History: [1] CL - 09-June-25 - Capture Ip Address
		[2] CL - 17-June-25 - Update Lead Source 
*/
public class GigaCommAddressInterestController {
    
    public class SiteLead{
        
        @AuraEnabled
        public String Address;
        @AuraEnabled
        public String AddressFinderId;
        @AuraEnabled
        public String Street;
        @AuraEnabled
        public String SA2_Id;
        @AuraEnabled
        public String GNAF_Id;
        
        @AuraEnabled
        public String StreetName;
        @AuraEnabled
        public String StreetNr;
        @AuraEnabled
        public String StreetNrSuffix;
        @AuraEnabled
        public String StreetType;
        
        @AuraEnabled
        public String UnitNumber;
        @AuraEnabled
        public String UnitType;
        @AuraEnabled
        public String LevelNumber;
        @AuraEnabled
        public String LevelType;
        
        @AuraEnabled
        public String AddressLine1;
        @AuraEnabled
        public String AddressLine2;
        
        
        @AuraEnabled
        public String State;
        @AuraEnabled
        public String Suburb;
        @AuraEnabled
        public String PostCode;
        @AuraEnabled
        public String Country;
        @AuraEnabled
        public String CountryCode;
        
        @AuraEnabled
        public String FirstName;
        @AuraEnabled
        public String LastName;
        @AuraEnabled
        public String Email;
        @AuraEnabled
        public String IPAddress;
    }
    
    @AuraEnabled
    public static lead createLead(String siteLead){
        system.debug(siteLead);
        GigaCommAddressInterestController.SiteLead sl = (GigaCommAddressInterestController.SiteLead)JSON.deserialize(siteLead, GigaCommAddressInterestController.SiteLead.class);
        
        Lead l = new Lead();
        l.IP_Address_bric__c = sl.IPAddress; //[1] CL - 09-June-25 - Capture Ip Address
        l.FirstName = sl.FirstName;
        l.LastName = sl.LastName;
        l.Email = sl.Email;
        l.Company = sl.FirstName + ' ' + sl.LastName;
        l.LeadSource = 'Website Address Interest';
        
        l.Address_Finder_Id_bric__c = sl.AddressFinderId;
        l.SA2_Id_bric__c = sl.SA2_Id;
        l.GNAF_Id_bric__c = sl.GNAF_Id;
        
        l.Street = sl.AddressLine1 + ', ' + sl.AddressLine2;
        l.Street_Name_bric__c = sl.StreetName;
        l.Street_Number_bric__c = sl.StreetNr;
        l.Street_Number_Last_bric__c = sl.StreetNrSuffix;
        l.Street_Type_bric__c = sl.StreetType;
        
        l.Unit_Number_Bric__c = sl.UnitNumber;
        l.Unit_Type_bric__c = sl.UnitType;
        l.Level_Number_bric__c = sl.LevelNumber;
        l.Level_Type_bric__c = sl.LevelType;
        
        l.StateCode = sl.State;
        l.CountryCode = sl.CountryCode;
        l.PostalCode = sl.PostCode;
        
        try{
            insert l;
        }catch(exception e){
            system.debug('Error: ' + e.getMessage());
            Utilities.createException(e, 'GigaComm Website');
        }
        return l;
        
    }
}