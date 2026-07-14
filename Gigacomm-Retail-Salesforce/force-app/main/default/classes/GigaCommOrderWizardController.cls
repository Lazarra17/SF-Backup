/*
Author: Chad Lazarra(Bricoleur Technology)
Date: 
History: [1] CL - 06-Jun - Added UTM Parameters
		 [2] CL - 17-Jun - Update the Lead Source
		 [3] CL - 17-Jun - Automatic Add Router when Plan is Selected
         [4] CL - 30-Jun - Delete vouchers if existing
		 [5] CL - 7-July - Save Voucher on Creation
		 [5]CL 26-Aug-25 : GR-246 Custom Promo Message
         [6]CL 5-Sept-25 : GR-246 Check for duplicate LP with same Product promo
                     
*/

public without sharing class GigaCommOrderWizardController {
  public class SiteLead {
    @AuraEnabled
    public String Id;
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
    public String Term;
    @AuraEnabled
    public Integer TermNum;
    @AuraEnabled
    public List<PlansAndInclusions> Plans;
    @AuraEnabled
    public List<Product_Inclusion_bric__c> PlansInclusions;
    @AuraEnabled
    public Boolean Serviceable;
    @AuraEnabled
    public Boolean ServiceablePlan; //Used in Our Plane Page
    @AuraEnabled
    public Boolean RefreshPlans;
    @AuraEnabled
    public Boolean HideWizard;
    @AuraEnabled
    public Integer TotalRouterQuantity;
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
    public Lead_Product_Item__c AgentPriceRouter;
    @AuraEnabled
    public Lead_Product_Item__c Installation;
    @AuraEnabled
    public Lead_Product_Item__c InstallationPromo;
    @AuraEnabled
    public String InstallationPromoPromoMessage; //[5]CL 26-Aug-25 : GR-246 Custom Promo Message
    @AuraEnabled
    public Boolean ShowRouter;
    @AuraEnabled
    public String Status;
    @AuraEnabled
    public Decimal TotalPrice;
    @AuraEnabled
    public String AgentCode;
    @AuraEnabled
    public String Kiosk;
    @AuraEnabled
    public Boolean AgentPriceOverride;
    @AuraEnabled
    public Integer StatusCode;
    @AuraEnabled
    public String ErrorPayload;
    @AuraEnabled
    public Boolean IncludeRouter;
    //UTM Parameters
    @AuraEnabled
    public String UTMSource;
    @AuraEnabled
    public String UTMMedium;
    @AuraEnabled
    public String UTMCampaign;
    @AuraEnabled
    public String UTMTerm;
    @AuraEnabled
    public String UTMContent;
    @AuraEnabled
    public String IPAddress;
    @AuraEnabled
    public String PromoCodeReferral;
    @AuraEnabled
    public Boolean isPromoCodeValid;
    @AuraEnabled
    public String promoCodeMessage;
  }

  public class PlansAndInclusions {
    @AuraEnabled
    public PriceBookEntry Plan;
    @AuraEnabled
    public List<Product_Inclusion_bric__c> PlansInclusions;
  }

  @AuraEnabled
  public static List<PlansAndInclusions> getPlans() {
    Set<Id> productIdSet = new Set<Id>();
    List<PlansAndInclusions> plnsInclusions = new List<PlansAndInclusions>();
    Map<Id, List<Product_Inclusion_bric__c>> prodVsProdInclusionsMap = new Map<Id, List<Product_Inclusion_bric__c>>();

    LIST<PriceBookEntry> plans = [
      SELECT
        Id,
        Product2Id,
        Product2.Name,
        UnitPrice,
        Product2.Download_Limit__c,
        Product2.Download_Unit_bric__c,
        Product2.Upload_Limit__c,
        Product2.Benefits_Inclusions_bric__c,
        Product2.Home_Page_Pre_Selected_bric__c,
        Product2.Upload_Unit_bric__c,
        Product2.Data_Capacity_bric__c,
        Product2.Frequency_bric__c,
        Product2.Description,
        Product2.Banner_bric__c,
        Product2.Display_Name_Bric__c,
        Product2.Desktop_URL_bric__c,
        Product2.Mobile_Image_bric__c,
        Product2.Tablet_Image_bric__c,
        Product2.Evening_Download_Limit__c,
        Product2.Evening_Upload_Limit__c,
        Product2.Is_Most_Popular__c
      FROM PriceBookEntry
      WHERE
        Product2.Display_On_Home_bric__c = TRUE
        AND Product2.Family = 'Data'
        AND PriceBook2.Name = 'Standard Price Book'
        AND Product2.Listed_on_Website_bric__c = TRUE
      ORDER BY Product2.Sort_Order_bric__c ASC
    ];

    for (PriceBookEntry pbe : plans) {
      productIdSet.add(pbe.Product2Id);
    }

    for (Product_Inclusion_bric__c pi : [
      SELECT
        Id,
        Name,
        Product_bric__c,
        Payment_Term_bric__c,
        Inclusion_bric__c,
        Display_on_Website_bric__c,
        Sort_Order__c
      FROM Product_Inclusion_bric__c
      WHERE
        Product_bric__c IN :productIdSet
        AND Display_on_Website_bric__c = TRUE
      ORDER BY Sort_Order__c
    ]) {
      if (prodVsProdInclusionsMap.containsKey(pi.Product_bric__c)) {
        prodVsProdInclusionsMap.get(pi.Product_bric__c).add(pi);
      } else {
        prodVsProdInclusionsMap.put(
          pi.Product_bric__c,
          new List<Product_Inclusion_bric__c>{ pi }
        );
      }
    }

    //Insert the Product inclusion on Plans
    for (PriceBookEntry pbe : plans) {
      PlansAndInclusions pi = new PlansAndInclusions();
      pi.Plan = pbe;

      if (prodVsProdInclusionsMap.containsKey(pbe.Product2Id)) {
        pi.Plan = pbe;
        pi.PlansInclusions = prodVsProdInclusionsMap.get(pbe.Product2Id);
      }
      plnsInclusions.add(pi);
    }

    return plnsInclusions;
  }

  private static List<PlansAndInclusions> getNonServiceablePlans() {
    return filterOut2GbPlans(getPlans());
  }

  private static List<PlansAndInclusions> filterOut2GbPlans(
    List<PlansAndInclusions> plans
  ) {
    List<PlansAndInclusions> filteredPlans = new List<PlansAndInclusions>();
    if (plans == null) {
      return filteredPlans;
    }

    for (PlansAndInclusions plan : plans) {
      String displayName = plan.Plan != null &&
        plan.Plan.Product2 != null
        ? plan.Plan.Product2.Display_Name_Bric__c
        : null;

      if (displayName != null && displayName.toLowerCase().contains('2gb')) {
        continue;
      }

      filteredPlans.add(plan);
    }

    return filteredPlans;
  }

  @AuraEnabled
  public static GigaCommOrderWizardController.SiteLead getLead(
    String enquiryId
  ) {
    GigaCommOrderWizardController.SiteLead sl = new GigaCommOrderWizardController.SiteLead();
    List<Lead> leads = [
      SELECT
        Id,
        Status,
        TECH_Address_bric__c,
        TECH_Include_Router_bric__c,
        TECH_Term_bric__c,
        Term_bric__c,
        StateCode,
        CountryCode,
        Street,
        State,
        City,
        PostalCode,
        Agent_Code_bric__c,
        Product_Offering_Qualification_JSON__c,
        Plan_bric__c,
        TECH_LastName_bric__c,
        Website_Lead_Status_bric__c,
        Agent_Price_Override_bric__c
      FROM Lead
      WHERE Id = :enquiryId AND IsConverted = FALSE
    ];
    List<PlansAndInclusions> plnsInclusions = new List<PlansAndInclusions>();
    if (leads.size() > 0) {
      Lead lead = leads[0];
      Decimal totalPrice = 0;
      List<PriceBookEntry> plans = new List<PriceBookEntry>();
      if (lead.Product_Offering_Qualification_JSON__c != null) {
        system.debug('PLAN EXIST');

        Set<Id> productIdSet = new Set<Id>();

        Map<Id, List<Product_Inclusion_bric__c>> prodVsProdInclusionsMap = new Map<Id, List<Product_Inclusion_bric__c>>();

        List<Product2> poqProducts = (List<Product2>) JSON.deserialize(
          lead.Product_Offering_Qualification_JSON__c,
          List<Product2>.class
        );

        List<String> productCodes = new List<String>();
        for (Product2 prod : poqProducts) {
          productCodes.add(prod.ProductCode);
        }

        plans = [
          SELECT
            Id,
            Product2Id,
            Product2.Name,
            UnitPrice,
            Product2.Download_Limit__c,
            Product2.Download_Unit_bric__c,
            Product2.Upload_Limit__c,
            Product2.Benefits_Inclusions_bric__c,
            Product2.Home_Page_Pre_Selected_bric__c,
            Product2.Upload_Unit_bric__c,
            Product2.Data_Capacity_bric__c,
            Product2.Frequency_bric__c,
            Product2.Description,
            Product2.Banner_bric__c,
            Product2.Display_Name_Bric__c,
            Product2.Desktop_URL_bric__c,
            Product2.Mobile_Image_bric__c,
            Product2.Tablet_Image_bric__c,
            Product2.Listed_on_Website_bric__c,
            Product2.ProductCode,
            Product2.Evening_Download_Limit__c,
            Product2.Evening_Upload_Limit__c,
            Product2.Is_Most_Popular__c
          FROM PriceBookEntry
          WHERE
            Product2.ProductCode IN :productCodes
            AND PriceBook2.Name = 'Standard Price Book'
            AND Product2.Listed_on_Website_bric__c = TRUE
          ORDER BY Product2.Sort_Order_bric__c ASC
        ];

        System.debug('##productCodes: ' + productCodes);
        for (PriceBookEntry pbe : plans) {
          productIdSet.add(pbe.Product2Id);
        }

        if (productIdSet.size() > 0) {
          sl.Serviceable = true; //If there are Plans return meaning it is serviceable
        }

        for (Product_Inclusion_bric__c pi : [
          SELECT
            Id,
            Name,
            Product_bric__c,
            Payment_Term_bric__c,
            Inclusion_bric__c,
            Display_on_Website_bric__c,
            Sort_Order__c
          FROM Product_Inclusion_bric__c
          WHERE
            Product_bric__c IN :productIdSet
            AND Display_on_Website_bric__c = TRUE
          ORDER BY Sort_Order__c
        ]) {
          if (prodVsProdInclusionsMap.containsKey(pi.Product_bric__c)) {
            prodVsProdInclusionsMap.get(pi.Product_bric__c).add(pi);
          } else {
            prodVsProdInclusionsMap.put(
              pi.Product_bric__c,
              new List<Product_Inclusion_bric__c>{ pi }
            );
          }
        }

        //Insert the Product inclusion on Plans
        for (PriceBookEntry pbe : plans) {
          PlansAndInclusions pi = new PlansAndInclusions();
          pi.Plan = pbe;

          if (prodVsProdInclusionsMap.containsKey(pbe.Product2Id)) {
            pi.Plan = pbe;
            pi.PlansInclusions = prodVsProdInclusionsMap.get(pbe.Product2Id);
          }
          plnsInclusions.add(pi);
        }
      }
      //List<Lead_Product_Item__c> prodItems = [SELECT Id FROM Lead_Product_Item__c WHERE Lead_bric__c =: enquiryId];

      sl.Id = lead.Id;
      sl.Address = lead.TECH_Address_bric__c;

      sl.PostCode = lead.PostalCode;
      sl.State = lead.StateCode;
      sl.Street = lead.Street;
      sl.Suburb = lead.City;
      sl.Status = lead.Website_Lead_Status_bric__c;
      sl.HideWizard = false;
      sl.Term = lead.Term_bric__c;
      sl.TermNum = Integer.ValueOf(lead.TECH_Term_bric__c);
      sl.AgentCode = lead.Agent_Code_bric__c;
      sl.AgentPriceOverride = lead.Agent_Price_Override_bric__c;
      sl.IncludeRouter = lead.TECH_Include_Router_bric__c;
      if (plnsInclusions.size() > 0) {
        sl.Plans = plnsInclusions;
      }

      //Map Vouchers to check if the Product is a voucher
      Map<Id, Id> vouchersProductMap = new Map<Id, Id>();
      for (Voucher_Product__c vp : [
        SELECT Id, Product_to_Apply_bric__c
        FROM Voucher_Product__c
      ]) {
        vouchersProductMap.put(vp.Product_to_Apply_bric__c, vp.Id);
      }

      Map<Id, Lead_Product_Item__c> voucherMap = new Map<Id, Lead_Product_Item__c>(); //[5]CL 26-Aug-25 : GR-246 Custom Promo Message
      //Get the Products items
      Integer TotalRouterQuantity = 0; //Calculate the Total Router Quantity
      for (Lead_Product_Item__c item : [
        SELECT
          Id,
          Total_Price_bric__c,
          Voucher_Term_bric__c,
          Voucher_bric__c,
          Voucher_Type_bric__c,
          Lead_bric__c,
          Product_bric__c,
          Product_bric__r.Family,
          Product_bric__r.ProductCode,
          TECH_PriceBookEntryId_bric__c,
          Product_bric__r.Name,
          Product_bric__r.Display_Name_Bric__c,
          Product_bric__r.Download_Limit__c,
          Product_bric__r.Download_Unit_bric__c,
          Product_bric__r.Upload_Limit__c,
          Product_bric__r.Upload_Unit_bric__c,
          Unit_Price_bric__c,
          Quantity_bric__c,
          Product_bric__r.Download_Upload_Limit_bric__c
        FROM Lead_Product_Item__c
        WHERE Lead_bric__c = :enquiryId
      ]) {
        //get the If there is Voucher
        if (item.Voucher_bric__c != null) {
          voucherMap.put(item.Voucher_bric__c, item);
        }

        //Filter not Voucher Products
        //if(!vouchersProductMap.containsKey(item.Product_bric__c)){
        if (item.Voucher_bric__c == null) {
          if (item.Product_bric__r.Family == 'Data') {
            sl.PlanSelected = item;
          }

          if (
            item.Product_bric__r.Family == 'Hardware' &&
            item.Product_bric__r.ProductCode == Constants.GIGACOMM_ROUTER_SKU
          ) {
            //Main Router
            sl.Router = item;
            system.debug('##sl: ' + sl);
            TotalRouterQuantity = Integer.ValueOf(item.Quantity_bric__c);
          } else if (
            item.Product_bric__r.Family == 'Hardware' &&
            item.Product_bric__r.ProductCode ==
            Constants.GIGACOMM_AGENT_PRICE_ROUTER_SKU
          ) {
            //Agent Price Router
            sl.AgentPriceRouter = item;
          } else if (
            item.Product_bric__r.Family == 'Hardware' &&
            item.Product_bric__r.ProductCode ==
            Constants.GIGACOMM_FREE_ROUTER_BUNDLE_SKU
          ) {
            //Agent Price Router
            sl.RouterPromo = item;
          }

          if (
            item.Product_bric__r.Family == 'Installation' &&
            item.Voucher_Type_bric__c == null
          ) {
            sl.Installation = item;
          }
        }
        totalPrice = totalPrice + item.Total_Price_bric__c;

        if (item.Voucher_Type_bric__c == 'Data Discount') {
          sl.PlanSelectedPromo = item;
        } else if (item.Voucher_Type_bric__c == 'Hardware Discount') {
          sl.RouterPromo = item;
        } else if (item.Voucher_Type_bric__c == 'Installation Discount') {
          sl.InstallationPromo = item;
        }
      }

      //Get the Voucher TC
      //[5]CL 26-Aug-25 : GR-246 Custom Promo Message
      if (voucherMap.size() > 0) {
        //Voucher Map just contain a single voucher Id
        List<Voucher_Product__c> vps = [
          SELECT
            Id,
            Apply_if_Product_Present_bric__r.Family,
            Plan_Promo_Message_bric__c
          FROM Voucher_Product__c
          WHERE
            Voucher_bric__c IN :voucherMap.keySet()
            AND (Product_to_Apply_bric__c = :sl.PlanSelectedPromo.Product_bric__c
            OR Product_to_Apply_bric__c = :sl.InstallationPromo.Product_bric__c)
        ];
        system.debug(vps);
        if (vps.size() > 0) {
          for (Voucher_Product__c vp : vps) {
            if (vp.Apply_if_Product_Present_bric__r.Family == 'Data') {
              sl.PlanSelectedPromoMessage = vp.Plan_Promo_Message_bric__c;
            } else if (
              vp.Apply_if_Product_Present_bric__r.Family == 'Installation'
            ) {
              sl.InstallationPromoPromoMessage = vp.Plan_Promo_Message_bric__c;
            }
          }
        }
      }

      //TotalPrice
      sl.TotalPrice = totalPrice;
      sl.TotalRouterQuantity = TotalRouterQuantity; //assign total quantity
      // sl.ShowRouter = lead.TECH_ShowRouter_bric__c;
      /*
            if(sl.Router != null){
                sl.ShowRouter = true;
            }else{
                sl.ShowRouter = false;
            }
*/
    } else {
      return null;
    }

    return sl;
  }

  @AuraEnabled
  public static GigaCommOrderWizardController.SiteLead createLead(
    String siteLead
  ) {
    GigaCommOrderWizardController.SiteLead sl = (GigaCommOrderWizardController.SiteLead) JSON.deserialize(
      siteLead,
      GigaCommOrderWizardController.SiteLead.class
    );
    Set<String> APOQIds = new Set<String>();
    system.debug('sl.PromoCodeReferral: ' + sl.PromoCodeReferral);
    List<Kiosk_Bric__c> kiosk = [
      SELECT Id
      FROM Kiosk_Bric__c
      WHERE Id = :sl.Kiosk
    ];
    List<Product2> poqProducts = new List<Product2>(); // = Test.isRunningTest() ? [SELECT Id, Product_Offering_Qualification_Id_bric__c FROM Product2 LIMIT 10] : MefPostProductOfferingQualification.PostPOQ(sl);
    List<Voucher__c> voucher = [
      SELECT Id
      FROM Voucher__c
      WHERE Voucher_Code_bric__C = :sl.PromoCodeReferral
    ];
    system.debug('voucher: ' + voucher);

    HttpResponse response = MefPostProductOfferingQualification.PostPOQ(sl);
    system.debug('response: ' + response?.getBody());
    system.debug('body: ' + response?.getBody());
    if (response?.getBody() != null) {
      String responseBodyString = response?.getBody();

      //Return If API is DOWN
      if (response.getStatusCode() >= 400) {
        GigaCommOrderWizardController.SiteLead errorResponse = new GigaCommOrderWizardController.SiteLead();
        errorResponse.Address = sl.Address;
        errorResponse.StatusCode = response.getStatusCode();
        errorResponse.Serviceable = false;
        errorResponse.State = sl.State;
        errorResponse.PostCode = sl.PostCode;
        errorResponse.Plans = getNonServiceablePlans();
        errorResponse.ErrorPayload = responseBodyString;

        Utilities.CreateExceptionLog(responseBodyString, 'GigaComm Website');
        return errorResponse;
      }

      //Cast the response to wrapper class
      RestResponseCollectionMef.PostPOQResponseBody responseBody = (RestResponseCollectionMef.PostPOQResponseBody) JSON.deserialize(
        responseBodyString,
        RestResponseCollectionMef.PostPOQResponseBody.class
      );

      List<RestResponseCollectionMef.AlternateProductOfferingProposal> POQIList = new List<RestResponseCollectionMef.AlternateProductOfferingProposal>();

      POQIList = responseBody
        ?.productOfferingQualificationItem[0]
        ?.AlternateProductOfferingProposal;
      String POQId = responseBody?.Id;

      for (
        RestResponseCollectionMef.AlternateProductOfferingProposal POQI : POQIList
      ) {
        //Get the Mef Product Ids
        if (POQI.serviceabilityConfidence == 'Green') {
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
      lead.Term_bric__c = sl.Term;

      if (poqProducts.size() > 0) {
        system.debug('IP ADDRESS: ' + sl.IPAddress);
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

        lead.Website_Lead_Status_bric__c = sl.Status;
        lead.Product_Offering_Qualification_JSON__c = JSON.serialize(
          poqProducts
        );
        lead.SA2_Id_bric__c = sl.SA2_Id;
        lead.GNAF_Id_bric__c = sl.GNAF_Id;
        lead.Agent_Code_bric__c = sl.AgentCode;
        lead.MefProductOfferingQualificationId_bric__c = poqProducts[0]
          .Product_Offering_Qualification_Id_bric__c;
        if (kiosk.size() > 0) {
          lead.Kiosk_bric__c = kiosk[0].id;
        }

        //[1] CL - 06-Jun - Added UTM Parameters
        lead.UTM_Campaign_bric__c = sl.UTMCampaign;
        lead.UTM_Content_bric__c = sl.UTMContent;
        lead.UTM_Medium_bric__c = sl.UTMMedium;
        lead.UTM_Source_bric__c = sl.UTMSource;
        lead.UTM_Term_bric__c = sl.UTMTerm;

        lead.Mef_POQ_Status_Code_bric__c = responseBody.statusCode;
        lead.Mef_POQ_Response_JSON_bric__c = JSON.serialize(responseBody);

        //[2] CL - 17-Jun - Update Lead Source
        if (sl.AgentCode != null || kiosk.size() > 0) {
          lead.LeadSource = 'Website Kiosk';
        } else {
          lead.LeadSource = 'GigaComm Website';
        }

        //[5] CL - 7-July - Save Voucher on Creation
        if (voucher.size() > 0) {
          lead.Voucher_bric__c = voucher[0].Id;
        }

        Serviceable = true;
        HideWizard = false;
        //    createProductItems(lead, sl);
      } else {
        for (Website_Valid_Address__c address : [
          SELECT Id, Address_bric__c
          FROM Website_Valid_Address__c
        ]) {
          if (address.Address_bric__c.equalsignorecase(sl.Address)) {
            sl.StatusCode = 400;
          }
        }

        sl.Serviceable = false;
        sl.Plans = getNonServiceablePlans();
        return sl;
      }

      try {
        insert lead;
        createProductItems(lead, sl);
        sl = getLead(lead.Id);

        sl.Serviceable = Serviceable;
        sl.HideWizard = HideWizard;
      } catch (Exception e) {
        system.debug('Error: ' + e.getMessage());
        Utilities.createException(e, 'GigaComm Website');
      }
    }

    return sl;
  }

  @AuraEnabled
  public static GigaCommOrderWizardController.SiteLead updateLead(
    String siteLead
  ) {
    GigaCommOrderWizardController.SiteLead sl = (GigaCommOrderWizardController.SiteLead) JSON.deserialize(
      siteLead,
      GigaCommOrderWizardController.SiteLead.class
    );
    List<Product2> poqProducts = new List<Product2>();
    Lead lead = [SELECT Id, Voucher_bric__c FROM Lead WHERE Id = :sl.Id];
    lead.Id = sl.Id;
    system.debug('sl: ' + sl);
    system.debug('sl: ' + sl.Status);

    if (sl.Status == 'Address Check') {
      HttpResponse response = MefPostProductOfferingQualification.PostPOQ(sl);
      system.debug('body: ' + response?.getBody());
      if (response?.getBody() != null) {
        String responseBodyString = response?.getBody();

        //Return If API is DOWN
        if (response.getStatusCode() >= 400) {
          GigaCommOrderWizardController.SiteLead errorResponse = new GigaCommOrderWizardController.SiteLead();
          errorResponse.Address = sl.Address;
          errorResponse.StatusCode = response.getStatusCode();
          errorResponse.Serviceable = false;
          errorResponse.State = sl.State;
          errorResponse.PostCode = sl.PostCode;
          errorResponse.Plans = getNonServiceablePlans();
          errorResponse.ErrorPayload = responseBodyString;

          Utilities.CreateExceptionLog(responseBodyString, 'GigaComm Website');
          return errorResponse;
        }

        //Cast the response to wrapper class
        RestResponseCollectionMef.PostPOQResponseBody responseBody = (RestResponseCollectionMef.PostPOQResponseBody) JSON.deserialize(
          responseBodyString,
          RestResponseCollectionMef.PostPOQResponseBody.class
        );

        //poqProducts = Test.isRunningTest() ? [SELECT Id, Product_Offering_Qualification_Id_bric__c FROM Product2 LIMIT 10] : MefPostProductOfferingQualification.PostPOQ(sl);
        List<RestResponseCollectionMef.AlternateProductOfferingProposal> POQIList = new List<RestResponseCollectionMef.AlternateProductOfferingProposal>();

        POQIList = responseBody
          ?.productOfferingQualificationItem[0]
          ?.AlternateProductOfferingProposal;
        String POQId = responseBody?.Id;
        for (
          RestResponseCollectionMef.AlternateProductOfferingProposal POQI : POQIList
        ) {
          //Get the Mef Product Ids
          if (POQI.serviceabilityConfidence == 'Green') {
            Product2 prod = new Product2();
            prod.ProductCode = POQI.alternateProduct.productOffering.id;
            prod.Product_Offering_Qualification_Id_bric__c = POQId;
            poqProducts.add(prod);
          }
        }
      }
      if (poqProducts.size() > 0) {
        lead.Website_Lead_Status_bric__c = sl.Status;
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
        lead.Product_Offering_Qualification_JSON__c = JSON.serialize(
          poqProducts
        );
        lead.SA2_Id_bric__c = sl.SA2_Id;
        lead.GNAF_Id_bric__c = sl.GNAF_Id;
        lead.Agent_Code_bric__c = sl.AgentCode;
        lead.MefProductOfferingQualificationId_bric__c = poqProducts[0]
          .Product_Offering_Qualification_Id_bric__c;

        try {
          //[4] CL - 30-Jun - Delete vouchers if existing
          if (lead.Voucher_bric__c != null) {
            removeVouchers(lead.Id, lead.Voucher_bric__c);
            lead.Voucher_bric__c = null;
          }

          update lead;
          sl = getLead(sl.Id);

          sl.Serviceable = true;
          system.debug('Update Success');
        } catch (Exception e) {
          Utilities.createException(e, 'GigaComm Website');
          system.debug('Error: ' + e.getMessage());
        }
      } else {
        sl.Serviceable = false;
        sl.Plans = getNonServiceablePlans();
      }
      return sl;
      //return for refresh plans
      //
      //
    } else if (sl.Status == 'Plan Selected') {
      lead.TECH_Include_Router_bric__c = sl.IncludeRouter;
      lead.Website_Lead_Status_bric__c = sl.Status;
      lead.Plan_bric__c = sl.PlanSelected.Product_bric__c;
      lead.Term_bric__c = sl.Term;

      system.debug('sl: ' + sl.Term);
      try {
        //[4] CL - 30-Jun - Delete vouchers if existing
        if (lead.Voucher_bric__c != null) {
          removeVouchers(lead.Id, lead.Voucher_bric__c);
          lead.Voucher_bric__c = null;
        }

        update lead;

        createProductItems(lead, sl);

        //Create Promo Code from Referral and update the Lead
        if (sl.PromoCodeReferral != '') {
          system.debug('##CREATE PROMO CODE');
          sl = applyPromoCode(sl, sl.PromoCodeReferral);
        }
        sl = getLead(sl.Id);
      } catch (Exception e) {
        Utilities.createException(e, 'GigaComm Website');
        system.debug('Error Plan: ' + e.getMessage());
      }

      return sl;
    } else if (sl.Status == 'Router Added') {
      system.debug('REMOVE VOUCHER: ' + lead.Voucher_bric__c);
      lead.Agent_Price_Override_bric__c = sl.AgentPriceOverride;
      lead.Website_Lead_Status_bric__c = sl.Status;

      update lead;
      createProductItems(lead, sl);
      sl = getLead(sl.Id);
      return sl;
    }

    update lead;
    sl = getLead(sl.Id);

    return sl;
  }

  @AuraEnabled
  public static void removeVouchers(String leadId, String voucherId) {
    List<Lead_Product_Item__c> vouchersItems = [
      SELECT Id
      FROM Lead_Product_Item__c
      WHERE Lead_bric__c = :leadId AND Voucher_bric__c = :voucherId
    ];
    if (vouchersItems.size() > 0) {
      delete vouchersItems;
    }
  }

  @AuraEnabled
  public static GigaCommOrderWizardController.SiteLead updateFreeRouter(
    String siteLead
  ) {
    GigaCommOrderWizardController.SiteLead sl = (GigaCommOrderWizardController.SiteLead) JSON.deserialize(
      siteLead,
      GigaCommOrderWizardController.SiteLead.class
    );
    List<Lead_Product_Item__c> productItems = new List<Lead_Product_Item__c>();
    Lead lead = new Lead();
    lead.Id = sl.Id;

    if (sl.Status == 'Router Added') {
      lead.Agent_Price_Override_bric__c = sl.AgentPriceOverride;
      lead.Website_Lead_Status_bric__c = sl.Status;

      List<Lead_Product_Item__c> routerList = [
        SELECT
          Id,
          Product_bric__c,
          Product_bric__r.Family,
          Product_bric__r.ProductCode,
          Quantity_bric__c
        FROM Lead_Product_Item__c
        WHERE Product_bric__r.Family = 'Hardware' AND Lead_bric__c = :lead.Id
      ];

      //Delete Router List so that we can recreate it later
      if (routerList.size() > 0) {
        delete routerList;
      }

      Product2 selectedPlan = new Product2();
      if (sl.PlanSelected != null) {
        selectedPlan = [
          SELECT
            Id,
            Name,
            Installation_SKU_bric__c,
            Installation_Discount_SKU_bric__c,
            Agent_Discount_bric__c
          FROM Product2
          WHERE Id = :sl.PlanSelected?.Product_bric__c
        ];
      }
      system.debug(
        selectedPlan.Name + ' : ' + selectedPlan.Agent_Discount_bric__c
      );
      List<PriceBookEntry> freeRouter = [
        SELECT Id, Product2Id, UnitPrice
        FROM PriceBookEntry
        WHERE
          Product2Id = :selectedPlan.Agent_Discount_bric__c
          AND PriceBook2.Name = 'Standard Price Book'
      ];

      system.debug(
        'CREATE ROUTER' +
          sl.AgentPriceOverride +
          Integer.ValueOf(sl.Router.Quantity_bric__c)
      );

      system.debug('CREATE ROUTER');
      //No Router Exist
      //Create a Router
      if (sl.AgentPriceOverride && sl.Router.Quantity_bric__c == 1) {
        //Create Free Router Lead Product Item
        if (freeRouter.size() > 0) {
          Lead_Product_Item__c freeRouterItem = new Lead_Product_Item__c();
          freeRouterItem.Lead_bric__c = lead.Id;
          freeRouterItem.Product_bric__c = freeRouter[0].Product2Id;
          freeRouterItem.Unit_Price_bric__c = freeRouter[0].UnitPrice;
          freeRouterItem.Quantity_bric__c = 1;
          freeRouterItem.TECH_PriceBookEntryId_bric__c = freeRouter[0].Id;
          productItems.add(freeRouterItem);
        }

        Lead_Product_Item__c routerItem = new Lead_Product_Item__c();
        routerItem.Lead_bric__c = lead.Id;
        routerItem.Product_bric__c = sl.Router.Product_bric__c;
        routerItem.Unit_Price_bric__c = sl.Router.Unit_Price_bric__c;
        routerItem.Quantity_bric__c = sl.Router.Quantity_bric__c;
        routerItem.TECH_PriceBookEntryId_bric__c = sl.Router.TECH_PriceBookEntryId_bric__c;
        productItems.add(routerItem);
      } else {
        Lead_Product_Item__c routerItem = new Lead_Product_Item__c();
        routerItem.Lead_bric__c = lead.Id;
        routerItem.Product_bric__c = sl.Router.Product_bric__c;
        routerItem.Unit_Price_bric__c = sl.Router.Unit_Price_bric__c;
        routerItem.Quantity_bric__c = sl.Router.Quantity_bric__c;
        routerItem.TECH_PriceBookEntryId_bric__c = sl.Router.TECH_PriceBookEntryId_bric__c;
        productItems.add(routerItem);
      }
    }

    update lead;
    sl = getLead(sl.Id);

    return sl;
  }

  public static List<Lead_Product_Item__c> createProductItems(
    Lead lead,
    GigaCommOrderWizardController.SiteLead sl
  ) {
    List<Lead_Product_Item__c> productItems = new List<Lead_Product_Item__c>();
    List<Lead_Product_Item__c> productItemsToUpdate = new List<Lead_Product_Item__c>();
    List<Lead_Product_Item__c> leadItemPlans = new List<Lead_Product_Item__c>();
    List<Lead_Product_Item__c> leadRouter = new List<Lead_Product_Item__c>();
    List<Lead_Product_Item__c> leadInstallation = new List<Lead_Product_Item__c>();
    Map<Id, Lead_Product_Item__c> LeadProdItemMap = new Map<Id, Lead_Product_Item__c>();
    List<PriceBookEntry> installationProd = [
      SELECT Id, Product2Id, UnitPrice
      FROM PriceBookEntry
      WHERE
        PriceBook2.Name = 'Standard Price Book'
        AND ProductCode = 'SKU1001327'
      LIMIT 1
    ];

    Map<Id, Decimal> standardPriceBookEntries = getStandardPriceBookEntries();
    for (Lead_Product_Item__c prod : [
      SELECT
        Id,
        Product_bric__c,
        Product_bric__r.Family,
        Product_bric__r.ProductCode,
        Quantity_bric__c
      FROM Lead_Product_Item__c
      WHERE Lead_bric__c = :lead.Id
    ]) {
      LeadProdItemMap.put(prod.Product_bric__c, prod);

      //List of the existing plan for a lead
      if (prod.Product_bric__r.Family == 'Data') {
        leadItemPlans.add(prod);
      }

      if (
        prod.Product_bric__r.Family == 'Hardware' &&
        prod.Product_bric__r.ProductCode == Constants.GIGACOMM_ROUTER_SKU
      ) {
        leadRouter.add(prod);
      }

      if (prod.Product_bric__r.Family == 'Installation') {
        leadInstallation.add(prod);
      }
    }

    //Check Plan Installation SKUs
    Product2 selectedPlan = new Product2();
    if (sl.PlanSelected != null) {
      selectedPlan = [
        SELECT
          Id,
          Installation_SKU_bric__c,
          Installation_Discount_SKU_bric__c,
          Agent_Discount_bric__c
        FROM Product2
        WHERE Id = :sl.PlanSelected?.Product_bric__c
      ];
    }

    if (sl.Status == 'Plan Selected' && sl.PlanSelected != null) {
      //Checks if No Plan Selected Yet

      List<PriceBookEntry> installation = [
        SELECT Id, Product2Id, UnitPrice
        FROM PriceBookEntry
        WHERE
          Product2Id = :selectedPlan.Installation_SKU_bric__c
          AND PriceBook2.Name = 'Standard Price Book'
      ];
      List<PriceBookEntry> freeInstallation = [
        SELECT Id, Product2Id, UnitPrice
        FROM PriceBookEntry
        WHERE
          Product2Id = :selectedPlan.Installation_Discount_SKU_bric__c
          AND PriceBook2.Name = 'Standard Price Book'
      ];

      if (leadItemPlans.size() > 0) {
        //Plan exist
        system.debug('PLAN EXIST');

        //Plan Exist
        //Update the existing plan -  There should be one plan for each lead
        leadItemPlans[0].Product_bric__c = sl.PlanSelected.Product_bric__c;
        leadItemPlans[0]
          .TECH_PriceBookEntryId_bric__c = sl.PlanSelected.TECH_PriceBookEntryId_bric__c;
        if (
          standardPriceBookEntries.containsKey(sl.PlanSelected.Product_bric__c)
        ) {
          leadItemPlans[0].Unit_Price_bric__c = standardPriceBookEntries.get(
            sl.PlanSelected.Product_bric__c
          );
        }
        productItemsToUpdate.add(leadItemPlans[0]);

        //Delete existing Installation
        //Create new installations
        if (leadInstallation.size() > 0) {
          delete leadInstallation;
        }

        //Create Installation Lead Product Item
        if (installation.size() > 0) {
          Lead_Product_Item__c installationItem = new Lead_Product_Item__c();
          installationItem.Product_bric__c = installation[0].Product2Id;
          installationItem.Quantity_bric__c = 1;
          installationItem.Lead_bric__c = lead.Id;
          installationItem.TECH_PriceBookEntryId_bric__c = installation[0].Id;
          installationItem.Unit_Price_bric__c = installation[0].UnitPrice;
          productItems.add(installationItem);
        }

        //Create Free Installation Lead Product Item
        //If Term is 12 or 24 months then it's free
        if (freeInstallation.size() > 0) {
          if (sl.Term == '12 Months' || sl.Term == '24 Months') {
            Lead_Product_Item__c freeInstallationItem = new Lead_Product_Item__c();
            freeInstallationItem.Product_bric__c = freeInstallation[0]
              .Product2Id;
            freeInstallationItem.Quantity_bric__c = 1;
            freeInstallationItem.Lead_bric__c = lead.Id;
            freeInstallationItem.TECH_PriceBookEntryId_bric__c = freeInstallation[0]
              .Id;
            freeInstallationItem.Unit_Price_bric__c = freeInstallation[0]
              .UnitPrice;
            freeInstallationItem.Voucher_Type_bric__c = 'Installation Discount';
            productItems.add(freeInstallationItem);
          }
        }
      } else {
        system.debug('PLAN NOT EXIST');

        //No Plan Exist - Create a Plan
        Lead_Product_Item__c planItem = new Lead_Product_Item__c();
        planItem.Lead_bric__c = lead.Id;
        planItem.Product_bric__c = sl.PlanSelected.Product_bric__c;
        planItem.Quantity_bric__c = sl.PlanSelected.Quantity_bric__c;
        planItem.TECH_PriceBookEntryId_bric__c = sl.PlanSelected.TECH_PriceBookEntryId_bric__c;
        if (
          standardPriceBookEntries.containsKey(sl.PlanSelected.Product_bric__c)
        ) {
          planItem.Unit_Price_bric__c = standardPriceBookEntries.get(
            sl.PlanSelected.Product_bric__c
          );
        }

        //Create Installation Lead Product Item
        if (installation.size() > 0) {
          Lead_Product_Item__c installationItem = new Lead_Product_Item__c();
          installationItem.Product_bric__c = installation[0].Product2Id;
          installationItem.Quantity_bric__c = 1;
          installationItem.Lead_bric__c = lead.Id;
          installationItem.TECH_PriceBookEntryId_bric__c = installation[0].Id;
          installationItem.Unit_Price_bric__c = installation[0].UnitPrice;
          productItems.add(installationItem);
        }

        //Create Free Installation Lead Product Item
        //If Term is 12 or 24 months then it's free
        if (freeInstallation.size() > 0) {
          if (sl.Term == '12 Months' || sl.Term == '24 Months') {
            Lead_Product_Item__c freeInstallationItem = new Lead_Product_Item__c();
            freeInstallationItem.Product_bric__c = freeInstallation[0]
              .Product2Id;
            freeInstallationItem.Quantity_bric__c = 1;
            freeInstallationItem.Lead_bric__c = lead.Id;
            freeInstallationItem.TECH_PriceBookEntryId_bric__c = freeInstallation[0]
              .Id;
            freeInstallationItem.Unit_Price_bric__c = freeInstallation[0]
              .UnitPrice;
            freeInstallationItem.Voucher_Type_bric__c = 'Installation Discount';
            productItems.add(freeInstallationItem);
          }
        }

        productItems.add(planItem);
        system.debug(productItems);
      }
    }
    system.debug('PlanSelected: ' + sl.PlanSelected);
    system.debug('sl.IncludeRouter: ' + sl.IncludeRouter);
    if (
      (sl.Status == 'Router Added' ||
      sl.Status == 'Plan Selected') &&
      sl.PlanSelected != null &&
      sl.IncludeRouter == true
    ) {
      List<PriceBookEntry> freeRouter = [
        SELECT Id, Product2Id, UnitPrice
        FROM PriceBookEntry
        WHERE
          Product2Id = :selectedPlan.Agent_Discount_bric__c
          AND PriceBook2.Name = 'Standard Price Book'
      ];
      //Refresh Routers
      List<Lead_Product_Item__c> routerList = [
        SELECT
          Id,
          Product_bric__c,
          Product_bric__r.Family,
          Product_bric__r.ProductCode,
          Quantity_bric__c
        FROM Lead_Product_Item__c
        WHERE Product_bric__r.Family = 'Hardware' AND Lead_bric__c = :lead.Id
      ];
      if (routerList.size() > 0) {
        delete routerList;
      }

      //Create Router

      system.debug(
        'CREATE ROUTER' +
          sl.AgentPriceOverride +
          Integer.ValueOf(sl.Router.Quantity_bric__c)
      );

      //Create a Router

      if (sl.AgentPriceOverride) {
        //Create Free Router Lead Product Item
        if (freeRouter.size() > 0) {
          Lead_Product_Item__c freeRouterItem = new Lead_Product_Item__c();
          freeRouterItem.Lead_bric__c = lead.Id;
          freeRouterItem.Product_bric__c = freeRouter[0].Product2Id;
          freeRouterItem.Unit_Price_bric__c = freeRouter[0].UnitPrice;
          freeRouterItem.Quantity_bric__c = 1;
          freeRouterItem.TECH_PriceBookEntryId_bric__c = freeRouter[0].Id;
          productItems.add(freeRouterItem);
        }
      }
      system.debug('sl.RouterPromo: ' + sl.RouterPromo);
      //Create Promo Router from Voucher if there is a Promo Voucher
      if (sl.RouterPromo != null) {
        //recreate Router Promo
        Lead_Product_Item__c voucherRouter = sl.RouterPromo;
        voucherRouter.Id = null;
        productItems.add(voucherRouter);
      }

      Lead_Product_Item__c routerItem = new Lead_Product_Item__c();
      routerItem.Lead_bric__c = lead.Id;

      //Add Router when Plan is Selected
      if (sl.Status == 'Plan Selected') {
        PriceBookEntry router = getRouter();
        system.debug('##: ' + router);
        if (sl.Router == null) {
          sl.Router = new Lead_Product_Item__c();
          sl.Router.Product_bric__c = router.Product2Id;
          sl.Router.Unit_Price_bric__c = router.UnitPrice;
          sl.Router.Quantity_bric__c = 1;
          sl.Router.TECH_PriceBookEntryId_bric__c = router.Id;
        }
        routerItem.Product_bric__c = sl.Router.Product_bric__c;
        routerItem.Unit_Price_bric__c = sl.Router.Unit_Price_bric__c;
        routerItem.Quantity_bric__c = sl.Router.Quantity_bric__c;
        routerItem.TECH_PriceBookEntryId_bric__c = sl.Router.TECH_PriceBookEntryId_bric__c;
      } else {
        routerItem.Product_bric__c = sl.Router.Product_bric__c;
        routerItem.Unit_Price_bric__c = sl.Router.Unit_Price_bric__c;
        routerItem.Quantity_bric__c = sl.Router.Quantity_bric__c;
        routerItem.TECH_PriceBookEntryId_bric__c = sl.Router.TECH_PriceBookEntryId_bric__c;
      }

      productItems.add(routerItem);

      /*
                
                else{
                    Lead_Product_Item__c routerItem = new Lead_Product_Item__c();
                    routerItem.Lead_bric__c = lead.Id;
                    routerItem.Product_bric__c = sl.Router.Product_bric__c;
                    routerItem.Unit_Price_bric__c = sl.Router.Unit_Price_bric__c;
                    routerItem.Quantity_bric__c = sl.Router.Quantity_bric__c;
                    routerItem.TECH_PriceBookEntryId_bric__c = sl.Router.TECH_PriceBookEntryId_bric__c;
                    productItems.add(routerItem);
                }
                */
    }

    if (productItems.size() > 0) {
      try {
        insert productItems;
      } catch (Exception e) {
        system.debug('Error: ' + e.getMessage());
        Utilities.createException(e, 'GigaComm Website');
      }
    }

    if (productItemsToUpdate.size() > 0) {
      update productItemsToUpdate;
    }
    return productItems;
  }

  public static List<Lead_Product_Item__c> updateProductItems(
    List<Lead_Product_Item__c> leadProdItems
  ) {
    return leadProdItems;
  }

  @AuraEnabled
  public static GigaCommOrderWizardController.SiteLead applyPromoCode(
    GigaCommOrderWizardController.SiteLead sl,
    String promoCode
  ) {
    Map<Id, Lead_Product_Item__c> leadProds = new Map<Id, Lead_Product_Item__c>();
    Map<Id, Id> reversionProdMap = new Map<Id, Id>();
    Map<String, Id> voucherTypesMap = new Map<String, Id>();

    for (Lead_Product_Item__c lp : [
      SELECT Id, Product_bric__c, Voucher_Type_bric__c
      FROM Lead_Product_Item__c
      WHERE Lead_bric__c = :sl.Id
    ]) {
      if (!leadProds.containsKey(lp.Product_bric__c)) {
        leadProds.put(lp.Product_bric__c, lp);
      }

      //Filter the voucher type to match with the Product Family for later
      if (lp.Voucher_Type_bric__c == 'Data Discount') {
        voucherTypesMap.put('Data', lp.Product_bric__c);
      } else if (lp.Voucher_Type_bric__c == 'Hardware Discount') {
        voucherTypesMap.put('Hardware', lp.Product_bric__c);
      } else if (lp.Voucher_Type_bric__c == 'Installation Discount') {
        voucherTypesMap.put('Installation', lp.Product_bric__c);
      }
    }

    List<Voucher__c> voucher = [
      SELECT Id, Voucher_Code_bric__c
      FROM Voucher__c
      WHERE Voucher_Code_bric__c = :promoCode
    ];

    if (voucher.size() > 0) {
      List<Voucher_Status__c> voucherStatus = [
        SELECT
          Id,
          Name,
          Status_bric__c,
          Start_Date_bric__c,
          End_Date_bric__c,
          Voucher_bric__c
        FROM Voucher_Status__c
        WHERE Voucher_bric__c = :voucher[0].Id
      ];
      //Check if voucher Status Exist
      if (voucherStatus.size() > 0) {
        //Check if voucher status valid
        if (
          voucherStatus[0].Status_bric__c == 'Active' &&
          voucherStatus[0].Start_Date_bric__c <= System.Today() &&
          voucherStatus[0].End_Date_bric__c >= System.Today()
        ) {
          Set<Id> promoProductsIds = new Set<Id>();
          for (Voucher_Product__c vp : [
            SELECT
              Id,
              Product_to_Apply_bric__c,
              Product_to_Apply_bric__r.Name,
              Product_to_Apply_bric__r.Family,
              Apply_bric__c,
              Apply_if_Product_Present_bric__c,
              Reversion_Product_bric__c,
              Duration_months_bric__c,
              Agreement_Length__c
            FROM Voucher_Product__c
            WHERE Voucher_bric__c = :voucher[0].Id
          ]) {
            //Add Always Products tp Apply
            if (vp.Apply_bric__c == 'Always') {
              promoProductsIds.add(vp.Product_to_Apply_bric__c);
            }
            //Add Product if the Product is Present in Lead Products
            else if (
              vp.Apply_bric__c == 'If Product Present' &&
              leadProds.containsKey(vp.Apply_if_Product_Present_bric__c)
            ) {
              //Check if the there is already a Promo discount bundle.  If does, promo code should not work
              if (
                !voucherTypesMap.containsKey(vp.Product_to_Apply_bric__r.Family)
              ) {
                promoProductsIds.add(vp.Product_to_Apply_bric__c);
              } else {
                continue;
              }
            }
          }

          if (promoProductsIds.size() > 0) {
            List<Lead_Product_Item__c> promoLeadItemsToCreate = new List<Lead_Product_Item__c>();

            Map<Id, PriceBookEntry> promoProdsEntryMap = new Map<Id, PriceBookEntry>();
            for (PriceBookEntry pbe : [
              SELECT Id, Product2Id, UnitPrice
              FROM PriceBookEntry
              WHERE
                Product2Id IN :promoProductsIds
                AND PriceBook2.Name = 'Standard Price Book'
            ]) {
              promoProdsEntryMap.put(pbe.Product2Id, pbe);
            }

            //[6]CL 5-Sept-25 : MAR-217 Check for duplicate LP with same Product promo
            Map<Id, Id> productToApplyMap = new Map<Id, Id>();

            //Loop the filtered VP to create the Lead Product Item
            for (Voucher_Product__c vp : [
              SELECT
                Id,
                Product_to_Apply_bric__c,
                Product_to_Apply_bric__r.Family,
                Product_to_Apply_bric__r.Name,
                Apply_bric__c,
                Reversion_Product_bric__c,
                Duration_months_bric__c,
                Agreement_Length__c
              FROM Voucher_Product__c
              WHERE
                Product_to_Apply_bric__c IN :promoProductsIds
                AND Voucher_bric__c = :voucher[0].Id
            ]) {
              Lead_Product_Item__c lp = new Lead_Product_Item__c();

              //[6]CL 5-Sept-25 : MAR-217 Check for duplicate LP with same Product promo
              //do not add if duplicate found
              if (productToApplyMap.containsKey(vp.Product_to_Apply_bric__c)) {
                continue;
              }

              //Check if Lead Term matches the Agreement Length for Plan otherwise put 1
              if (
                promoProdsEntryMap.containsKey(vp.Product_to_Apply_bric__c) &&
                vp.Agreement_Length__c.contains(sl.Term)
              ) {
                //[6]CL 5-Sept-25 : MAR-217 Check for duplicate LP with same Product promo
                //Add value to Map to check later if has duplicate
                productToApplyMap.put(
                  vp.Product_to_Apply_bric__c,
                  vp.Product_to_Apply_bric__c
                );

                lp.Product_bric__c = promoProdsEntryMap.get(
                    vp.Product_to_Apply_bric__c
                  )
                  .Product2Id;
                lp.Lead_bric__c = sl.Id;
                lp.Quantity_bric__c = 1;
                lp.Unit_Price_bric__c = promoProdsEntryMap.get(
                    vp.Product_to_Apply_bric__c
                  )
                  .UnitPrice;
                lp.TECH_PriceBookEntryId_bric__c = promoProdsEntryMap.get(
                    vp.Product_to_Apply_bric__c
                  )
                  .Id;
                lp.Voucher_bric__c = voucher[0].Id;
                lp.Voucher_Term_bric__c = vp.Duration_months_bric__c;
                lp.Reversion_Product_bric__c = vp.Reversion_Product_bric__c;

                if (vp.Product_to_Apply_bric__r.Family == Constants.DATA) {
                  lp.Voucher_Type_bric__c = Constants.DATA_DISCOUNT;
                } else if (
                  vp.Product_to_Apply_bric__r.Family == Constants.HARDWARE
                ) {
                  lp.Voucher_Type_bric__c = Constants.HARDWARE_DISCOUNT;
                } else if (
                  vp.Product_to_Apply_bric__r.Family == Constants.INSTALLATION
                ) {
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
            l.Id = sl.Id;
            l.Voucher_bric__c = voucher[0].Id;
            sl.isPromoCodeValid = true;

            try {
              update l;

              if (promoLeadItemsToCreate.size() > 0) {
                insert promoLeadItemsToCreate;
              }
            } catch (Exception e) {
              system.debug('Error: ' + e.getMessage());
              Utilities.createException(e, 'GigaComm Website');
            }
          } else {
            system.debug('Error: 1');
            sl.isPromoCodeValid = false;
            sl.promoCodeMessage = 'Your promo code is invalid.';
          }
        } else {
          system.debug('Error: 2');
          sl.isPromoCodeValid = false;
          sl.promoCodeMessage = 'Your promo code is expired.';
        }
      } else {
        system.debug('Error: 3');
        sl.isPromoCodeValid = false;
        sl.promoCodeMessage = 'Your promo code is expired.';
      }
    } else {
      system.debug('Error: 4');
      sl.isPromoCodeValid = false;
      sl.promoCodeMessage = 'Your promo code is invalid.';
    }

    if (sl.isPromoCodeValid == false) {
      Utilities.CreateExceptionLog(sl.promoCodeMessage, 'GigaComm Website');
    }

    return sl;
  }

  @AuraEnabled
  public static GigaCommOrderWizardController.SiteLead removeItem(
    String siteLead
  ) {
    GigaCommOrderWizardController.SiteLead sl = (GigaCommOrderWizardController.SiteLead) JSON.deserialize(
      siteLead,
      GigaCommOrderWizardController.SiteLead.class
    );
    Set<Id> prodItemsToDelete = new Set<Id>();

    if (sl.Router != null) {
      for (Lead_Product_Item__c lpi : [
        SELECT Id, Product_bric__r.Family
        FROM Lead_Product_Item__c
        WHERE Lead_bric__c = :sl.Router.Lead_bric__c
      ]) {
        if (lpi.Product_bric__r.Family == 'Hardware') {
          prodItemsToDelete.add(lpi.Id);
        }
      }
    }

    List<Lead_Product_Item__c> lProdItems = [
      SELECT Id
      FROM Lead_Product_Item__c
      WHERE Lead_bric__c = :sl.Id AND ID IN :prodItemsToDelete
    ];
    try {
      if (lProdItems.size() > 0) {
        delete lProdItems;
      }

      system.debug('###: ' + sl.IncludeRouter);
      if (sl.IncludeRouter != null) {
        Lead l = [
          SELECT Id, TECH_ShowRouter_bric__c
          FROM Lead
          WHERE Id = :sl.Id
        ];
        l.TECH_Include_Router_bric__c = sl.IncludeRouter;
        update l;
      }
    } catch (Exception e) {
      system.debug('Error: ' + e.getMessage());
      Utilities.createException(e, 'GigaComm Website');
    }

    sl = getLead(sl.Id);
    return sl;
  }

  public static Map<Id, Decimal> getStandardPriceBookEntries() {
    Map<Id, Decimal> standardPriceBookEntries = new Map<Id, Decimal>();
    for (PriceBookEntry pbe : [
      SELECT Id, Product2Id, UnitPrice
      FROM PriceBookEntry
      WHERE PriceBook2.Name = 'Standard Price Book'
    ]) {
      standardPriceBookEntries.put(pbe.Product2Id, pbe.UnitPrice);
    }
    return standardPriceBookEntries;
  }

  @auraEnabled
  public static List<Map<String, String>> getPicklistValues(
    String objObject,
    String fld,
    String selected_string
  ) {
    // Get the object type of the SObject.
    Schema.sObjectType objType = Schema.getGlobalDescribe().get(objObject);
    // Describe the SObject using its object type.
    Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
    // Get a map of fields for the SObject
    Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
    // Get the list of picklist values for this field.
    list<Schema.PicklistEntry> values = fieldMap.get(fld)
      .getDescribe()
      .getPickListValues();

    String myValue = '';
    if (selected_string != null) {
      myValue = selected_string;
    }

    List<Map<String, String>> options = new List<Map<String, String>>();

    options.add(new Map<String, String>());

    options.get(0).put('label', 'Select Street Type');

    options.get(0).put('value', '');

    Integer I = 1;

    for (Schema.PicklistEntry a : values) {
      if (a.getValue() == 'NC') {
        continue;
      }

      options.add(new Map<String, String>());

      options.get(I).put('label', a.getLabel());

      options.get(I).put('value', a.getValue());

      if (myValue != '') {
        if (selected_string == a.getValue()) {
          options.get(I).put('selected', 'true');
        } //end of if No2
      } //end of if No1

      I = I + 1;
    }

    return options;
  }
  @AuraEnabled
  public static PriceBookEntry getRouter() {
    return [
      SELECT
        Id,
        Product2Id,
        Product2.Name,
        Product2.Description,
        UnitPrice,
        Product2.Display_Name_Bric__c
      FROM PriceBookEntry
      WHERE
        Product2.ProductCode = 'SKU1001281'
        AND PriceBook2.Name = 'Standard Price Book'
      LIMIT 1
    ];
  }
  @AuraEnabled(cacheable=true)
  public static List<SlideDTO> getSlides() {
    // Query active header config records (adjust field API names if needed)
    List<Header_Config__c> recs = [
      SELECT
        Id,
        Type__c,
        Image_URL__c,
        Video_HTML__c,
        Small_Tag__c,
        Title_Line1__c,
        Title_Line2__c,
        Subtitle__c,
        Button_Label__c,
        Sort_Order__c,
        Active__c,
        Button_Navigation_URL__c
      FROM Header_Config__c
      WHERE Active__c = TRUE
      ORDER BY Sort_Order__c NULLS LAST
    ];

    List<SlideDTO> out = new List<SlideDTO>();
    for (Header_Config__c r : recs) {
      out.add(new SlideDTO(r));
    }
    return out;
  }

  // DTO returned to LWC
  public class SlideDTO {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String type;
    @AuraEnabled
    public String imageUrl;
    @AuraEnabled
    public String videoHtml;
    @AuraEnabled
    public String smallTag;
    @AuraEnabled
    public String titleLine1;
    @AuraEnabled
    public String titleLine2;
    @AuraEnabled
    public String subtitle;
    @AuraEnabled
    public String buttonLabel;
    @AuraEnabled
    public String buttonLink;

    SlideDTO(Header_Config__c r) {
      this.id = r.Id;
      this.type = r.Type__c;
      this.imageUrl = r.Image_URL__c;
      this.videoHtml = r.Video_HTML__c;
      this.smallTag = r.Small_Tag__c;
      this.titleLine1 = r.Title_Line1__c;
      this.titleLine2 = r.Title_Line2__c;
      this.subtitle = r.Subtitle__c;
      this.buttonLabel = r.Button_Label__c;
      this.buttonLink = r.Button_Navigation_URL__c;
    }
  }
}
