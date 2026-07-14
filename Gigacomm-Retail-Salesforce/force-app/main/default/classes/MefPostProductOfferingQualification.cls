/*
@Author: Chad Lazarra (Bricoleur Technology)
@Date: 
@Desc:
@History:
*/
public class MefPostProductOfferingQualification {
    
    //JPS 19 May
    //public static Boolean apiHasError = false;
    
    public static HttpResponse PostPOQ(GigaCommOrderWizardController.SiteLead siteLead){
        Mef_API_Settings__c apiSettings = Mef_API_Settings__c.getOrgDefaults();
        List<PriceBookEntry> plans = new List<PriceBookEntry>();
        List<Product2> poqProducts = new List<Product2>();
        HttpResponse response = new HttpResponse();
        
        Boolean isActive = apiSettings?.Active__c;
        String endpoint = apiSettings?.Endpoint__c;
        
        if(apiSettings == null || !isActive) { 
            return response;
        }else{ 
            
            Map<String , String> requestHeader = MefRequestUtilities.ConstructRequestHeaders(apiSettings); // no need, Named Credentials is used
            RestRequestCollectionMef.PostProductOfferingQualification requestBody = SetPostRequestBody(siteLead);
            String requestBodyString = JSON.serialize(requestBody);
            system.debug('requestBodyString'+requestBodyString);  
            
            
            response = RestHandler.ExecuteRequest(null ,endpoint +  CONSTANTS.INTEGRATION_MEF_ENDPOINT_POQ , requestBodyString, CONSTANTS.INTEGRATION_REST_METHOD_POST); 
          
            
            String responseBodyString = response?.getBody();
            system.debug(response);
            system.debug(responseBodyString);
            
            //Create Error Logs if invalid response
            if(!MefRequestUtilities.CheckResponseBodyValidity(response?.getStatusCode() , responseBodyString)){
                RestHandler.ExceptionLogWrapper contactExLog = new RestHandler.ExceptionLogWrapper();
                contactExLog.requestBody = requestBodyString;
                contactExLog.requestEndpoint =  endpoint + CONSTANTS.INTEGRATION_MEF_ENDPOINT_ADDRESS;
                contactExLog.responseBody = responseBodyString;
                contactExLog.statusCode = String.valueOf(response?.getStatusCode());
                Utilities.CreateExceptionLog(JSON.serialize(contactExLog), 'GigaComm API');   
                //apiHasError = true; //JPS 19 May
                return response;
            }
            
            
          	
                        
        }
        
        return response;
        
    }      
    

     
    
    private static RestRequestCollectionMef.PostProductOfferingQualification SetPostRequestBody(GigaCommOrderWizardController.SiteLead siteLead)
    {
        List<RestRequestCollectionMef.FieldedAddressRepresentation> addressList = new List<RestRequestCollectionMef.FieldedAddressRepresentation>();
        RestRequestCollectionMef.FieldedAddressRepresentation address = new RestRequestCollectionMef.FieldedAddressRepresentation();
        address.streetType = siteLead.StreetType;
        address.streetName = siteLead.StreetName;
        address.streetNr = siteLead.StreetNr;
        address.city = siteLead.Suburb;
        address.stateOrProvince = siteLead.State;
        address.postcode = siteLead.PostCode;
        address.countryCode = siteLead.CountryCode;
        address.language = 'en';
        addressList.add(address);
        System.debug('ADDRESS: ' + address);
        List<RestRequestCollectionMef.Place> places = new List<RestRequestCollectionMef.Place>();
        RestRequestCollectionMef.Place place = new RestRequestCollectionMef.Place();
		place.role = 'INSTALL_LOCATION';
        place.fieldedAddressRepresentation = addressList;   
        places.add(place);

        
        
        RestRequestCollectionMef.productSpecification poqSpecification = new RestRequestCollectionMef.ProductSpecification();
        poqSpecification.id = '121';
        
        
        RestRequestCollectionMef.Product poqProd = new RestRequestCollectionMef.Product();
        poqProd.productSpecification = poqSpecification;
        poqProd.place = places;
        
        List<RestRequestCollectionMef.ProductOfferingQualificationItem>  poqItems = new List<RestRequestCollectionMef.ProductOfferingQualificationItem>();      
        RestRequestCollectionMef.ProductOfferingQualificationItem  poqItem = new RestRequestCollectionMef.ProductOfferingQualificationItem();
        poqItem.id = 'SFGIGA01';
        poqItem.action = 'add';
        poqItem.product = poqProd;
        poqItems.add(poqItem);
       
        
        
        RestRequestCollectionMef.PostProductOfferingQualification postRequestBody = new RestRequestCollectionMef.PostProductOfferingQualification();
        postRequestBody.instantSyncQualification = true;
        postRequestBody.provideAlternative = true;
        postRequestBody.productOfferingQualificationItem = poqItems;
        

        return postRequestBody;
        
        
    }
    
    
}