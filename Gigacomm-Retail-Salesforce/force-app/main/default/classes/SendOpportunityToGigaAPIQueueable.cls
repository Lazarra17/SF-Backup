/*
@Author: Bricoleur Technology
@Date:
@History:  [1] CL - 23-Jun-25 - Capture Status Code, Message and Error 
		   [2] CL - 7-July-25 - Revert Oppty Stagename if API is failed 
		   [3] CL - 1-Aug-25 - Remove whitespaces for number and unmasked the number_x to number as string 
		   [4] CL - 26-Jan-26 - Choose Contact.Phone as API Contact Number if Mobile is blank 
		   [5] CL - 3-Feb-26 - Accepting terms correctly 
*/
public class SendOpportunityToGigaAPIQueueable implements Queueable, Database.AllowsCallouts {
    private List<Id> opportunityIds;
    
    public SendOpportunityToGigaAPIQueueable(List<Id> oppIds) {
        this.opportunityIds = oppIds;
    }
    
    public void execute(QueueableContext context) {
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        Map<Id, String> productFamilyMap = new Map<Id,String>();
        List<Opportunity> opps = [
            SELECT Id, Name, AccountId, MefProductOfferingQualificationId_bric__c, Term_bric__c, TECH_Term_Number_bric__c, Plan_bric__c, Plan_bric__r.Family,
            Account.Name, Account.BillingStreet, Account.BillingCity, Gigacomm_Order_Number__c,
            Service_Address_Line1_bric__c, Service_Address_Line2_bric__c, Service_Level_Number_bric__c, Service_Level_Type_bric__c, Service_Street_Name_bric__c,
            Service_Street_Number_bric__c, Service_Street_Number_Last_bric__c, Service_Street_Type_bric__c, Service_Unit_Number_bric__c, Service_Unit_Type_bric__c,
            Service_Country_bric__c, Service_Postal_Code_bric__c, Service_State_bric__c, Service_City_bric__c, 
            Account.GA_Account_Number_bric__c, 
            Account.BillingStateCode, Account.BillingPostalCode, 
            Account.BillingCountryCode, Account.Phone, Account.PersonEmail, Account.Address_Finder_Id_bric__c,
            (SELECT Id, ProductCode, Product2Id, Product_Family_bric__c, Voucher_Term_bric__c, Voucher_bric__c FROM OpportunityLineItems)
            FROM Opportunity
            WHERE Id IN :opportunityIds
        ];
        
        //[4] CL - 26-Jan-26 - Choose Contact.Phone as API Contact Number if Mobile is blank 
        //Map the Opportunity Contact Role
        Map<Id, OpportunityContactRole> oppConRoleMap = new Map<Id, OpportunityContactRole>();
        for(OpportunityContactRole opptyRole : [SELECT Id, OpportunityId, Contact.Name, Contact.Email, Contact.MobilePhone, Contact.Phone FROM OpportunityContactRole
                                                WHERE OpportunityId IN : opps AND IsPrimary = TRUE]){
                                                 
                                                    oppConRoleMap.put(opptyRole.OpportunityId, opptyRole);
                                                    
                                                }
        
        Map<Id, Contact> accountToContactMap = new Map<Id, Contact>();
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : opps) {
            if (opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
        }
        for (Contact con : [
            SELECT Id, AccountId, Name, MobilePhone, Email
            FROM Contact
            WHERE AccountId IN :accountIds
        ]) {
            if (!accountToContactMap.containsKey(con.AccountId)) {
                accountToContactMap.put(con.AccountId, con);
            }
        }
        
        for (Opportunity opp : opps) {
            if (opp.AccountId == null || opp.OpportunityLineItems.isEmpty()) continue;
            
            List<GigaOpportunityRequestWrapper.ProductOrderItem> orderItems = new List<GigaOpportunityRequestWrapper.ProductOrderItem>();
            Set<Id> allOLIIds = new Set<Id>();
            for (OpportunityLineItem oli : opp.OpportunityLineItems) {
                allOLIIds.add(oli.Id);
            }
            
            for (OpportunityLineItem oli : opp.OpportunityLineItems) {
                GigaOpportunityRequestWrapper.ProductOrderItem item = new GigaOpportunityRequestWrapper.ProductOrderItem();
                item.id = oli.Id;
                item.action = 'add';
                
                // Billing Account
                item.billingAccount = new GigaOpportunityRequestWrapper.BillingAccount();
                item.billingAccount.id = opp.Account.GA_Account_Number_bric__c; //New Field under Opportunity Account
                
                // GC Integration
                item.x_gcIntegration = new GigaOpportunityRequestWrapper.GcIntegration();
                item.x_gcIntegration.x_sfAccountId = opp.AccountId;
                Contact c = accountToContactMap.get(opp.AccountId);
                item.x_gcIntegration.x_sfContactId = c != null ? c.Id : null;
                
                //item.x_gcIntegration.x_sfContactId = getContactID(opp.AccountId) != NULL ? getContactID(opp.AccountId) : NULL;
                
                // Item Relationships
                if(opp.OpportunityLineItems.size()>1){
                    item.productOrderItemRelationship = new List<GigaOpportunityRequestWrapper.ProductOrderItemRelationship>();
                    for (Id otherId : allOLIIds) {
                        if (otherId != oli.Id) {
                            GigaOpportunityRequestWrapper.ProductOrderItemRelationship rel = new GigaOpportunityRequestWrapper.ProductOrderItemRelationship();
                            rel.id = otherId;
                            rel.relationshipType = 'LINE_ITEM_GROUP';
                            item.productOrderItemRelationship.add(rel);
                        }
                    }
                }
                
                // Product & Place
                item.product = new GigaOpportunityRequestWrapper.Product();
                item.product.productOffering = new GigaOpportunityRequestWrapper.ProductOffering();
                item.product.productOffering.id = oli.ProductCode;
                
                // Qualification
                item.product.productOfferingQualificationItem = new GigaOpportunityRequestWrapper.ProductOfferingQualificationItem();
                item.product.productOfferingQualificationItem.id = oli.Id;
                if(opp.MefProductOfferingQualificationId_bric__c != '') item.product.productOfferingQualificationItem.productOfferingQualificationId = opp.MefProductOfferingQualificationId_bric__c;
                
                // Address
                // return if there is no Contact [4] CL - 26-Jan-26
                if(!oppConRoleMap.containsKey(opp.Id)){
                    break;
                }
                item.product.place = new List<GigaOpportunityRequestWrapper.Place>();
                GigaOpportunityRequestWrapper.Place place = new GigaOpportunityRequestWrapper.Place();
                place.geographicAddress = buildGeographicAddressFromAccount(opp.Account, oppConRoleMap.get(opp.Id), opp); //[4] CL - 26-Jan-26
                item.product.place.add(place);
                
                // Product relationship
                // //Need to Confirm with LAK
                /*  item.product.productRelationship = new List<GigaOpportunityRequestWrapper.ProductRelationship>();
                GigaOpportunityRequestWrapper.ProductRelationship prodRel = new GigaOpportunityRequestWrapper.ProductRelationship();
                prodRel.relationshipType = 'CONNECTS_TO_UNI';
                prodRel.id = 'SP2_UNI';
                item.product.productRelationship.add(prodRel);
                */
                
                // Term
                item.requestedItemTerm = new GigaOpportunityRequestWrapper.RequestedItemTerm();
                
                //[5] CL - 3-Feb-26 - Accepting terms correctly
                Integer term;
                if(opp.Term_bric__c == null){
                    term = 1;
                }else if(opp.Term_bric__c == 'Monthly'){
                    term = 1;
                }else{
                    term = Integer.valueOf(opp.Term_bric__c.replaceAll(' Months',''));
                }
                
                if(oli.Product_Family_bric__c == 'Data' && oli.Voucher_bric__c == null){
                    
                   
                    item.requestedItemTerm.name = opp.Term_bric__c + ' ' + Constants.INTEGRATION_MEF_TERM; //12 Months Term
                    item.requestedItemTerm.endOfTermAction = Constants.INTEGRATION_MEF_AUTO_RENEW; //AUTO_RENEW
                    item.requestedItemTerm.duration = new GigaOpportunityRequestWrapper.Duration(); 
                    item.requestedItemTerm.duration.amount = term;
                    item.requestedItemTerm.duration.units = Constants.INTEGRATION_MEF_CALENDARMONTHS; // CalendarMonths
                    
                }else if(oli.Product_Family_bric__c == 'Data' && oli.Voucher_bric__c != null){
                    
                    item.requestedItemTerm.name = ''; 
                    item.requestedItemTerm.endOfTermAction = Constants.INTEGRATION_MEF_AUTO_DISCONNECT; //AUTO_DISCONNECT
                    item.requestedItemTerm.duration = new GigaOpportunityRequestWrapper.Duration(); 
                    item.requestedItemTerm.duration.amount = Integer.valueOf(oli.Voucher_Term_bric__c);
                    item.requestedItemTerm.duration.units = Constants.INTEGRATION_MEF_CALENDARMONTHS; // CalendarMonths
                }
                
                //[5] CL - 3-Feb-26 - Accepting terms correctly  - END
                
                orderItems.add(item);
                
            }
            
            // Final payload
            GigaOpportunityRequestWrapper wrapper = new GigaOpportunityRequestWrapper();
            wrapper.externalId = opp.Gigacomm_Order_Number__c;
            //wrapper.projectId = 'buyerProject-' + opp.Id;
            //wrapper.requestedCompletionDate = DateTime.now().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
            
            wrapper.productOrderItem = orderItems;
            
            // Related contact info
            wrapper.relatedContactInformation = new List<GigaOpportunityRequestWrapper.RelatedContactInformation>();
            GigaOpportunityRequestWrapper.RelatedContactInformation contact = new GigaOpportunityRequestWrapper.RelatedContactInformation();
            contact.name = Label.relatedContactInformation_Name;
            contact.emailAddress = Label.relatedContactInformation_emailAddress;
            contact.number_x = Label.relatedContactInformation_Number;
            contact.organization = Label.relatedContactInformation_organization;
            contact.numberExtension = Label.relatedContactInformation_numberExtension;
            contact.role = Label.relatedContactInformation_Role ;
            wrapper.relatedContactInformation.add(contact);
            
            HttpResponse res = sendOpportunityPayload(wrapper);
            if(res == null){return;}
            
            GigaOpportunityResponseWrapper parsed = new GigaOpportunityResponseWrapper();
            String responseBody = res.getBody();
            system.debug('response Body: ');
            system.debug(responseBody);
            
            Opportunity updatedOpp = new Opportunity();
            updatedOpp.Id = opp.Id;
            
            
            if (res.getStatusCode() == 200) {
                responseBody = responseBody.replaceAll('x-','x_');
                responseBody = responseBody.replaceAll('"number"','"number_x"');
               
                parsed = (GigaOpportunityResponseWrapper) JSON.deserialize(responseBody, GigaOpportunityResponseWrapper.class);
                
                updatedOpp.Mef_Status_bric__c = parsed.state;
                if(parsed.state == 'acknowledged'){
                    updatedOpp.Mef_Order_Product_Id_bric__c = parsed.Id;
                }
                updatedOpp.Mef_Submission_Error_bric__c = '';
                 
                
            }else{//Contains Error StatusCode 400>
                Mef_API_Failed_Settings__c apiFailedSettings = Mef_API_Failed_Settings__c.getOrgDefaults();
                updatedOpp.Mef_Submission_Error_bric__c = responseBody; 
                updatedOpp.Mef_Order_Product_Id_bric__c = '';
                updatedOpp.Mef_Status_bric__c = '';
                updatedOpp.StageName = apiFailedSettings.Opportunity_Status_on_Fail_bric__c;
            }
            
            
            
            updatedOpp.Mef_Submission_Status_bric__c = String.valueOf(res.getStatusCode());
            updatedOpp.Mef_Product_Order_Response_JSON_bric__c = responseBody.replaceAll('"number_x"','"number"');
            updatedOpp.Mef_Product_Order_Request_Body_bric__c = JSON.serialize(wrapper).replaceAll('"number_x"','"number"');
            
            oppsToUpdate.add(updatedOpp);
            
            
            
        }
        
        if (!oppsToUpdate.isEmpty()) {
            update oppsToUpdate;
        }
    }
    
