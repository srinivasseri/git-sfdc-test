@isTest
public class UpdateProjectContactTest    {

    public static List<Project__c> mockProjectDataList;
    public static List<Payment__c> mockPaymentDataList; 
    public static List<Contact>    mockContactDataList;
    
    //create mock Contact data
    private static void createContactMockData()    {
        mockContactDataList = new List<Contact>();
        Contact person = new Contact(FirstName= 'TestMock First',
                                     LastName = 'TestMock Last');
        mockContactDataList.add(person);
        insert mockContactDataList;
        
    }
    
    //create mock Project data(two projects)
    private static void createProjectMockData()    {
        mockProjectDataList = new List<Project__c>();
        for (Integer i = 0; i<2; i++) {
            Project__c project = new Project__c(Name='TestMockProject - ' + i);
            mockProjectDataList.add(project);
        }
        insert(mockProjectDataList);
    }
    
    //create mock Payment data (4 payments)
    private static void createPaymentMockData()    {   
        //create Contact and Project mock data first
        createContactMockData();
        createProjectMockData();
            
        mockPaymentDataList = new List<Payment__c>();
        //create four payments assign two each to one project
        for (Integer i = 0; i<4; i++) {
            Payment__c pymnt = new Payment__c(
                                Name='MockTestPayment - ' + i,
                                Payment_Amount__c = 100,
                                Payment_Date__c = System.today() ,
                                Project__c = mockProjectDataList.get(i<2?0:1).ID,
                                Contact__c=mockContactDataList.get(0).ID);
            mockPaymentDataList.add(pymnt);
        }
        insert mockPaymentDataList;
    }
       
    public static testMethod void testPaymentInsert() {
        //create the Payment mock data first
        createPaymentMockData();
       
        List<Contact> contacts = fetchContactPayments();
        System.debug('****** fetchContacts after testPaymentInsert: ' + contacts);            
       
        System.assert(contacts.size()==1, 'There should be only one contact!');
        System.assert(contacts.get(0).Total_Amount__c==400, 'total amount should be 400!');
        System.assert(contacts.get(0).Recent_Payment__c==System.today(), 'recent payment date should be today!');      
    }
    
    public static testMethod void testPaymentUpdate() {
        //create Contact, Project and Payment mock data first
        createContactMockData();
        createProjectMockData();
        createPaymentMockData();
        
        for(Payment__c payment : mockPaymentDataList)   {
            payment.Payment_Amount__c  = 200;
            payment.Payment_Date__c = System.today() + 1;
        }
        update mockPaymentDataList;
        
        List<Contact> contacts = fetchContactPayments();
        System.debug('****** fetchContacts after testPaymentUpdate: ' + contacts);                        

        //there should be only 1 -- the trigger should not have created another
        System.assert(contacts.size()==1, 'There should be only one contact!');
        System.assert(contacts.get(0).Total_Amount__c==800, 'total amount should be 800!');
        System.assert(contacts.get(0).Recent_Payment__c==System.today()+1, 'recent payment date should be tomorrow!');
    }
    
    public static testMethod void testPaymentDelete() {
        //create the Payment mock data first
        createPaymentMockData();
       
        List<Payment__c> deletePaymentList = new List<Payment__c>();
        deletePaymentList.add(mockPaymentDataList.get(0));
        delete deletePaymentList;    
        
        List<Contact> contacts = fetchContactPayments();
        System.debug('****** fetchContacts after testPaymentInsert: ' + contacts);        
 
        System.assert(contacts.size()==1, 'There should be only one contact!');
        System.assert(contacts.get(0).Total_Amount__c==300, 'total amount should be 400!');
        System.assert(contacts.get(0).Recent_Payment__c==System.today(), 'recent payment date should be today!');  
    }
    
    private static List<Contact> fetchContactPayments(){
        return [SELECT Name,Total_Amount__c,Recent_Payment__c,
                    (
                        SELECT ID, Payment_Amount__c, Payment_Date__c From Payments__r
                    ) 
               FROM Contact where ID IN (SELECT Contact__c FROM Payment__c WHERE Name like 'MockTestPayment%')
               ];   
    }
    
} //End of Controller class