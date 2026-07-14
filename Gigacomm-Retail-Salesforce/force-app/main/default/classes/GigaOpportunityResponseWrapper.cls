public class GigaOpportunityResponseWrapper {
    public String id;
    public String href;
    public String orderDate;
    public String state;
    public List<StateChange> stateChange;
    public String externalId;
    public String projectId;
    public List<RelatedContactInformation> relatedContactInformation;
    public List<ProductOrderItem> productOrderItem;

    public class StateChange {
        public String state;
        public String changeDate;
    }

    public class RelatedContactInformation {
        public String emailAddress;
        public String name;
        public String number_x;
        public String numberExtension;
        public String organization;
        public String role;
    }

    public class ProductOrderItem {
        public String id;
        public String action;
        public String endCustomerName;
        public String relatedBuyerPON;
        public String requestedCompletionDate;
        public String agreementName;
        public BillingAccount billingAccount;
        public Product product;
        public GcIntegration x_gcIntegration;
    }

    public class BillingAccount {
        public String id;
    }

    
    public class GcIntegration {
        public String x_sfAccountId;
        public String x_sfContactId;
    }

    
    
    public class Product {
        public ProductOfferingQualificationItem productOfferingQualificationItem;
        public ProductOffering productOffering;
        public List<Place> place;
        public List<ProductRelationship> productRelationship;
    }

    public class ProductOfferingQualificationItem {
        public String id;
        public String productOfferingQualificationId;
    }

    public class ProductOffering {
        public String id;
    }

    public class Place {
        public GeographicAddress geographicAddress;
    }

    public class GeographicAddress {
        public String type;
        public String id;
        public List<FieldedAddressRepresentation> fieldedAddressRepresentation;
        public String role;
        public List<Contact> contact;
    }

    public class FieldedAddressRepresentation {
        public String streetType;
        public String streetName;
        public String streetNr;
        public String streetNrLast;
        public String city;
        public String stateOrProvince;
        public String postcode;
        public String countryCode;
        public List<SubUnit> subUnit;
        public String language;
    }

    public class SubUnit {
        public String subUnitType;
        public String subUnitNumber;
    }

    public class Contact {
        public String number_x;
        public String emailAddress;
        public String name;
    }

    public class ProductRelationship {
        public String relationshipType;
        public String id;
    }
}