/*
* @Author: Bricoleur Technology
* @Date: June 19, 2026
* @Desc: Fetches CustomerPayments from MYOB and updates nao__Invoice__c records
*        with Amount Paid, Balance Due Amount, and Last Payment Date.
*/
public class MYOB_GetPaymentsBatch implements Database.Batchable<MYOB_RestResponseCollection.CustomerPayment>, Database.AllowsCallouts, Database.Stateful
{

    public String paramString;

    public MYOB_GetPaymentsBatch(String params) {
        paramString = params;
    }

    public Iterable<MYOB_RestResponseCollection.CustomerPayment> start(Database.BatchableContext context)
    {
        MYOB_API_Setting__mdt apiSettings = [SELECT Client_ID__c, Endpoint__c, Company_File_ID__c
                                             FROM MYOB_API_Setting__mdt
                                             WHERE DeveloperName = 'Default'];
        String clientID = apiSettings?.Client_ID__c;
        String endpoint = apiSettings?.Endpoint__c;
        String companyFileID = apiSettings?.Company_File_ID__c;

        MYOBProcessingSettings__c myobSettings = MYOBProcessingSettings__c.getOrgDefaults();

        if (apiSettings == NULL || endpoint == NULL || myobSettings?.Payment_Sync_Date_Time__c == NULL) {
            return new List<MYOB_RestResponseCollection.CustomerPayment>();
        }

        String modifiedSince = getUTCDateTime(myobSettings.Payment_Sync_Date_Time__c);

        Map<String, String> requestHeader = MYOB_RequestUtilities.ConstructRequestHeaders(clientID);

        String lastModifiedParam = EncodingUtil.urlEncode(
            MYOB_CONSTANTS.INTEGRATION_MYOB_FILTER_LASTMODIFIED + MYOB_CONSTANTS.INTEGRATION_MYOB_FILTER_DATETIME +
            MYOB_CONSTANTS.GENERIC_SINGLE_QUOTE + modifiedSince + MYOB_CONSTANTS.GENERIC_SINGLE_QUOTE, 'UTF-8');

        if (paramString == '') paramString = MYOB_CONSTANTS.INTEGRATION_MYOB_FILTER + lastModifiedParam;

        System.debug('paramString: ' + EncodingUtil.urlDecode(paramString, 'UTF-8'));

        HttpResponse getResponse = RestHandler.ExecuteRequest(requestHeader,
            endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CUSTOMER_PAYMENT + '?' + paramString,
            null, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_GET);

        String getResponseBodyString = getResponse?.getBody();
        System.debug('getResponse: ' + getResponseBodyString);

        Utilities.CreateRequestResponseLog(MYOB_CONSTANTS.INTEGRATION_REST_METHOD_GET, null, getResponse?.getBody(),
            getResponse?.getStatusCode(), MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CUSTOMER_PAYMENT + '?' + paramString);

        getResponseBodyString = getResponseBodyString.replaceAll('_x', '');

        if (!MYOB_RequestUtilities.CheckResponseBodyValidity(getResponse?.getStatusCode(), getResponseBodyString)) {
            paramString = '';
            return new List<MYOB_RestResponseCollection.CustomerPayment>();
        }

        MYOB_RestResponseCollection.CustomerPaymentResponseBody paymentResponse =
            (MYOB_RestResponseCollection.CustomerPaymentResponseBody) JSON.deserialize(
                getResponseBodyString, MYOB_RestResponseCollection.CustomerPaymentResponseBody.class);

        if (paymentResponse == NULL) {
            paramString = '';
            return new List<MYOB_RestResponseCollection.CustomerPayment>();
        } else if (paymentResponse.Items?.size() > 0) {
            paramString = paymentResponse.NextPageLink;
            paramString = paramString?.substringAfter('?');
            return paymentResponse.Items;
        } else {
            paramString = '';
            return new List<MYOB_RestResponseCollection.CustomerPayment>();
        }
    }

