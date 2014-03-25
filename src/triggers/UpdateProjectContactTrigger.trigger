trigger UpdateProjectContactTrigger on Payment__c (after insert, after update,after delete) {

     UpdateProjectContact upc = new UpdateProjectContact(Trigger.new,Trigger.oldMap,Trigger.isUpdate,Trigger.isDelete);
     
     if(Trigger.isInsert || Trigger.isUpdate){
         upc.insertAfterBulk();
     }
       
     if(Trigger.isDelete){
          upc.deleteBulk();
     }
     
     upc.updateProjectContactData();
}