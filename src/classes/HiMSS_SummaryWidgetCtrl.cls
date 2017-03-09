public with sharing class HiMSS_SummaryWidgetCtrl {
	public static String WARNING_MESSAGE 	    = 'Your account has overdue invoices. Please pay the balance now or set up a payment plan to avoid becoming delinquent.\n If you have any questions about the bill, please contact the Customer Service Center at ' + Label.Customer_Service_Center_Phone + '.';
	public static String DELINQUENT_MESSAGE     = 'This account has delinquent invoices. Delinquent invoices will be sent to a collection agency if payment arrangements are not made within the next 30 days. Please pay the balance now or set up a payment plan.'; 
	public static String PASTDUE_MESSAGE        = ' We have not received your latest payment plan installment. Please pay your previous installment amount now or pay your account in full to avoid payment plan cancellation.'; 
	public static String PASTDUE_MANUAL_MESSAGE = ' We have not received your latest payment plan installment. Please pay your previous installment amount now or pay your account in full to avoid payment plan cancellation. If you have any questions about the bill, call the Customer Service Center at ' + Label.Customer_Service_Center_Phone + '.';
	public static String ERROR_MESSAGE		    = ' Your latest payment plan installment failed. Please update your payment method or pay your previous installment amount now to keep your account current.';
	public static String DUE_STATUS  	  	    = 'Due';
	public static String OVERDUE_STATUS  	    = 'Overdue';
	public static String DELINQUENT_STATUS      = 'Delinquent';
	public static String PAYMENT_PLAN_STATUS    = 'On Payment Plan';
	public static String PLAN_STANDING_ERROR    = 'In Error';
	public static String PLAN_STANDING_GOOD     = 'Good standing';

	@AuraEnabled
	public static List<GuarantorWrapper> getAllHeaderInfo(String getNewUser) {
		List<GuarantorWrapper> guarantorWrapperList = new List<GuarantorWrapper>();
		HttpResponse res = HiMSS_SummaryWidgetCtrl.query(getNewUser);
		if (res.getStatus() == 'OK' && ! String.isEmpty(res.getBody())) {
			List<Guarantor> portalGuarantorList = (List<Guarantor>) JSON.deserialize(
	        	res.getBody(), List<Guarantor>.class
	    	);

	    	for (Guarantor portalGuarantor : portalGuarantorList) {
	    		guarantorWrapperList.add(new GuarantorWrapper(portalGuarantor));
	    	}
		}

		return guarantorWrapperList;
	}

	private static HttpResponse query(String getNewUser) {
		HttpRequest req = new HttpRequest(); 		
		req.setMethod('GET');
		req.setEndpoint('https://portal-sirono.cs18.force.com/guarantor/services/apexrest/SummaryWidget?getNewUser=' + getNewUser);
		
		Http http = new Http();
		HttpResponse res = http.send(req);
		    	
		return res;
	}

	public class GuarantorWrapper {
		@AuraEnabled public Guarantor.GuarantorUser 	grtUser 				{get;set;}
		@AuraEnabled public Guarantor.GuarantorContact 	contact 				{get;set;}
		@AuraEnabled public Guarantor.Invoice 			invoiceOverdue 			{get;set;}
		@AuraEnabled public String 						messageInfo 			{get;set;}
		@AuraEnabled public Guarantor.PaymentPlan 		paymentPlan 			{get;set;}
		@AuraEnabled public Integer 					newEstimatesCount	 	{get;set;}
		@AuraEnabled public Boolean 					version2 				{get;set;}
		@AuraEnabled public Boolean 					version3 				{get;set;}
		@AuraEnabled public Boolean 					version4 				{get;set;}
		@AuraEnabled public Boolean 					isInstallAmountView 	{get;set;}

		public GuarantorWrapper(Guarantor portalGuarantor) {
			this.messageInfo = '';
	    	this.grtUser = portalGuarantor.grtUser;

	    	if (portalGuarantor.grtUser.contactId != null) {
	    		this.contact = portalGuarantor.grtContact;
	    		this.invoiceOverdue = portalGuarantor.grtInvoice;
	    		this.paymentPlan = portalGuarantor.grtPaymentPlan;
	    		this.newEstimatesCount = portalGuarantor.newEstimatesCount;

				if (contact.status == OVERDUE_STATUS) {
					this.messageInfo = WARNING_MESSAGE;
				} else if (contact.status == DELINQUENT_STATUS) {
					this.messageInfo = DELINQUENT_MESSAGE;
				}
				if (this.paymentPlan != null && (paymentPlan.isActive && paymentPlan.paymentPlanStanding == 'Past Due' && paymentPlan.planType == 'Automatic')) {
					this.messageInfo += PASTDUE_MESSAGE;
				}
				if (this.paymentPlan != null && (paymentPlan.isActive && paymentPlan.paymentPlanStanding == 'Past Due' && paymentPlan.planType == 'Manual')) {
					this.messageInfo += PASTDUE_MANUAL_MESSAGE;
				}
				if (this.paymentPlan != null && (paymentPlan.isActive && paymentPlan.planType == 'Automatic' && paymentPlan.paymentPlanStanding == 'In Error')) {
					this.messageInfo += ERROR_MESSAGE;
				}

				this.version2 = ((this.contact.status == 'Due' || this.contact.status == 'Overdue' 
					|| this.contact.status == 'Delinquent') && this.contact.addToPaymentPlan == false) ? true : false;
				this.version3 = ((((this.contact.status == 'Due' || this.contact.status == 'Overdue' 
					|| this.contact.status == 'Delinquent') && this.contact.addToPaymentPlan == true) 
						|| this.contact.status == 'On Payment Plan') && (this.paymentPlan != null && this.paymentPlan.paymentPlanStanding == 'Good Standing')) ? true : false;
				this.version4 = ((((this.contact.status == 'Due' || this.contact.status == 'Overdue' 
					|| this.contact.status == 'Delinquent') && this.contact.addToPaymentPlan == true) 
						|| this.contact.status == 'On Payment Plan') && (this.paymentPlan != null && this.paymentPlan.paymentPlanStanding != 'Good Standing')) ? true : false;
				this.isInstallAmountView = (((this.contact.status == 'Due' || this.contact.status == 'Overdue' || this.contact.status == 'Delinquent') 
					&& this.contact.addToPaymentPlan == true) || this.contact.status == 'On Payment Plan') ? true : false;
	    	}
		}
	}
}