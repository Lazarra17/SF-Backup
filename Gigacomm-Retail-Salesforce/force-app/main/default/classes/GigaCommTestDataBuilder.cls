@isTest
public class GigaCommTestDataBuilder {
    //Test data for Accounts
    public static List<Account> createAccounts(Boolean isInsert, Integer cnt) {
        
        List<Account> accList = new List<Account>();
        
        for(Integer i=0; i<cnt; i++) {
            Account acc = new Account(
            	Name = 'Test Acc '+i
            );
            accList.add(acc); 
        }
        
        if(isInsert) insert accList;
        
        return accList;
    }
    
    //Test data for Leads
    public static List<Lead> createLeads(Boolean isInsert, Integer cnt) {
    	List<Lead> leadList = new List<Lead>();
        for(Integer i=0; i<cnt; i++) {
            Lead l = new Lead(
            	Status = 'New',
                FirstName = 'Lead '+i,
                LastName = 'Test '+i,
                TECH_Address_bric__c = 'Test Tech Address',
                TECH_LastName_bric__c = 'LAST',
                Street = 'Test Street',
                StateCode = 'VIC',
                City = 'Test City',
                Term_bric__c = 'Monthly',
                PostalCode = '1234',
                Country = 'Australia',
                Product_Offering_Qualification_JSON__c = '[{"attributes":{"type":"Product2"},"ProductCode":"SKU1001160","Product_Offering_Qualification_Id_bric__c":"790f98a4-717c-49c9-9263-b2de00416473"},' +
                                                          '{"attributes":{"type":"Product2"},"ProductCode":"SKU1001161","Product_Offering_Qualification_Id_bric__c":"790f98a4-717c-49c9-9263-b2de00416473"},' +
                                                          '{"attributes":{"type":"Product2"},"ProductCode":"SKU1001313","Product_Offering_Qualification_Id_bric__c":"790f98a4-717c-49c9-9263-b2de00416473"},' +
                                                          '{"attributes":{"type":"Product2"},"ProductCode":"SKU1001314","Product_Offering_Qualification_Id_bric__c":"790f98a4-717c-49c9-9263-b2de00416473"}]',
                
                
                //'[{"attributes":{"type":"Product2"},"ProductCode":"0", "Product_Offering_Qualification_Id_bric__c" : "1"},{"attributes":{"type":"Product2"},"ProductCode":"1", "Product_Offering_Qualification_Id_bric__c" : "1"} },{"attributes":{"type":"Product2"},"ProductCode":"2", "Product_Offering_Qualification_Id_bric__c" : "1"}},{"attributes":{"type":"Product2"},"ProductCode":"3", }]',
                Plan_bric__c = null
            );
            leadList.add(l);
        }
        
        if(isInsert) insert leadList;
        
        return leadList;
    }
    
    //Test data for Products
    public static List<Product2> createProducts(Boolean isInsert, Integer cnt, String Family) {
        
        List<Product2> prodList = new List<Product2>();
        
        for(Integer i=0; i<cnt; i++) {
            Product2 prod = new Product2(
            	Name = 'Test Product GigaComm '+i,
                Download_Limit__c = '100',
                Download_Unit_bric__c = 'Mbps',
                Upload_Limit__c = '100',
                Upload_Unit_bric__c = 'Mbps',
                Display_Name_Bric__c = 'Test Product GigaComm '+i,
                Frequency_bric__c = 'Monthly',
                IsActive = true,
                Status_bric__c = 'Available',
                Display_On_Home_bric__c = true,
                Family = Family,
                Product_Offering_Qualification_Id_bric__c = '1212',
                Listed_on_Website_bric__c = true,
                ProductCode = 'SKU1001160'
            );
            prodList.add(prod);
        }
        
        if(isInsert) insert prodList;
        
        return prodList;
    }
    
    //Test data for PriceBook2Id
    public static Id getPriceBook2Id() {
        PriceBook2 pb = new PriceBook2(Name = 'Standard Price Book', isActive = true);
        insert pb;
        return pb.Id;
    }
    
