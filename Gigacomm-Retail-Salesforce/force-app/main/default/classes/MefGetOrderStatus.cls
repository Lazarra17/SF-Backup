/*
@Author: Chad Lazarra (Bricoleur Technology)
@Date: 17-Sept-25
@Desc:
@History: 
[1] CLAZARRA 17-Sept-25 Created
[2] CLAZARRA 24-Sept-25 Added Field Mapping and error handling
*/
public class MefGetOrderStatus {
    
    
    public static HttpResponse getOrderStatus(Opportunity opp){
        
        Mef_API_Settings__c apiSettings = Mef_API_Settings__c.getOrgDefaults();
        List<PriceBookEntry> plans = new List<PriceBookEntry>();
        List<Product2> poqProducts = new List<Product2>();
        HttpResponse response = new HttpResponse();
        
        Boolean isActive = apiSettings?.Active__c;
        String endpoint = apiSettings?.NonNamedCredentialEndpoint__c;
        
        if(apiSettings == null || !isActive) { 
            return response;
        }else{ 
            
            Map<String , String> requestHeader = MefRequestUtilities.ConstructRequestHeaders(apiSettings);
            response = RestHandler.ExecuteRequest(requestHeader ,endpoint +  CONSTANTS.INTEGRATION_MEF_ENDPOINT_POM + '/' + opp.Mef_Order_Product_Id_bric__c, null, CONSTANTS.INTEGRATION_REST_METHOD_GET); 
            
            String responseBodyString = response?.getBody().replaceAll('"date":', '"date_x":');
            system.debug('response: ' + response);
            system.debug(responseBodyString);
            
            opp.Mef_Product_Order_Response_JSON_bric__c = responseBodyString;
            opp.Mef_Submission_Status_bric__c = String.valueOf(response?.getStatusCode());
            
            //Create Error Logs if invalid response
            if(!MefRequestUtilities.CheckResponseBodyValidity(response?.getStatusCode() , responseBodyString)){
                RestHandler.ExceptionLogWrapper contactExLog = new RestHandler.ExceptionLogWrapper();
                contactExLog.requestBody = '';
                contactExLog.requestEndpoint =  endpoint + CONSTANTS.INTEGRATION_MEF_ENDPOINT_POM;
                contactExLog.responseBody = responseBodyString;
                contactExLog.statusCode = String.valueOf(response?.getStatusCode());
                Utilities.CreateExceptionLog(JSON.serialize(contactExLog), 'GigaComm API');   
                update opp;
                //apiHasError = true; //JPS 19 May
                return response;
            }
            
            
            
            RestResponseCollectionMef.GetOrderStatusResponseBody orderStatusResponse = (RestResponseCollectionMef.GetOrderStatusResponseBody) JSON.deserialize(responseBodyString, RestResponseCollectionMef.GetOrderStatusResponseBody.class);
            
            if(orderStatusResponse.completionDate != null) opp.Completion_Date_bric__c = Date.ValueOf(orderStatusResponse.completionDate);
            if(orderStatusResponse.expectedCompletionDate != null){
              
                DateTime dt = (DateTime) JSON.deserialize('"'+ orderStatusResponse.expectedCompletionDate + '"', DateTime.class);
                opp.Expected_Completion_Date_bric__c = dt; 
                
        
                Datetime dtLocal = Datetime.valueOf(orderStatusResponse.expectedCompletionDate.replace('T', ' ').replace('+11:00',''));
                // Format into mm-dd-yyyy hh:mm am/pm
                String dtLocalFormat = dtLocal.format('dd/MM/yyyy, h:mm a').toLowerCase();
                opp.Expected_Completion_local_bric__c = dtLocalFormat;
                
                opp.Expected_Completion_with_offset_bric__c = orderStatusResponse.expectedCompletionDate;
                
                
            } 
            if(orderStatusResponse.state != null) opp.Mef_Status_bric__c = orderStatusResponse.state;
            
            for(RestResponseCollectionMef.productOrderItem item : orderStatusResponse.productOrderItem){
                system.debug('ID: ' + item.product?.id);
                if(item.product?.id != null){
                    opp.Service_Identification_Number_bric__c = item.product.id;
                }
            }
            
            Set<String> mefNoteIds = new Set<String>();
            if(opp.Mef_Product_Order_Note_Ids_bric__c != null){
                mefNoteIds = (Set<String>) JSON.deserialize(opp.Mef_Product_Order_Note_Ids_bric__c, Set<String>.class);
            }
            //Create a Content Notes
            List<ContentNote> notes = new List<ContentNote>();
            List<ContentDocumentLink> notesLinks = new List<ContentDocumentLink>();
            Set<String> productNoteIds = new Set<String>();
            
            for(RestResponseCollectionMef.note resNote : orderStatusResponse.note){
                Boolean createNote = false;
                if(mefNoteIds.size() > 0){
                    productNoteIds = mefNoteIds;					
                    
                    if(!mefNoteIds.contains(resNote.text)){
                        createNote = true;
                    }
                    
                }else{
                    createNote = true;
                }
                
                if(createNote){
                    
                    Blob body = Blob.valueOf('<p>Date: ' + Date.valueOf(resNote.date_x).format() + '</p>' + 
                                             'Description: ' + resNote.text.escapeHTML4());
                    
                    ContentNote n = new ContentNote();
                    n.Title = resNote.source;
                    n.Content = body;
                    
                    productNoteIds.add(resNote.text);
                    notes.add(n);
                }
                
            }
            
            //Update Opportunity
            //Add Notes Id to opportunity for deduplication
            opp.Mef_Product_Order_Note_Ids_bric__c = JSON.serialize(productNoteIds);
            update opp;
            
            if(notes.size() > 0){
                insert notes;
                
                //Create Document Links
                Set<Id> contentNoteIdSet = new Set<Id>();
                Map<String, String> cdocumentMap = new Map<String, String>();
                for(ContentNote note : notes){
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.ContentDocumentId = note.Id; // Link to the newly created ContentNote
                    cdl.LinkedEntityId = opp.Id;
                    cdl.ShareType = 'V'; // Share type: 'V' for Viewer
                    cdl.Visibility = 'AllUsers'; // Visibility: 'AllUsers' for all users with access to the record
                    
                    
                    contentNoteIdSet.add(note.Id);
                    notesLinks.add(cdl);
                    
                }
                
                if(notesLinks.size() > 0){
                    insert notesLinks;
                    
                }
                
                
            }
            
            
        }
        
        return response;
    }
}