    private static GigaOpportunityRequestWrapper.GeographicAddress buildGeographicAddressFromAccount(Account acc, OpportunityContactRole con, Opportunity oppty) {
        GigaOpportunityRequestWrapper.GeographicAddress geo = new GigaOpportunityRequestWrapper.GeographicAddress();
        geo.id = acc.Address_Finder_Id_bric__c;
        geo.role = 'INSTALL_LOCATION'; 
        geo.language = 'en';
        
        // FieldedAddressRepresentation & SubUnit
        GigaOpportunityRequestWrapper.FieldedAddressRepresentation addr = new GigaOpportunityRequestWrapper.FieldedAddressRepresentation();
        if(oppty.Service_Street_Type_bric__c != '') addr.streetType = oppty.Service_Street_Type_bric__c;
        if(oppty.Service_Street_Name_bric__c != '') addr.streetName = oppty.Service_Street_Name_bric__c;
        if(oppty.Service_Street_Number_bric__c != '') addr.streetNr = oppty.Service_Street_Number_bric__c;
        if(oppty.Service_Street_Number_Last_bric__c != '') addr.streetNrLast = oppty.Service_Street_Number_Last_bric__c;
        if(oppty.Service_City_bric__c != '') addr.city = oppty.Service_City_bric__c;
        if(oppty.Service_State_bric__c != '') addr.stateOrProvince = oppty.Service_State_bric__c;
        if(oppty.Service_Postal_Code_bric__c != '') addr.postcode = oppty.Service_Postal_Code_bric__c;
        if(oppty.Service_Country_bric__c != '') addr.countryCode = oppty.Service_Country_bric__c;
        addr.language = 'en';
        
        List<GigaOpportunityRequestWrapper.SubUnit> subUnits = new List<GigaOpportunityRequestWrapper.SubUnit>();
        if(oppty.Service_Unit_Number_bric__c != null || oppty.Service_Unit_Type_bric__c != null){
            GigaOpportunityRequestWrapper.SubUnit subunit = new GigaOpportunityRequestWrapper.SubUnit();
            subunit.subUnitNumber = oppty.Service_Unit_Number_bric__c;
            subunit.subUnitType = oppty.Service_Unit_Type_bric__c;
            
            subUnits.add(subunit);
            
            
        }
        
            if(oppty.Service_Level_Number_bric__c != null || oppty.Service_Level_Type_bric__c != null){
                GigaOpportunityRequestWrapper.SubUnit subunitLevel = new GigaOpportunityRequestWrapper.SubUnit();
                subunitLevel.subUnitNumber = oppty.Service_Level_Number_bric__c;
                subunitLevel.subUnitType = oppty.Service_Level_Type_bric__c;
                subUnits.add(subunitLevel);
                    
                    }
        
        
        if(subUnits.size() > 0){
             addr.subUnit = subUnits;
        }
        
        
        system.debug('##ADDRESS: ' + addr);
        geo.fieldedAddressRepresentation = new List<GigaOpportunityRequestWrapper.FieldedAddressRepresentation>{ addr };
            
            // Contact    
            GigaOpportunityRequestWrapper.Contact contact = new GigaOpportunityRequestWrapper.Contact();
        contact.name = con.Contact.Name;
        contact.number_x = con.Contact?.MobilePhone != null ?  con.Contact?.MobilePhone?.deleteWhitespace() : con.Contact?.Phone?.deleteWhitespace();
        contact.emailAddress = con.Contact.Email;
        geo.contact = new List<GigaOpportunityRequestWrapper.Contact>{ contact };
            
            return geo;
    }
    
