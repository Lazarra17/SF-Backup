/**
 * @description Invocable class that generates document templates for NAO
 * @author Bricoleur Technologies
 * @date Aug-15-2024
 */public class Invoke_DocTemplateGen {

    /**
    * @description Request Parameters
    * @author Bricoleur Technologies
    * @date Aug-15-2024
    */
    public class Request {
        @InvocableVariable(required=true)
        public Id recordId;

        @InvocableVariable(required=true)
        public List<nao__Document_Template__c> docTemplates;

    }
     
	/**
    * @description response
    * @author Bricoleur Technologies
    * @date Aug-15-2024
    */
    public class Response {
        @InvocableVariable
        public Id contentDocumentId; 
        @InvocableVariable
        public String errorMsg; 
    }

    /** 
     * @description Logic for invocable apex
     * @param requestList
    */
    @InvocableMethod(label='Generate and Attach PDF' description='Generates a PDF from a Visualforce page and attaches it to a record')
    public static void generateAndAttachPDF(List<Request> requestList) {
        // Enqueue the job to process asynchronously
        DocTemplateGen_Queueable job = new DocTemplateGen_Queueable(requestList);
        System.enqueueJob(job);
    }
}