/*
@Author: Chad Lazarra (Bricoleur Technology)
@Date: 
@Desc:
@History:
[1] CLAZARRA 12-Oct-27 : Created
*/
public class RestResponseCollectionClubfit { 
    
    public class ProspectsReponseBody{
        public list<data> data;
        public String href;
        public String next;
    }
    
    public class Source{
        public String Name;
        public Integer Id;
    }
    
    public class SalesPerson{
        public String FirstName;
        public String LastName;
        public String Email;
        public Integer Id;
    }
    
    public class data{
        public Source Source;
        public ContactMethod ContactMethod;
        public String Gender;
        public String TrialStartDate;
        public String DateOfBirth;
        public String TrialEndDate;
        public String Barcode;
        public String CreatedDateUtc;
        public String Status;
        public String SourcePage;
        public String LastName;
        public SalesPerson SalesPerson;
        public String FirstName;
        public Contact Contact;
        public String Number_x;
    }
    
    public class ContactMethod{
        public String Name;
        public Integer Id;
    }
    
    public class Contact{
        public String Suburb;
        public String State;
        public String Postcode;
        public String Address;
        public Boolean OptOutEmail;
        public String Mobile;
        public Boolean OptOutSms;
        public String Email;
    }
    
    public class AccessTokenResponse {
        public String AccessToken;
        public Integer ExpiresIn;
        public String TokenType;
    }
    
    
    
}