public class AvailabilityV2Response {

    public Boolean UPRNExists;
    public Boolean ReadyForSale;
    public Integer ClientJourney;
    public Boolean AvailableForPreOrder;

    public AvailabilityV2Response() {

        UPRNExists = false;
        ReadyForSale = false;
        ClientJourney = 0;
        AvailableForPreOrder = false;
    }
}