    @testVisible
    private static string getContactID(ID accountID){
        contact con = [SELECT ID from Contact where AccountID =: accountID LIMIT 1];
        if(con.Id != NULL){
            return con.Id;
        }else{
            return NULL;
        }
    }
    
    @testVisible
    private static HttpResponse sendOpportunityPayload(GigaOpportunityRequestWrapper payload) {
        Mef_API_Settings__c apiSettings = Mef_API_Settings__c.getOrgDefaults();
        Boolean isActive = apiSettings?.Active__c;
        String endpoint = apiSettings?.Endpoint__c;
        
        String payloadString = JSON.serialize(payload);
        payloadString = payloadString.replaceAll('x_','x-');
        payloadString = payloadString.replaceAll('_x','');
        //String jsonBody = JSON.serialize(payload);
        System.debug('Payload JSON: ' + payloadString);
        String output;
        String responseBody = '';
        HttpResponse res = new HttpResponse();
        try{
            res = RestHandler.ExecuteRequest(null ,endpoint +  CONSTANTS.INTEGRATION_MEF_ENDPOINT_POM , payloadString, CONSTANTS.INTEGRATION_REST_METHOD_POST); 
            
        } catch (Exception ex) {
            Utilities.CreateExceptionLog(ex, payloadString);
            System.debug('Callout Failed: ' + ex.getMessage());
            //output = NULL;
        }
        return res;
    }
}