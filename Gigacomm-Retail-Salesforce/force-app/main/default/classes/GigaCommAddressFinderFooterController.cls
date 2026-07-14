/*
@author: Chad Lazarra
@Date:
@History: [1] CL 10-Jun-25 : Capture Ip Address


*/
public without sharing class GigaCommAddressFinderFooterController {
    
    @AuraEnabled
    public static GigaCommOrderWizardController.SiteLead createLead(String siteLead){
        GigaCommOrderWizardController.SiteLead sl = (GigaCommOrderWizardController.SiteLead)JSON.deserialize(siteLead, GigaCommOrderWizardController.SiteLead.class);
        Set<String> APOQIds = new Set<String>();
        List<Product2> poqProducts = new List<Product2>();
        
        HttpResponse response = MefPostProductOfferingQualification.PostPOQ(sl);
        system.debug('response: '+ response?.getBody());
        system.debug('body: '+ response?.getBody());
        if(response?.getBody() != null){ 
            String responseBodyString = response?.getBody();
            
            //Return If API is DOWN
            if(response.getStatusCode() >= 400){
                GigaCommOrderWizardController.SiteLead errorResponse = new GigaCommOrderWizardController.SiteLead();
                errorResponse.Address = sl.Address;
                errorResponse.StatusCode = response.getStatusCode();
                errorResponse.Serviceable = false;
                errorResponse.State = sl.State;
                errorResponse.PostCode = sl.PostCode;
                errorResponse.ErrorPayload = responseBodyString;
                
                Utilities.CreateExceptionLog(responseBodyString, 'GigaComm Website');
                return errorResponse;
            }
            
            //Cast the response to wrapper class
            RestResponseCollectionMef.PostPOQResponseBody responseBody = (RestResponseCollectionMef.PostPOQResponseBody)
                JSON.deserialize(responseBodyString, RestResponseCollectionMef.PostPOQResponseBody.class);
            
            List<RestResponseCollectionMef.AlternateProductOfferingProposal> POQIList = new List<RestResponseCollectionMef.AlternateProductOfferingProposal>();
            
            POQIList = responseBody?.productOfferingQualificationItem[0]?.AlternateProductOfferingProposal;
            String POQId = responseBody?.Id;
            
            for(RestResponseCollectionMef.AlternateProductOfferingProposal POQI : POQIList){
                
                //Get the Mef Product Ids
                if(POQI.serviceabilityConfidence == 'Green'){
                    Product2 prod = new Product2();
                    prod.ProductCode = POQI.alternateProduct.productOffering.id;
                    prod.Product_Offering_Qualification_Id_bric__c = POQId;
                    poqProducts.add(prod);
                }
            }
            system.debug('SKU size: ' + poqProducts); 
            
            Lead lead = new Lead();
            Boolean Serviceable;
            Boolean HideWizard;
            lead.LastName = Constants.TBA;
            lead.Company = Constants.TBA;
            
            if(poqProducts.size() > 0){
                
                lead.IP_Address_bric__c = sl.IPAddress;
                lead.Address_Finder_Id_bric__c = sl.AddressFinderId;
                lead.TECH_Address_bric__c = sl.Address;
                lead.Street = sl.Street;
                lead.Street_Number_bric__c = sl.StreetNr;
                
                
                lead.Unit_Number_Bric__c = sl.UnitNumber;
                lead.Unit_Type_bric__c = sl.UnitType;
                lead.Level_Type_bric__c = sl.LevelType;
                lead.Level_Number_bric__c = sl.LevelNumber;
                
                
                lead.TECH_Address_Line1_bric__c = sl.AddressLine1;
                lead.TECH_Address_Line2_bric__c = sl.AddressLine2;
                
                
                lead.Street_Number_Last_bric__c = sl.StreetNrSuffix;
                lead.Street_Name_bric__c = sl.StreetName;
                lead.Street_Type_bric__c = sl.StreetType;
                lead.StateCode = sl.State;
                lead.City = sl.Suburb;
                lead.PostalCode = sl.PostCode;
                lead.Country = Constants.AUSTRALIA;
                lead.CountryCode = sl.CountryCode;
                
                
                lead.LeadSource = 'GigaComm Website';
                lead.Website_Lead_Status_bric__c = sl.Status;
                lead.Product_Offering_Qualification_JSON__c = JSON.serialize(poqProducts);
                lead.SA2_Id_bric__c = sl.SA2_Id;
                lead.GNAF_Id_bric__c = sl.GNAF_Id;
                lead.Agent_Code_bric__c = sl.AgentCode;
                lead.MefProductOfferingQualificationId_bric__c = poqProducts[0].Product_Offering_Qualification_Id_bric__c;
                
                
                lead.Mef_POQ_Status_Code_bric__c = responseBody.statusCode;
                lead.Mef_POQ_Response_JSON_bric__c= JSON.serialize(responseBody);
                
                Serviceable = true;
                
            }else{
                
                for(Website_Valid_Address__c address : [SELECT Id, Address_bric__c FROM Website_Valid_Address__c]){
                    
                    if(address.Address_bric__c.equalsignorecase(sl.Address)){
                        sl.StatusCode = 400;    
                    }
                    
                }
                
                sl.Serviceable = false;
                return sl;
            }
            
            
            try{
                insert lead;
                sl.Id = lead.Id;
                sl.Serviceable = Serviceable;
                
                
            } catch(Exception e){
                system.debug('Error: ' + e.getMessage());
                Utilities.createException(e, 'GigaComm Website');
            }
            
            
            
        }
        
        
        
        return sl;
    }
    
}