/*
 * Author: 			Alfonso Maquilan
 * Created Date: 	May. 06, 2021
 * Description: 	Collection class for Xero API Requests
 * Test Class: 		N/A
 * History: 		May 06, 2021 - Creation
 */
public class XeroAPIRequestCollection 
{
	//Post Contact
    public class PostRequestContact
    {
        public List<Event> events;
        public Integer firstEventSequence;
        public Integer lastEventSequence;
        public String entropy;
    }
    
    public class Event
    {
        public String resourceUrl;
        public String resourceId;
        public String eventDateUtc;
        public String eventType;
        public String eventCategory;
        public String tenantId;
        public String tenantType;
    }
}