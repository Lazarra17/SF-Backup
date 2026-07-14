public class paymentResponseWrapper {
    public String href;
    public String next;
    public List <payment> data;
    
    public class payment{
        public string Id;
        public string Numbers;
        public Decimal Amount;
        public DateTime PaymentDate;
        public string PaymentType;  
        public string Response;
        public string PaymentDescription;
        public PaymentForReference PaymentForReference;
        public FeeBreakdown FeeBreakdown; 
        public Refund Refund;
    }
    
    public class PaymentForReference{
        public string Id;
        public string Name;
    }
    
    public class FeeBreakdown{
        public Decimal AccessCardFee;
        public Decimal AddOnAmount;
        public Decimal Adjustment;
        public Decimal ArrearsFee;
        public Decimal CancellationLateFee;
        public Decimal CardSurchargeFee;
        public Decimal ClassNoShowFee;
        public Decimal CrecheClassNoShowFee;
        public Decimal DishonourFee;
        public Decimal JoiningFee;
        public Decimal MaintenanceFee;
        public Decimal PosTransaction;
        public Decimal Prorata;
        public Decimal PtNoShowFee;
        public Decimal SetupFee;
        public Decimal SubscriptionFee;
        public Decimal SuspensionFee;
        public Decimal TransactionFee;
    }
    
    public class Refund{
        public Boolean IsRefund;
        public string RefundedPaymentId;
    }
    
}