public class Invoke_DocTemplateGen_Batch {
    
    public class Request {
        @InvocableVariable(required=true)
        public Id recordId;
        
        @InvocableVariable(required=true)
        public nao__Document_Template__c docTemplate;
        
        @InvocableVariable(description='List of Email Address Recipients')
        public List<String> setToAddrList;
        @InvocableVariable(description='List of Email Address CCs')
        public List<String> ccList;

        @InvocableVariable(description='Email Template Id is populated.  Don\'t populate the subject and body ')
        public String emailTemplateId;
        @InvocableVariable
        public String orgWideEmailId;
        @InvocableVariable
        public String senderDisplayName;
        @InvocableVariable(description='Email Template Id is populated.  Don\'t populate the subject and body ')
        public String subject;
        @InvocableVariable(description='Email Template Id is populated.  Don\'t populate the subject and body ')
        public String body;
        @InvocableVariable
        public String replyTo;
        @InvocableVariable(description='User/Lead/Contact id')
        public String targetObjectId;
        @InvocableVariable(description='Related Record Id of the corresponding Email Template object')
        public String whatId;
        @InvocableVariable
        public Boolean saveAsActivity;
        
        
    }  
    
    public class Response {
        @InvocableVariable
        public ContentVersion contentVersionId; 
        @InvocableVariable
        public String errorMsg; 
    }
    
    @InvocableMethod(label='Generate and Send PDF' description='Generates and Send a PDF from a Visualforce page and attaches it to a record')
    public static List<Response> generateAndAttachPDF(List<Request> requestList) {
        List<Response> responses = new List<Response>();
        Response res = new Response();
        
        DocTemplateGen_Batch job = new DocTemplateGen_Batch(requestList);
        System.enqueueJob(job);
        

        
        return responses;
    }
    
    
}