    public void execute(Database.BatchableContext context, List<MYOB_RestResponseCollection.CustomerPayment> paymentList)
    {
        Set<String> invoiceUIDs = new Set<String>();
        Map<String, Date> invoiceLastPaymentDateMap = new Map<String, Date>();

        for (MYOB_RestResponseCollection.CustomerPayment payment : paymentList) {
            Date paymentDate = getDateValue(payment.Date_x);
            if (payment.Invoices == NULL) continue;
            for (MYOB_RestResponseCollection.CustomerPaymentInvoiceLine line : payment.Invoices) {
                String invoiceUID = line.Sale?.UID;
                if (String.isBlank(invoiceUID)) continue;
                invoiceUIDs.add(invoiceUID);
                if (paymentDate != NULL) {
                    if (!invoiceLastPaymentDateMap.containsKey(invoiceUID) ||
                        paymentDate > invoiceLastPaymentDateMap.get(invoiceUID)) {
                        invoiceLastPaymentDateMap.put(invoiceUID, paymentDate);
                    }
                }
            }
        }

        if (invoiceUIDs.isEmpty()) return;

        Map<String, MYOB_Invoice__c> myobInvoiceMap = new Map<String, MYOB_Invoice__c>();
        for (MYOB_Invoice__c inv : [SELECT Id, MYOB_UID_bric__c, TotalAmount_bric__c, Balance_Due_Amount_bric__c, Last_Payment_Date_bric__c
                                    FROM MYOB_Invoice__c
                                    WHERE MYOB_UID_bric__c IN :invoiceUIDs AND MYOB_UID_bric__c != NULL]) {
            myobInvoiceMap.put(inv.MYOB_UID_bric__c, inv);
        }

        Map<String, nao__Invoice__c> naoInvoiceMap = new Map<String, nao__Invoice__c>();
        for (nao__Invoice__c inv : [SELECT Id, External_Accounting_Id__c, nao__Amount_Paid__c, Balance_Due_Amount__c, Last_Payment_Date__c
                                    FROM nao__Invoice__c
                                    WHERE External_Accounting_Id__c IN :invoiceUIDs]) {
            naoInvoiceMap.put(inv.External_Accounting_Id__c, inv);
        }

        List<nao__Invoice__c> invoicesToUpdate = new List<nao__Invoice__c>();

        for (String uid : invoiceUIDs) {
            nao__Invoice__c naoInv = naoInvoiceMap.get(uid);
            if (naoInv == NULL) continue;

            MYOB_Invoice__c myobInv = myobInvoiceMap.get(uid);
            if (myobInv != NULL) {
                if (myobInv.TotalAmount_bric__c != NULL && myobInv.Balance_Due_Amount_bric__c != NULL) {
                    naoInv.nao__Amount_Paid__c = myobInv.TotalAmount_bric__c - myobInv.Balance_Due_Amount_bric__c;
                }
                naoInv.Balance_Due_Amount__c = myobInv.Balance_Due_Amount_bric__c;
                if (myobInv.Last_Payment_Date_bric__c != NULL) {
                    naoInv.Last_Payment_Date__c = myobInv.Last_Payment_Date_bric__c;
                }
            }

            Date paymentDate = invoiceLastPaymentDateMap.get(uid);
            if (paymentDate != NULL && (naoInv.Last_Payment_Date__c == NULL || paymentDate > naoInv.Last_Payment_Date__c)) {
                naoInv.Last_Payment_Date__c = paymentDate;
            }

            invoicesToUpdate.add(naoInv);
        }

        if (!invoicesToUpdate.isEmpty()) {
            try {
                Database.update(invoicesToUpdate, false);
            } catch (Exception e) {
                Utilities.CreateExceptionLog(e, 'MYOB_GetPaymentsBatch');
            }
        }
    }

    public void finish(Database.BatchableContext context)
    {
        System.debug('finish paramString: ' + paramString);

        if (paramString != '' && paramString != null) {
            Database.executeBatch(new MYOB_GetPaymentsBatch(paramString));
        } else {
            MYOBProcessingSettings__c settings = MYOBProcessingSettings__c.getOrgDefaults();
            if (settings != NULL) {
                settings.Payment_Sync_Date_Time__c = System.now();
                Database.update(settings);
            }

            List<CronTrigger> scheduledJobs = [SELECT Id FROM CronTrigger
                                               WHERE CronJobDetail.Name LIKE '%MYOB_PaymentBatchSchedulable%'];
            for (CronTrigger job : scheduledJobs) {
                try {
                    System.abortJob(job.Id);
                } catch (Exception e) {
                    System.debug('Job already processed or removed: ' + e.getMessage());
                }
            }
            Datetime nextRun = System.now().addMinutes(15);
            String cronStr = nextRun.format('s m H d M ? yyyy');
            System.schedule('MYOB_PaymentBatchSchedulable', cronStr, new MYOB_PaymentBatchSchedulable());
        }
    }

    public Date getDateValue(String dt) {
        if (dt == '' || dt == NULL) return NULL;
        return Date.valueOf(dt);
    }

    public String getUTCDateTime(DateTime dt) {
        Datetime GMTDate = Datetime.newInstance(dt.year(), dt.month(), dt.day(), dt.hour(), dt.minute(), dt.second());
        return GMTDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss');
    }

}
