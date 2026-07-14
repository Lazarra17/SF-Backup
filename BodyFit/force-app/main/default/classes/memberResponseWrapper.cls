public class memberResponseWrapper {
    public String href;
    public String next;
    public List<Member> data;

    public class Member {
        public String NumberData;
        public String FirstName;
        public String LastName;
        public String Status;
        public String Barcode;
        public String FitnessPassportNumber;
        public String DateOfBirth;
        public String Gender;
        public String LastUpdatedUtcDateTime;
        public Contact Contact;
        public Membership Membership;
    }

    public class Contact {
        public String Email;
       // public Integer Home;
       // public Integer Work;
        public String Mobile;
        public String Address;
        public String Suburb;
        public String State;
        public String Postcode;
        public Boolean OptOutEmail;
        public Boolean OptOutSms;
    }

    public class Membership {
        public Integer Id;
        public String Name;
        public String StartDate;
        public String SaleDate;
       // public String CancellationDate;
       // public String MinimumTermDate;
        public String ExpiryDate;
        public String Type;
    }
}