    //Test data for PBEs
    public static List<PricebookEntry> createPBEs(Boolean isInsert, List<Product2> prodList) {
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        for(Product2 prod : prodList) {
        	PricebookEntry pbe = new PricebookEntry(
            	PriceBook2Id = Test.getStandardPriceBookId(),
                UnitPrice = 100,
                Product2Id = prod.Id,
                isActive = true
            );
            pbeList.add(pbe);
            PricebookEntry pbe2 = new PricebookEntry(
            	PriceBook2Id = getPriceBook2Id(),
                UnitPrice = 100,
                Product2Id = prod.Id,
                isActive = true
            );
            pbeList.add(pbe2);
        }
        if(isInsert) insert pbeList;
        return pbeList;
    }
    
    //Test data for Lead_Product_Item__c
    public static List<Lead_Product_Item__c> createdLeadProductItem(Boolean isInsert, List<Product2> prodList, String leadId) {
        
        List<Lead_Product_Item__c> leadProdItemList = new List<Lead_Product_Item__c>();
        
        for(Product2 prod : prodList) {
            Lead_Product_Item__c lpi = new Lead_Product_Item__c(
            	Product_bric__c = prod.Id,
                Lead_bric__c = leadId,
                Quantity_bric__c = 1,
                Unit_Price_bric__c = 100
            );
            leadProdItemList.add(lpi);
        }
        
        if(isInsert) insert leadProdItemList;
        
        return leadProdItemList;
    }

    public static List<Kiosk_Bric__c> createKiosk(Boolean isInsert, Integer cnt) {

        List<Kiosk_Bric__c> kiosks = new List<Kiosk_Bric__c>();
        
        for(Integer i = 0; i < cnt; i++) {
            Kiosk_Bric__c kiosk = new Kiosk_Bric__c(
                Name = 'Kiosk '+i
            );
            kiosks.add(kiosk);
        }

        if(isInsert) insert kiosks;
        
        return kiosks;
    }
    
    public static List<Product_Inclusion_bric__c> createProductInclusions(Boolean isInsert, Integer cnt, Product2 prod) {
        
        List<Product_Inclusion_bric__c> pis = new List<Product_Inclusion_bric__c>();
        
        for(Integer i = 0; i < cnt; i++) {
            Product_Inclusion_bric__c pi = new Product_Inclusion_bric__c(
                Product_bric__c = prod.Id,
                Display_on_Website_bric__c = true
            );
            pis.add(pi);
        }
        
        if(isInsert) insert pis;
        
        return pis;
    } 
    
    public static List<Voucher__c> createVouchers(Boolean isInsert, Integer cnt) {
        
        List<Voucher__c> vs = new List<Voucher__c>();
        
        for(Integer i = 0; i < cnt; i++) {
            Voucher__c v = new Voucher__c(
                Name = 'PROMO' + i,
                Voucher_Code_bric__c = 'PROMO' + i
            );
            vs.add(v);
        }
        
        if(isInsert) insert vs;
        
        return vs;
    } 
    
    public static List<Voucher_Status__c> createVoucherStatuses(Boolean isInsert, Voucher__c v, Integer cnt) {
        
        List<Voucher_Status__c> vStatuses = new List<Voucher_Status__c>();
        
        for(Integer i = 0; i < cnt; i++) {
            Voucher_Status__c vs = new Voucher_Status__c(
                Voucher_bric__c = v.Id,
                Status_bric__c = 'Active',
                Start_Date_bric__c = system.today(),
                End_Date_bric__c = system.today().AddDays(5)
            );
            vStatuses.add(vs);
        }
        
        if(isInsert) insert vStatuses;
        
        return vStatuses;
    } 
    
