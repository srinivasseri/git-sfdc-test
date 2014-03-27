public with sharing class TestPageController {
	public List<Question> questionList {get;set;} 
	    
	    public class question {
	    	public string text {get;set;} 
	    	public string choice {get;set;} 
	    }
	    
	    public string choice1 {get;set;}
	    public string choice2 {get;set;}
	    public string choice3 {get;set;}        
	    public string choice4 {get;set;}
	        
	    public testPageController () { 
	    	choice1 = 'always';
	    	choice2 = 'frequently';
	        choice3 = 'sometimes';
	        choice4 = 'never';
	        
	        questionList = new List<Question> ();
	        for (integer i = 0; i < 1; i++) {
	        	question q = new Question();
	        	q.text = 'question ' + i;
	        	questionList.add(q); 
	        }        
	    }
	    
	    public pageReference showValues() {
	    	
	    	for (question q:questionList) {
	    		System.Debug('Question is ' + q);
	    		System.Debug('Question is ' + q.choice);
	    	}
	    	return null; 
	    	
	    }
	}