public class ProjectContactController {
    List<Contact> contacts = new List<Contact>();

    public Decimal paymentAmount{get;set;}
    public Date paymentDate{get;set;}
   
    public List<Contact> getContacts() {
  
        contacts= [SELECT Name,Total_Amount__c,Recent_Payment__c,
                   (
                       SELECT Payment_Amount__c, Payment_Date__c From Payments__r order by Payment_Date__c desc
                   ) 
                   FROM Contact where ID IN (SELECT Contact__c FROM Payment__c)
                  ];
                  
        return contacts;
    }
    
    public PageReference Save()  {
        System.debug('****** updated contacts, before insert: ' + contacts.get(1).Payments__r);  
        List<Payment__c> updatePaymentList = new List<Payment__c>();
        for(Contact c : contacts)   {
            updatePaymentList.addAll(c.Payments__r);    
        }
        update updatePaymentList;
        
        return null;  
    }
}