public class GigaOpportunityRequestWrapper {

    public String externalId;
    public String projectId;
    public List<RelatedContactInformation> relatedContactInformation;
    public String requestedCompletionDate;
    public List<ProductOrderItem> productOrderItem;

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
        public BillingAccount billingAccount;
        public GcIntegration x_gcIntegration;
        public List<ProductOrderItemRelationship> productOrderItemRelationship;
        public Product product;
        public RequestedItemTerm requestedItemTerm;
    }

    public class BillingAccount {
        public String id;
    }

    public class GcIntegration {
        public String x_sfAccountId;
        public String x_sfContactId;
    }

    public class ProductOrderItemRelationship {
        public String id;
        public String relationshipType;
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
        public String id;
        public List<FieldedAddressRepresentation> fieldedAddressRepresentation;
        public String role;
        public List<Contact> contact;
        public string language;
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

    public class RequestedItemTerm {
        public Duration duration;
        public String endOfTermAction;
        public String name;
    }

    public class Duration {
        public Integer amount;
        public String units;
    }
}