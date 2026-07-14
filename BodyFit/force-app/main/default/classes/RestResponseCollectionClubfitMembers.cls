public class RestResponseCollectionClubfitMembers {
    public String next;
    public list<data> data;
    public String href;
    public class Membership{
        public String SaleDate;
        public String CancellationDate;
        public String StartDate;
        public String MinimumTermDate;
        public String Name;
        public String ExpiryDate;
        public Integer Id;
        public String Type;
    }
    public class data{
        public Contact Contact;
        public String FitnessPassportNumber;
        public String Barcode;
        public String DateOfBirth;
        public String Status;
        public String Gender;
        public String LastName;
        public String LastUpdatedUtcDateTime;
        public String FirstName;
        public Membership Membership;
        public String Number_x;
        public String Club;
    }
    public class Contact{
        public String Work;
        public String Home;
        public String Address;
        public Boolean OptOutSms;
        public String Suburb;
        public String Mobile;
        public String State;
        public Boolean OptOutEmail;
        public String Postcode;
        public String Email;
    }
}