    public static List<Voucher_Product__c> createVoucherProducts(Boolean isInsert, Voucher__c v, Product2 promoProd, Product2 prod, Integer cnt) {
        
        List<Voucher_Product__c> vProds = new List<Voucher_Product__c>();
        
        for(Integer i = 0; i < cnt; i++) {
            Voucher_Product__c vp = new Voucher_Product__c(
                Agreement_Length__c = 'Monthly;12 Months;24 Months',
                Apply_bric__c = 'If Product Present',
                Apply_if_Product_Present_bric__c = prod.Id,
                Duration_months_bric__c = 3,
                Product_to_Apply_bric__c = promoProd.Id,
                Voucher_bric__c = v.Id
            );
            vProds.add(vp);
        }
        
        if(isInsert) insert vProds;
        
        return vProds;
    } 
    
    
    public static GigaCommOrderWizardController.SiteLead generateSiteLead(string status, String kioskId){
        GigaCommOrderWizardController.SiteLead sl = new GigaCommOrderWizardController.SiteLead();
        sl.State = 'VIC';
        sl.IncludeRouter = false;
        sl.Street = 'Street';
        sl.Suburb = 'SOUTHBANK';
        sl.CountryCode = 'AU';
        sl.Status = status;
        sl.Kiosk = kioskId;
        
        return sl;
    }

    public static String getStaticSiteLead() {
        return '{' +
            '"Address":"2 Meaden Street, SOUTHBANK, VIC, 3006",' +
            '"HideWizard":false,' +
            '"Id":"00QH3000006G3nuMAC",' +
            '"Installation":{' +
                '"Id":"a0VH3000000FEZfMAO",' +
                '"Product_bric__c":"01tH30000019VgeIAE",' +
                '"Unit_Price_bric__c":125,' +
                '"Quantity_bric__c":1,' +
                '"Product_bric__r":{' +
                    '"Category_bric__c":"Installation",' +
                    '"Name":"Fiber Engineer Installation",' +
                    '"Display_Name_Bric__c":"Fibre Engineer (Installation)",' +
                    '"Download_Unit_bric__c":"Mbps",' +
                    '"Upload_Unit_bric__c":"Mbps",' +
                    '"Id":"01tH30000019VgeIAE"' +
                '}' +
            '},' +
            '"Plans":[' +
                // Repeat similar block for each plan, or break into helper methods if preferred
            '],' +
            '"PlanSelected":{' +
                '"Id":"a0VH3000000FEZgMAO",' +
                '"Product_bric__c":"01tH30000019OPOIA2",' +
                '"Unit_Price_bric__c":65,' +
                '"Quantity_bric__c":1,' +
                '"Product_bric__r":{' +
                    '"Category_bric__c":"Data",' +
                    '"Name":"FTTx 100 (100/25Mbps)",' +
                    '"Display_Name_Bric__c":"HYPER - FAST 2G",' +
                    '"Download_Limit__c":"100",' +
                    '"Download_Unit_bric__c":"Mbps",' +
                    '"Upload_Limit__c":"25",' +
                    '"Upload_Unit_bric__c":"Mbps",' +
                    '"Id":"01tH30000019OPOIA2"' +
                '}' +
            '},' +
            '"PostCode":"3006",' +
            '"Router":{' +
                '"Id":"a0VH3000000FEZcMAO",' +
                '"Product_bric__c":"01tH30000019SumIAE",' +
                '"Unit_Price_bric__c":199,' +
                '"Quantity_bric__c":1,' +
                '"Product_bric__r":{' +
                    '"Category_bric__c":"Hardware",' +
                    '"Name":"AX300 Whole Home Mesh Wifi System",' +
                    '"Id":"01tH30000019SumIAE"' +
                '}' +
            '},' +
            '"State":"VIC",' +
            '"Status":"Address Check",' +
            '"Street":"2 Meaden Street",' +
            '"Suburb":"SOUTHBANK",' +
            '"Term":"Monthly",' +
            '"IncludeRouter":"false",' +
            '"TotalPrice":389' +
        '}';
    }
    
}