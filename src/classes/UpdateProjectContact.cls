public Class UpdateProjectContact{

   List<Payment__c> newPaymentList;
   Map<Id,Payment__c> oldPaymentMap;
   Boolean isUpdate;
   Boolean isDelete;
   Map<Id,List<Payment__c>> contactPaymentMap = new Map<Id,List<Payment__c>>();
   Map<Id,List<Payment__c>> projectPaymentMap = new Map<Id,List<Payment__c>>();
   Map<Id,Date> paymentDateMap = new Map<Id,Date>();
   Map<Id,Contact> resultContactMap = new Map<Id,Contact>();
   Map<Id,Project__c> resultProjectMap = new Map<Id,Project__c>();
   List<Payment__c> paymentList;
   
  
   public UpdateProjectContact(List<Payment__c> newList,Map<Id,Payment__c> oldMap,Boolean pUpdate,Boolean pDelete){
       newPaymentList = newList;
       oldPaymentMap = oldMap;
       isUpdate = pUpdate;
       isDelete = pDelete;
   }
   
   /**
   * Since we need to Update Contact and Project objects when Payment is inserted,
   * we need construct the structures of the Maps one for Contact another for Project
   *
   * contactPaymentMap<ID, List<Payment__c>> and
   * projectPaymentMap<ID, List<Payment__c>>
   *
   */ 
   public void insertAfterBulk(){
       for(Payment__c payment : newPaymentList){
          if(payment.Contact__c != null){
              if(contactPaymentMap.containsKey(payment.Contact__c)){
                  contactPaymentMap.get(payment.Contact__c).add(payment);
              }
              else{
                  paymentList = new List<Payment__c>();
                  paymentList.add(payment);
                  contactPaymentMap.put(payment.Contact__c,paymentList);
              }
          }
          if(payment.Project__c != null){
             if(projectPaymentMap.containsKey(payment.Project__c)){
                  projectPaymentMap.get(payment.Project__c).add(payment);
              }
              else{
                  paymentList = new List<Payment__c>();
                  paymentList.add(payment);
                  projectPaymentMap.put(payment.Project__c,paymentList);
              }
          }
       }      
   }
   
   public void deleteBulk(){
       Payment__c payment;
       for(Id id : oldPaymentMap.keySet()){
           payment = oldPaymentMap.get(id);
           if(payment.Contact__c != null){
              if(contactPaymentMap.containsKey(payment.Contact__c)){
                  contactPaymentMap.get(payment.Contact__c).add(payment);
              }
              else{
                  paymentList = new List<Payment__c>();
                  paymentList.add(payment);
                  contactPaymentMap.put(payment.Contact__c,paymentList);
              }
          }
          if(payment.Project__c != null){
             if(projectPaymentMap.containsKey(payment.Project__c)){
                  projectPaymentMap.get(payment.Project__c).add(payment);
              }
              else{
                  paymentList = new List<Payment__c>();
                  paymentList.add(payment);
                  projectPaymentMap.put(payment.Project__c,paymentList);
              }
          }
       }  
   }
   
   /**
   * main roll up logic resides here, it depends on whether it updates or deletes
   * - updating total payment and calculate most recent payment dates on Contact object
   * - updating total payment amount on Project object
   */
   public void updateProjectContactData(){
       
       System.debug('Before Conversion contactPaymentMap -------------------  '+contactPaymentMap);
       System.debug('Before Conversion projectPaymentMap -------------------  '+projectPaymentMap);
       
       convertContactMap();
       System.debug('After Conversion contactPaymentMap -------------------  '+resultContactMap);

       
       List<Contact> resultContactList = new List<Contact>();
       if(resultContactMap != null && resultContactMap.size() > 0){
           Contact rContact;
           for(Payment__c payment : [select Id, Payment_Date__c,Contact__c from Payment__c where Contact__c IN :resultContactMap.keySet() order by payment_date__c desc]){
               
               if(!paymentDateMap.containsKey(payment.Contact__c)){
                   paymentDateMap.put(payment.Contact__c,payment.Payment_Date__c);
               }
           }
           
           for(Contact cntct : [select Id,Recent_Payment__c,Total_Amount__c from Contact where Id IN :resultContactMap.keySet()]){
              rContact = resultContactMap.get(cntct.Id);
              Decimal rAmount = (rContact.Total_Amount__c == null)?0:rContact.Total_Amount__c;
              Decimal cAmount = (cntct.Total_Amount__c == null)?0:cntct.Total_Amount__c;

              if((rAmount !=  cAmount) || (cntct.Recent_Payment__c != rContact.Recent_Payment__c)){
                  if(isdelete){
                      cntct.Total_Amount__c = cAmount - rAmount;
                  }
                  else{
                      cntct.Total_Amount__c = cAmount + rAmount;
                  }
                  if(isUpdate || isDelete){
                      cntct.Recent_Payment__c = paymentDateMap.get(cntct.Id);
                  }
                  else{
                      cntct.Recent_Payment__c = rContact.Recent_Payment__c;
                  }
                  resultContactList.add(cntct);
              }
           }
        }
       
       convertProjectMap();
       System.debug('After Conversion projectPaymentMap -------------------  '+resultProjectMap);
       List<Project__c> resultProjectList = new List<Project__c>();
       if(resultProjectMap != null && resultProjectMap.size() > 0){
           Project__c prjct;
           for(Project__c project : [select Id,Total_Amount__c from Project__c where Id IN :resultProjectMap.keySet()]){
               prjct = resultProjectMap.get(project.Id);
               Decimal prjctAmount = (prjct.Total_Amount__c == null)?0:prjct.Total_Amount__c;
               Decimal projectAmount = (project.Total_Amount__c == null)?0:project.Total_Amount__c;

               if(prjctAmount != projectAmount){
                   
                   if(isdelete){
                       project.Total_Amount__c = projectAmount - prjctAmount;
                   }
                   else{
                       project.Total_Amount__c = projectAmount + prjctAmount;
                   }
                   resultProjectList.add(project);
               }
           }
       }
       
       if(resultContactList != null && resultContactList.size() > 0){
           update resultContactList;
       }
       if(resultProjectList != null && resultProjectList.size() > 0){
           update resultProjectList;
       }  
   }
     
   /**
   * Utilty method to convert contact map to result contact Map
   */
   public void convertContactMap(){
       Contact cntct;
       List<Payment__c> paymentList;     
           for(Id contactId : contactPaymentMap.keySet()){             
               paymentList = contactPaymentMap.get(contactId);
               for(Payment__c pymt : paymentList){
                   if(resultContactMap.containsKey(contactId)){
                       cntct = resultContactMap.get(contactId);
                       if(isUpdate){
                           cntct.Total_Amount__c = cntct.Total_Amount__c + (pymt.Payment_Amount__c - oldPaymentMap.get(pymt.Id).Payment_Amount__c);
                       }
                       else{
                           cntct.Total_Amount__c = cntct.Total_Amount__c + pymt.Payment_Amount__c;
                       }

                       if(pymt.Payment_Date__c > cntct.Recent_Payment__c){
                           cntct.Recent_Payment__c = pymt.Payment_Date__c;
                       }
                   }
                   else{
                       cntct = new Contact();
                       if(isUpdate){
                           cntct.Total_Amount__c = pymt.Payment_Amount__c - oldPaymentMap.get(pymt.Id).Payment_Amount__c;
                       }
                       else{
                           cntct.Total_Amount__c = pymt.Payment_Amount__c;
                       }
                       cntct.Recent_Payment__c = pymt.Payment_Date__c;
                       resultContactMap.put(contactId,cntct);
                   }
               }
           }
    }
   
   /**
   * Utilty method to convert Project map to result Project Map
   */
   public void convertProjectMap(){
       Project__c prjct;
       List<Payment__c> paymentList;
      
           for(Id prjctId : projectPaymentMap.keySet()){
               
               paymentList = projectPaymentMap.get(prjctId);
               for(Payment__c pymt : paymentList){
                   if(resultProjectMap.containsKey(prjctId)){
                       prjct = resultProjectMap.get(prjctId);
                       if(isUpdate){
                           prjct.Total_Amount__c = prjct.Total_Amount__c + (pymt.Payment_Amount__c - oldPaymentMap.get(pymt.Id).Payment_Amount__c);
                       }
                       else{
                           prjct.Total_Amount__c = prjct.Total_Amount__c + pymt.Payment_Amount__c;
                       }
                   }
                   else{
                       prjct = new Project__c();
                       if(isUpdate){
                            prjct.Total_Amount__c = pymt.Payment_Amount__c - oldPaymentMap.get(pymt.Id).Payment_Amount__c;
                       }
                       else{
                           prjct.Total_Amount__c = pymt.Payment_Amount__c;
                       }
                       
                       resultProjectMap.put(prjctId,prjct);
                   }
               }
           }
    } 
} //end of class