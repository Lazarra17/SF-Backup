/*
@Author: Chad Lazarra (Bricoleur Technology)
@Date: 
@Desc:
@History:
[1] CLAZARRA 12-Sept-25 : Created
*/
public class RestRequestCollectionMeta {
    
    public List<Data> data;
    
    public class Data {
        public String action_source;	//website
        public String event_name;	//Lead Converted
        public Long event_time;	//1757636936 time stamp
        public user_data user_data;
        public custom_data custom_data;
        
    }
    public class custom_data {
        public String event_source;	//crm
        public String lead_event_source;	//Salesforce
    }
    public class user_data {
        public Long lead_id;	//2828406384023322
        public String fn;	//FirstName
        public String ln;	//LastName
        public String em;	//Email
        public String ph;	//Phone
        public String db;	//Date of Birth
        public String ct;	//City
        public String st;	//State
        public String zp;	//Zipcode
        public String country; 
        public String external_id; //Opportunity Id	
    }
    
    
}