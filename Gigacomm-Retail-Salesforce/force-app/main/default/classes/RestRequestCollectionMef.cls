public class RestRequestCollectionMef {
    
    /*
Address Validation Body API START
*/
    public class PostAddressValidation {
        public Boolean provideAlternative;
        public SubmittedGeographicAddress submittedGeographicAddress;
    }
    
    public class SubmittedGeographicAddress {
        public String streetNr;
        public String streetNrSuffix;
        public String streetName;
        public String city;
        public String postcode;
        public String country;
        public String type;
    }
    /*=========================================*/
    
    
    /*
	Product Offering Response Body	
	*/
    public class PostProductOfferingQualification{
        public boolean instantSyncQualification;
        public boolean provideAlternative;
        public RelatedContactInformation[] relatedContactInformation;
        public List<ProductOfferingQualificationItem> productOfferingQualificationItem;
    }
    
    
    class RelatedContactInformation {
        public String projectId;	//john.example@buyer.mef.com
        public String name;	//John Example
        public String number_x;	//12-345-6789
        public String numberExtension;	//1234
        public String organization;	//RSP Buyer Co.
        public String role;	//buyerContactInformation
    }
    
    public class ProductOfferingQualificationItem {
        public String id;	//1
        public String action;	//add
        public Product product;
    }
    
    public class Product {
        public productSpecification productSpecification;
        public place[] place;
    }
    
    public class ProductSpecification {
        public String id;	//121
    }
    
    public class Place {
        public List<FieldedAddressRepresentation> fieldedAddressRepresentation;
        public SubUnit subUnit;
        public String role;	//INSTALL_LOCATION
    }
    
    public class FieldedAddressRepresentation {
        public String streetType;	//Street
        public String streetName;	//Meaden
        public String streetNr;	//2
        public String streetNrLast;	//2
        public String city;	//SOUTHBANK
        public String stateOrProvince;	//VIC
        public String postcode;	//3006
        public String countryCode;	//au
        public String language;	//en
    }
    
    public class SubUnit {
        public String subUnitType;	//SUITE
        public String subUnitNumber;	//2
    }
    /*=====================================================*/
    
}