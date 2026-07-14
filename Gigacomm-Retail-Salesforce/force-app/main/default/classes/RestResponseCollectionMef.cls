public class RestResponseCollectionMef {
    
    
    public class PostPOQResponseBody{
        
        public String id;	//6fe9ba4e-e5ca-49e1-9fa4-b2d70015b758
        public String href;	//
        public String creationDate;	//2025-05-08T01:19:03.975915Z
        public String state;	//done
        public StateChange[] stateChange;
        public RelatedContactInformation[] relatedContactInformation;
        public ProductOfferingQualificationItem[] productOfferingQualificationItem;
        public Integer statusCode;
    }
    
    public class StateChange {
        public String state;	//done
        public String changeDate;	//2025-05-08T01:19:03.975915Z
    }
    
    public class RelatedContactInformation {
    }
    
    public class ProductOfferingQualificationItem {
        public String id;	//1
        public String state;	//
        public String qualificationResult;	//qualified
        public StateChange[] stateChange;
        public String serviceabilityConfidence;	//Green
        public InstallationInterval installationInterval;
        public String guaranteedUntilDate;	//2025-05-08T01:19:03.975915Z
        public AlternateProductOfferingProposal[] alternateProductOfferingProposal;
        public String deliveryType;	//onNetWithBuild
    }
    
    public class InstallationInterval {
        public Integer amount;	//5
        public String units;	//day
    }
    
    public class AlternateProductOfferingProposal {
        public String id;	//27b88087-d24f-4316-9376-b2d70015b759
        public String serviceabilityConfidence;	//Green
        public InstallationInterval installationInterval;
        public String guaranteedUntilDate;	//2025-05-08T01:19:03.9770193Z
        public AlternateProduct alternateProduct;
        public String deliveryType;	//onNetWithBuild
    }
    
    public class AlternateProduct {
        public ProductOffering productOffering;
    }
    
    public class ProductOffering {
        public String id;	//SKU1001160
    }
    
    
    //Response for Mef Get Order Status
    
    
    public class GetOrderStatusResponseBody{
        public String id;	    //OD-5936
        public String orderDate;	    //2025-09-18T10:48:44.1633438Z
        public String completionDate;
        public String expectedCompletionDate;	    //2025-09-23T11:00:00+00:00
        public String state;	    //completed
        public List<stateChange> stateChange;
        public String externalId;	    //GCD0001494
        public List<note> note;
        public List<productOrderItem> productOrderItem;
        
        
    }
    
    public class note {
        public String author;	    //SELLER
        public String date_x;	    //2025-09-22T01:13:14Z
        public String id;	    //b9635a6b-7c5e-4ab5-a26c-5f95db84ce6d
        public String source;	    //SELLER
        public String text;	    //22/09 SB- Confirmed with BM
        
    }
    
    public class productOrderItem {
        public String id;	
        public product product;
    }
    
    public class product {
        public String id;	    //INH0107623
    }
    
    
}