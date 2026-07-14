/*
@Author: Chad Lazarra
@Date: 
@History: [1]CL 10-Jun-25 : Capture and Save TC
		  [2]CL 19-Jun-25 : Map Address Fields to Oppty Service Fields
		  [3]CL 26-Jun-25 : Voucher Feature
		  [4]CL 19-Aug-25 : GR-239 Manage Duplicate Account
		  [5]CL 26-Aug-25 : GR-246 Custom Promo Message
          [6]CL 10-Oct-25 : GR-265 Update Ezidebit on Account Level
		  [7]CL 14-Jan-26 : MAR-295 Fixed the ACcount Unit Number Address
*/
public without sharing class GigaCommOrderPersonalDetailsController {
    
    
    public class SiteLead{
        @AuraEnabled
        public Lead Lead;
        @AuraEnabled
        public Decimal TotalPrice;
        @AuraEnabled
        public String ContactId;
        @AuraEnabled
        public String OpportunityId;
        @AuraEnabled
        public Lead_Product_Item__c PlanSelected;
        @AuraEnabled
        public Lead_Product_Item__c PlanSelectedPromo;
        @AuraEnabled
        public String PlanSelectedPromoMessage; //[5]CL 26-Aug-25 : GR-246 Custom Promo Message
        @AuraEnabled
        public Lead_Product_Item__c Router;
        @AuraEnabled
        public Lead_Product_Item__c RouterPromo;
        @AuraEnabled
        public Lead_Product_Item__c Installation;
        @AuraEnabled
        public Lead_Product_Item__c InstallationPromo;
        @AuraEnabled
        public String InstallationPromoPromoMessage; //[5]CL 26-Aug-25 : GR-246 Custom Promo Message
        @AuraEnabled
        public Lead_Product_Item__c AgentPriceRouter;
        @AuraEnabled
        public List<Voucher__c> VoucherTCs; 
        @AuraEnabled
        public Voucher__c Voucher; 
        @AuraEnabled
        public Integer TotalRouterQuantity;
        @AuraEnabled
        public Boolean isPromoCodeValid;
        @AuraEnabled
        public String promoCodeMessage;
        
    } 
    
    @AuraEnabled
    public static SiteLead getLead(String enquiryId){
        GigaCommOrderPersonalDetailsController.SiteLead sl = new GigaCommOrderPersonalDetailsController.SiteLead();
        
        Lead lead = [SELECT Id, Unit_Number_Bric__c, Unit_Type_bric__c, Level_Number_bric__c, Level_Type_bric__c, Street_Name_bric__c, Street_Number_bric__c, Street_Number_Last_bric__c, Street_Type_bric__c,
                     TECH_Address_Line1_bric__c, TECH_Address_Line2_bric__c, FirstName, LastName, Email, MobilePhone, TECH_LastName_bric__c, Voucher_bric__c, Voucher_bric__r.Voucher_Code_bric__c, EziDebit_Reference_bric__c,
                     StateCode, State, PostalCode, Term_bric__c, Agree_Terms_bric__c, Agree_Cooling_Off_bric__c, Permit_Technician_Access_bric__c, Accept_Marketing_Terms_bric__c, Has_Voucher_T_C_bric__c
                     FROM Lead WHERE Id =: enquiryId AND IsConverted = false];
        sl.Lead = lead;
        
        if(lead.Voucher_bric__r?.Voucher_Code_bric__c != null){
            sl.isPromoCodeValid = true;
        }
        
        Map<Id, Lead_Product_Item__c> voucherMap = new Map<Id, Lead_Product_Item__c>();
        
        List<Lead_Product_Item__c> voucherList = new List<Lead_Product_Item__c>();
        Decimal totalPrice = 0;
        Decimal totalInstallationPrice = 0;
        Integer TotalRouterQuantity = 0;
        //Get the Products items
        for(Lead_Product_Item__c item : [SELECT Id, Voucher_bric__c, Total_Price_bric__c, Voucher_Type_bric__c, Voucher_Term_bric__c,  Product_bric__r.Installer_Access_Required_bric__c, Product_bric__r.Family, Product_bric__c, Product_bric__r.Name, Product_bric__r.Display_Name_Bric__c,
                                         Product_bric__r.Download_Limit__c, Product_bric__r.Download_Unit_bric__c, Product_bric__r.Upload_Limit__c, Product_bric__r.Upload_Unit_bric__c, 
                                         Unit_Price_bric__c, Quantity_bric__c, Product_bric__r.ProductCode, Product_bric__r.Download_Upload_Limit_bric__c  FROM Lead_Product_Item__c WHERE Lead_bric__c =: enquiryId]){
                                             
                                             //get the If there is Voucher
                                             if(item.Voucher_bric__c != null){
                                                 voucherMap.put(item.Voucher_bric__c, item);
                                             }
                                             
                                             //Filter not Voucher Products
                                               if(item.Voucher_bric__c == null || item.Voucher_Type_bric__c == ''){
                                                 if(item.Product_bric__r.Family == 'Data'){
                                                     sl.PlanSelected = item;
                                                     //totalPrice = totalPrice + item.Total_Price_bric__c;
                                                 }
                                                 
                                                 if(item.Product_bric__r.Family == 'Hardware' && item.Product_bric__r.ProductCode == Constants.GIGACOMM_ROUTER_SKU){
                                                     //Main Router
                                                     sl.Router = item;
                                                     //totalPrice = totalPrice + item.Total_Price_bric__c;
                                                     TotalRouterQuantity = Integer.ValueOf(item.Quantity_bric__c);
                                                 }else if(item.Product_bric__r.Family == 'Hardware' && item.Product_bric__r.ProductCode == Constants.GIGACOMM_AGENT_PRICE_ROUTER_SKU){
                                                     //Agent Price Router
                                                     sl.AgentPriceRouter = item;
                                                 
                                                     
                                                 }else if(item.Product_bric__r.Family == 'Hardware' && item.Product_bric__r.ProductCode == Constants.GIGACOMM_FREE_ROUTER_BUNDLE_SKU){
                                                         //Agent Price Router
                                                         sl.RouterPromo = item;
                                                         
                                                     }
                                                 
                                                 //Get the correct Installation Product
                                                 if(item.Product_bric__r.Family == 'Installation'  && item.Voucher_Type_bric__c == null){
                                                     sl.Installation = item;
                                                     
                                                 }
                                             }
                                             
                                             if(item.Voucher_Type_bric__c == 'Data Discount'){
                                                 sl.PlanSelectedPromo = item;
                                             }else if(item.Voucher_Type_bric__c == 'Hardware Discount'){
                                                 sl.RouterPromo = item;
                                             }else if(item.Voucher_Type_bric__c == 'Installation Discount'){
                                                 sl.InstallationPromo = item;
                                             }
                                             
                                             
                                             
                                             if(item.Voucher_bric__c != null){
                                                 voucherList.add(item);
                                             }
                                             
                                             totalPrice = totalPrice + item.Total_Price_bric__c;
                                            
                                             
                                         }
        
        
        
        //Get the Voucher TC 
        //[5]CL 26-Aug-25 : GR-246 Custom Promo Message
        if(voucherMap.size() > 0){
            //Voucher Map just contain a single voucher Id
            List<Voucher_Product__c> vps = [SELECT Id, Apply_if_Product_Present_bric__r.Family, Plan_Promo_Message_bric__c FROM Voucher_Product__c WHERE Voucher_bric__c IN: voucherMap.keySet() 
                                            AND (Product_to_Apply_bric__c =: sl.PlanSelectedPromo.Product_bric__c OR  Product_to_Apply_bric__c =: sl.InstallationPromo.Product_bric__c)];
            system.debug(vps);
            if(vps.size() > 0){
                
                for(Voucher_Product__c vp : vps){
                    if(vp.Apply_if_Product_Present_bric__r.Family == 'Data'){
                        sl.PlanSelectedPromoMessage = vp.Plan_Promo_Message_bric__c;
                        
                    }else if(vp.Apply_if_Product_Present_bric__r.Family == 'Installation'){
                        sl.InstallationPromoPromoMessage = vp.Plan_Promo_Message_bric__c;
                    }
                }
                
            }
            sl.Voucher = [SELECT Id, Has_T_C_bric__c, Voucher_T_C__c FROM Voucher__c WHERE Id IN: voucherMap.keySet() LIMIT 1];
            
        }
        
        sl.TotalPrice = totalPrice;
        sl.TotalRouterQuantity = TotalRouterQuantity;
        return sl;
        
    }
     
    @AuraEnabled
    public static GigaCommOrderPersonalDetailsController.SiteLead updateLead(String siteLead, Boolean convertLead){
        system.debug('siteLead: ' + siteLead);
        String oppId = '';
        GigaCommOrderPersonalDetailsController.SiteLead sl = (GigaCommOrderPersonalDetailsController.SiteLead)JSON.deserialize(siteLead, GigaCommOrderPersonalDetailsController.SiteLead.class);
        system.debug(sl.Lead);
        Lead l = new Lead();
        l.Id = sl.Lead.Id;
        l.Website_Lead_Status_bric__c = 'Personal Details';
        l.FirstName = sl.Lead.FirstName;
        l.LastName = sl.Lead.TECH_LastName_bric__c;
        
        l.TECH_LastName_bric__c = sl.Lead.TECH_LastName_bric__c;
        l.Email = sl.Lead.Email;
        l.MobilePhone = sl.Lead.MobilePhone;
        l.Unit_Number_Bric__c = sl.Lead.Unit_Number_Bric__c;
        l.Company = sl.Lead.FirstName + ' ' + sl.Lead.TECH_LastName_bric__c;
        
        update l;
        
        
        if(convertLead){
            
            List<Contact> existingCon = [SELECT Id, AccountId FROM Contact WHERE Email =: l.Email LIMIT 1];
            Id opportunityRecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Opportunity' AND DeveloperName = 'Sales_Pipeline' LIMIT 1].Id;  
            system.debug('opportunityRecordTypeId: ' + opportunityRecordTypeId);
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(l.Id);
            lc.setDoNotCreateOpportunity(false);
            lc.setConvertedStatus('Qualified');
          
            //[4] - CL Assign Existing Acc and Con
            if(existingCon.size() > 0){
                lc.setAccountId(existingCon[0].AccountId);   
                lc.setContactId(existingCon[0].Id); 
            }
             
            Database.LeadConvertResult result = Database.convertLead(lc);
            
            oppId = result.getOpportunityId();
            system.debug(oppId);
            copyLeadProductsToOpportunity(l.Id, oppId);
            
            Opportunity oppty = [SELECT Id,AccountId, ContactId, Primary_Contact_Email_Bric__c FROM Opportunity WHERE Id =: oppId];
            
            sl.OpportunityId = oppId;
            sl.ContactId = oppty.ContactId;
            
            
            //[5] CL Update Account type to Customer
            Account acc = new Account();
            acc.Id = oppty.AccountId;
            acc.Type = Constants.CUSTOMER;
            //Update the Billing Address
            acc.Billing_Address_Line1_bric__c = sl.Lead.TECH_Address_Line1_bric__c;
            acc.Billing_Address_Line2_bric__c = sl.Lead.TECH_Address_Line2_bric__c;
            acc.Billing_Level_Number_bric__c = sl.Lead.Level_Number_bric__c;
            acc.Billing_Level_Type_bric__c = sl.Lead.Level_Type_bric__c;
            acc.Billing_Street_Name_bric__c = sl.Lead.Street_Name_bric__c;
            acc.Billing_Street_Number_bric__c = sl.Lead.Street_Number_bric__c;
            acc.Billing_Street_Number_Last_bric__c = sl.Lead.Street_Number_Last_bric__c;
            acc.Billing_Street_Type_bric__c = sl.Lead.Street_Type_bric__c;
            acc.Billing_Unit_Number_bric__c = sl.Lead.Unit_Number_Bric__c;
            acc.Billing_Unit_Type_bric__c = sl.Lead.Unit_Type_bric__c;
                
            acc.Ezidebit_Reference__c = 'allocated:' + sl.Lead.EziDebit_Reference_bric__c; //[6]CL 10-Oct-25 : GR-265 Update Ezidebit on Account Level
                
            update acc;
            
        }
        
        
        
        return sl;
    }
    
    
    
    @AuraEnabled
    public static Lead updateLeadTC(String siteLead){
        system.debug('siteLead: ' + siteLead);
        Lead sl = (Lead)JSON.deserialize(siteLead, Lead.class);
        
        try{
            update sl;
            
            
        } catch(Exception e){
            system.debug('Error: ' + e.getMessage());
            Utilities.createException(e, 'GigaComm Website');
        }
        
        
        return sl;
    }
    
    @AuraEnabled
    public static GigaCommOrderPersonalDetailsController.SiteLead applyPromoCode(String siteLead, String promoCode){
        system.debug('siteLead: ' + siteLead);
        GigaCommOrderPersonalDetailsController.SiteLead sl = (GigaCommOrderPersonalDetailsController.SiteLead)JSON.deserialize(siteLead, GigaCommOrderPersonalDetailsController.SiteLead.class);
        system.debug(sl);
        system.debug(sl.Lead.TECH_LastName_bric__c);
        Map<Id, Lead_Product_Item__c> leadProds = new Map<Id, Lead_Product_Item__c>();
        Map<Id, Id> reversionProdMap = new Map<Id, Id>();
        Map<String, Id> voucherTypesMap = new Map<String, Id>();
        
        for(Lead_Product_Item__c lp : [SELECT Id, Product_bric__c, Voucher_Type_bric__c FROM Lead_Product_Item__c WHERE Lead_bric__c =: sl.Lead.Id]){
            if(!leadProds.containsKey(lp.Product_bric__c)){
                leadProds.put(lp.Product_bric__c, lp);
            }
            
            //Filter the voucher type to match with the Product Family for later 
            if(lp.Voucher_Type_bric__c == 'Data Discount'){
                voucherTypesMap.put('Data', lp.Product_bric__c);
            }else if(lp.Voucher_Type_bric__c == 'Hardware Discount'){
                voucherTypesMap.put('Hardware', lp.Product_bric__c);
            }else if(lp.Voucher_Type_bric__c == 'Installation Discount'){
                voucherTypesMap.put('Installation', lp.Product_bric__c);
            }
            
        } 
        
        List<Voucher__c> voucher = [SELECT Id, Voucher_Code_bric__c FROM Voucher__c WHERE Voucher_Code_bric__c =: promoCode];
        
        if(voucher.size() > 0){
            List<Voucher_Status__c> voucherStatus = [SELECT Id, Name, Status_bric__c, Start_Date_bric__c, End_Date_bric__c, Voucher_bric__c FROM Voucher_Status__c WHERE Voucher_bric__c =: voucher[0].Id AND Status_bric__c = 'Active'];
            //Check if voucher Status Exist
            if(voucherStatus.size() > 0){
                
                //Check if voucher status valid
                if(voucherStatus[0].Start_Date_bric__c <= System.Today() && voucherStatus[0].End_Date_bric__c >= System.Today()){
                    Set<Id> promoProductsIds = new Set<Id>();
                    for(Voucher_Product__c vp : [SELECT Id, Product_to_Apply_bric__c, Product_to_Apply_bric__r.Family, Apply_bric__c, Apply_if_Product_Present_bric__c, Reversion_Product_bric__c, Duration_months_bric__c, Agreement_Length__c 
                                                 FROM Voucher_Product__c WHERE Voucher_bric__c =: voucher[0].Id]){
                                                     
                        //Add Always Products tp Apply
                        if(vp.Apply_bric__c == 'Always'){
                            promoProductsIds.add(vp.Product_to_Apply_bric__c);
                        } 
                        //Add Product if the Product is Present in Lead Products
                        else if(vp.Apply_bric__c == 'If Product Present' && leadProds.containsKey(vp.Apply_if_Product_Present_bric__c)){
                            //Check if the there is already a Promo discount bundle.  If does, promo code should not work
                            if(!voucherTypesMap.containsKey(vp.Product_to_Apply_bric__r.Family)){
                                promoProductsIds.add(vp.Product_to_Apply_bric__c);
                            }else{
                                continue;
                            }
                            
                        }
                                                     
                                                     
                                                 }
                    
                    if(promoProductsIds.size() > 0){
                        List<Lead_Product_Item__c> promoLeadItemsToCreate = new List<Lead_Product_Item__c>();
                        
                        Map<Id, PriceBookEntry> promoProdsEntryMap = new Map<Id, PriceBookEntry>();
                        for(PriceBookEntry pbe : [SELECT Id, Product2Id, UnitPrice FROM PriceBookEntry WHERE Product2Id IN: promoProductsIds AND PriceBook2.Name = 'Standard Price Book']){
                            promoProdsEntryMap.put(pbe.Product2Id, pbe);
                        }
                        
                        //[5]CL 26-Aug-25 : GR-246 Check for duplicate LP with same Product promo
                        Map<Id, Id> productToApplyMap = new Map<Id,Id>();
                        
                        //Loop the filtered VP to create the Lead Product Item
                        for(Voucher_Product__c vp : [SELECT Id, Product_to_Apply_bric__c, Product_to_Apply_bric__r.Family, Apply_bric__c, Reversion_Product_bric__c, Duration_months_bric__c, Agreement_Length__c 
                                                     FROM Voucher_Product__c WHERE Product_to_Apply_bric__c IN : promoProductsIds AND Voucher_bric__c =: voucher[0].Id ]){
                                                         
                                                         //do not add if duplicate found
                                                         if(productToApplyMap.containsKey(vp.Product_to_Apply_bric__c)){
                                                             continue;
                                                         }
                                                         
                                                         Lead_Product_Item__c lp = new Lead_Product_Item__c();
                                                          //Check if Lead Term matches the Agreement Length for Plan otherwise put 1
                                                         if(promoProdsEntryMap.containsKey(vp.Product_to_Apply_bric__c) && vp.Agreement_Length__c.contains(sl.Lead.Term_bric__c)){
                                                             
                                                             //Add value to Map to check later if has duplicate 
                                                             productToApplyMap.put(vp.Product_to_Apply_bric__c, vp.Product_to_Apply_bric__c);
                                                             
                                                             
                                                             lp.Product_bric__c = promoProdsEntryMap.get(vp.Product_to_Apply_bric__c).Product2Id;
                                                             lp.Lead_bric__c = sl.Lead.Id;
                                                             lp.Quantity_bric__c = 1;
                                                             lp.Unit_Price_bric__c = promoProdsEntryMap.get(vp.Product_to_Apply_bric__c).UnitPrice;
                                                             lp.TECH_PriceBookEntryId_bric__c = promoProdsEntryMap.get(vp.Product_to_Apply_bric__c).Id;
                                                             lp.Voucher_bric__c = voucher[0].Id;
                                                             lp.Voucher_Term_bric__c = vp.Duration_months_bric__c;
                                                             lp.Reversion_Product_bric__c = vp.Reversion_Product_bric__c;
                                                             

                                                             if(vp.Product_to_Apply_bric__r.Family == Constants.DATA){
                                                                 lp.Voucher_Type_bric__c = Constants.DATA_DISCOUNT;
                                                             }else if(vp.Product_to_Apply_bric__r.Family == Constants.HARDWARE){
                                                                 lp.Voucher_Type_bric__c = Constants.HARDWARE_DISCOUNT;
                                                             }else if(vp.Product_to_Apply_bric__r.Family == Constants.INSTALLATION){
                                                                 lp.Voucher_Type_bric__c = Constants.INSTALLATION_DISCOUNT;
                                                             }
                                                             
                                                             
                                                             
                                                         }
                                                         /*
                                                          else if(vp.Product_to_Apply_bric__r.Family != 'Data'){
                                                             
                                                             lp.Product_bric__c = promoProdsEntryMap.get(vp.Product_to_Apply_bric__c).Product2Id;
                                                             lp.Lead_bric__c = sl.Lead.Id;
                                                             lp.Quantity_bric__c = 1;
                                                             lp.Unit_Price_bric__c = promoProdsEntryMap.get(vp.Product_to_Apply_bric__c).UnitPrice;
                                                             lp.TECH_PriceBookEntryId_bric__c = promoProdsEntryMap.get(vp.Product_to_Apply_bric__c).Id;
                                                             lp.Voucher_bric__c = voucher[0].Id;
                                                             lp.Voucher_Term_bric__c = vp.Duration_months_bric__c;
                                                             lp.Reversion_Product_bric__c = vp.Reversion_Product_bric__c;
                                                             
                                                         }
                                                         */
                                                         
                                                         
                                                         promoLeadItemsToCreate.add(lp);
                                                         
                                                     }
                        
                        Lead l = new Lead();
                        l.Id = sl.Lead.Id;
                        l.Voucher_bric__c = voucher[0].Id;
                        l.FirstName = sl.Lead.FirstName;
                        l.LastName = sl.Lead.TECH_LastName_bric__c == null || sl.Lead.TECH_LastName_bric__c == '' ? 'TBA' : sl.Lead.TECH_LastName_bric__c;
                        
                        l.TECH_LastName_bric__c =  sl.Lead.TECH_LastName_bric__c;
                        l.Email = sl.Lead.Email;
                        l.MobilePhone = sl.Lead.MobilePhone;
                        l.Unit_Number_Bric__c = sl.Lead.Unit_Number_Bric__c;
                        sl.isPromoCodeValid = true;
                        
                        try{
                            update l;
                            
                            if(promoLeadItemsToCreate.size() > 0){
                                insert promoLeadItemsToCreate;
                            }
                            
                        } catch(Exception e){
                            system.debug('Error: ' + e.getMessage());
                            Utilities.createException(e, 'GigaComm Website');
                        }
                        
                        sl = getLead(l.Id); 
                        
                    }else{
                         system.debug('Error: 1');
                        sl.isPromoCodeValid = false;
                        sl.promoCodeMessage = 'Your voucher code is not valid.';
                    }
                    
                    
               
                    
                    
                }else{
                    system.debug('Error: 2');
                    sl.isPromoCodeValid = false;
                    sl.promoCodeMessage = 'Your voucher code is not valid.';
                }
                
                
            }else{
                system.debug('Error: 3');
                sl.isPromoCodeValid = false;
                sl.promoCodeMessage = 'Your voucher code is not valid.';
            }
            
            
        }else{
            system.debug('Error: 4');
            sl.isPromoCodeValid = false;
            sl.promoCodeMessage = 'Your voucher code is not valid.';
        }
        
        
        
        
        
        
        
        return sl;
    }
    
    @AuraEnabled
    public static GigaCommOrderPersonalDetailsController.SiteLead deleteVouchers(String siteLead, String promoCode){
        system.debug('siteLead: ' + siteLead);
        GigaCommOrderPersonalDetailsController.SiteLead sl = (GigaCommOrderPersonalDetailsController.SiteLead)JSON.deserialize(siteLead, GigaCommOrderPersonalDetailsController.SiteLead.class);
     
        List<Voucher__c> voucher = [SELECT Id, Voucher_Code_bric__c FROM Voucher__c WHERE Voucher_Code_bric__c =: promoCode];
        
        if(voucher.size() > 0){
            
            List<Lead_Product_Item__c> leadProdItem = [SELECT Id FROM Lead_Product_Item__c WHERE Voucher_bric__c =: voucher[0].Id];
            
            Lead l = new Lead();
            l.Id = sl.Lead.Id;
            l.Voucher_bric__c = null;
            sl.isPromoCodeValid = null;
            
            try{
				delete leadProdItem;
                update l;
                sl = getLead(l.Id);
                
                
            } catch(Exception e){
                system.debug('Error: ' + e.getMessage());
                Utilities.createException(e, 'GigaComm Website');
            }
            
        }else{
            sl.isPromoCodeValid = null;
        }
        
        return sl;
    }
    
    public static void copyLeadProductsToOpportunity(Id leadId, Id opportunityId) {
        
        
        //[2]CL 19-Jun-25 : Map Address Fields to Oppty Service Fields
		Lead l = [SELECT Id, City, CountryCode, PostalCode, StateCode, Street FROM Lead WHERE Id =: leadId];
        
        
        // Fetch Lead Products
        List<Lead_Product_Item__c> leadProducts = [
            SELECT Product_bric__c, Quantity_bric__c, Unit_Price_bric__c, TECH_PriceBookEntryId_bric__c, Voucher_bric__c, Voucher_Term_bric__c, Reversion_Product_bric__c
            FROM Lead_Product_Item__c
            WHERE Lead_bric__c = :leadId
        ];
        
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        
        for (Lead_Product_Item__c lp : leadProducts) {
            system.debug('pb: ' + lp.TECH_PriceBookEntryId_bric__c);
            OpportunityLineItem oli = new OpportunityLineItem(
                OpportunityId = opportunityId,
                PricebookEntryId = lp.TECH_PriceBookEntryId_bric__c,
                Quantity = lp.Quantity_bric__c,
                UnitPrice = lp.Unit_Price_bric__c,
                Voucher_bric__c = lp.Voucher_bric__c,
                Voucher_Term_bric__c = lp.Voucher_Term_bric__c,
                Reversion_Product_bric__c = lp.Reversion_Product_bric__c
                
            );
            oppLineItems.add(oli);
        }
        
        insert oppLineItems;
        
        //Update Opportunity to Close Won
        Opportunity opp = [
            SELECT Id, StageName FROM Opportunity WHERE Id = :opportunityId LIMIT 1
        ];
        opp.StageName = Constants.OPPORTUNITY_STAGE_WON_RESIDENTIAL;
        opp.Service_City_bric__c = l.City;
        opp.Service_Postal_Code_bric__c = l.PostalCode;
        opp.Service_State_bric__c = l.StateCode;
        opp.Service_Street_bric__c = l.Street;
        opp.Service_Country_bric__c = l.CountryCode;
        opp.Type = 'Residential';
        opp.Lead_bric__c = l.Id;
        
        
        try {
            update opp;
        } catch (DmlException e) {
            System.debug(e.getMessage());
            for (Integer i = 0; i < e.getNumDml(); i++) {
                System.debug(e.getDmlStatusCode(i)); // Will show FIELD_CUSTOM_VALIDATION_EXCEPTION
                System.debug(e.getDmlMessage(i));    // Shows the validation rule error message
                System.debug(e.getDmlFieldNames(i)); // Shows which field triggered it (if field-level)
            }
        }
        
        
    }
    
}