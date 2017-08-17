/*
 * Copyright (c) 2017-present Sirono LLC, All rights reserved
 */

/**
 * Payment DAO for Encounter__c object SOQL/DML operations
 */
public with sharing class EncounterDao {
    public enum IdType {
        GUARANTOR, ENCOUNTER
    }

    public without sharing class ElevatedPrivilegesHelper {
        /**
         * Return the patient MRN and Name for all encounters for the given guarantor
         *
         * @param Contact - the guarantor to retrieve Encounter__c for
         * @returns List<Encounter__c> - The list of encounters.
         */
        public List<Encounter__c> getInfoForRelatedPatients(Contact guarantor) {
            return [
                SELECT Patient__r.Medical_Record_Number__c, Patient__r.Name
                FROM Encounter__c
                WHERE Guarantor__c = :guarantor.Id
                LIMIT 50000
            ];
        }

        /**
         * Return all encounters for the given guarantor. Include the first attachment for each and its associated
         * payments. If the guarantor is not supplied, just return an empty list
         *
         * @param Contact - the guarantor to retrieve Encounter__c for
         * @param String paidFilter - filter to return only 'Paid', 'Unpaid' or 'All' encounters. null == 'All'
         * @param List<String> patientIds - limit the returned Encounter__c records to those associated with these patients
         *
         */
        public List<Encounter__c> getAllEncounters(Contact guarantor, String paidFilter, List<String> patientIds) {

            if (guarantor == null) {
                return new List<Encounter__c>();
            }

            String patientClause = '';
            if (patientIds != null && !patientIds.isEmpty()) {
                patientClause += ' AND Patient__c IN :patientIds';
            }

            String query = 'SELECT (SELECT Amount__c, Deposit_Date__c FROM Payments__r), ' +
                'Id, Name, Patient__r.Name, Estimate_Id__c, Patient_Portion__c, ' +
                'Date_Of_Service__c, Patient__r.Medical_Record_Number__c, Procedure__c, ' +
                'Location__c, Encounter_Id__c, Total_Charges__c, Insurance_Discount__c, ' +
                'Insurance_Portion__c, Total_Payments__c, Balance__c, Type__c, Ordering_Physician__c, ' +
                'Coverage__c, Coverage__r.Name, ' +
                '(SELECT Id  FROM Attachments ORDER BY CreatedDate DESC LIMIT 1)' +
                'FROM Encounter__c WHERE Guarantor__c = \'' + guarantor.Id + '\'' + patientClause;

            if (!String.isEmpty(paidFilter)) {
                if (Constants.UNPAID.equalsIgnoreCase(paidFilter)) {
                    query += ' AND Encounter__c.Balance__c > 0 AND (Encounter__c.Total_Payments__c = null OR Encounter__c.Total_Payments__c = 0) ';
                }
                if (Constants.PAID.equalsIgnoreCase(paidFilter)) {
                    query += ' AND ((Encounter__c.Balance__c > 0 AND Encounter__c.Total_Payments__c > 0 ) OR Encounter__c.Balance__c <= 0) ';
                }
            }

            System.debug('SOQL query: ' + query);
            System.debug('paidFilter: ' + paidFilter);

            return Database.query(query);
        }

        /**
         * Get a list of Encounters for a particular invoice.
         *
         * @param Id contactId - The contact id for the user associated with the encounters.
         * @param String invoiceId - The invoice id for which to get the encounters.
         * @returns List<Encounter__c> - The encounters.
         */
        public List<Encounter__c> getForInvoice(Id contactId, String invoiceId) {

            if (EncounterSecurityContext.SELECT_CONTEXT.actionAllowed()) {
                return [
                    SELECT Id, Name, Patient__r.Name, Estimate_Id__c, Patient_Portion__c,
                        Date_Of_Service__c, Patient__r.Medical_Record_Number__c, Procedure__c,
                        Location__c, Encounter_Id__c, Total_Charges__c, Insurance_Discount__c,
                        Insurance_Portion__c, Total_Payments__c, Balance__c, Type__c, Ordering_Physician__c, (
                        SELECT Amount__c, Deposit_Date__c
                        FROM Payments__r
                    )
                    FROM Encounter__c
                    WHERE Guarantor__c = :contactId
                    AND Id = :invoiceId
                ];
            }
            return null;
        }
    }

	/**
	 * This method is use to get Encounter Records based on Guarantor Id or Id and Balance is greater than zero.
     * @param IdType objectName - object name for where condition
     * @param String condId - record Id
	 **/
    public static List<Encounter__c> getEncounterRecordsById(IdType objectName, String condId) {
        if (EncounterSecurityContext.SELECT_CONTEXT.actionAllowed()) {
            String queryString = 'SELECT Id, Name, Patient__c, Date_Of_Service__c, Procedure__c, Location__c, Patient_Portion__c, Guarantor__c, Balance__c ';
            queryString += ' FROM Encounter__c ';
            queryString += ' WHERE Balance__c > 0 ';
            queryString += (objectName == IdType.GUARANTOR) ? ' AND Guarantor__c = :condId' : ' AND Id = :condId';
            List<Encounter__c> encounterList = Database.query(queryString);
            return encounterList;
        }
        return null;
    }

    /**
     * This method is use to update Billed CG Count in Encounters.
     *
     * @param List<Encounter__c> encounters - That contains list of Encounters.
     **/
    public static void updateBilledCGCount(List<Encounter__c> encounters) {
        if (EncounterSecurityContext.UPDATE_BILLED_CG_COUNT_CONTEXT.actionAllowed()) {
            update encounters;
        }
    }

    /**
     * Get the number of Encounters for a contact from a startdate to now.
     *
     * @returns Integer - The number of Encounters found.
     */
    public static Integer getCountByDate(Id contactId, Datetime startDate) {
        if (EncounterSecurityContext.SELECT_CONTEXT.actionAllowed()) {
            return [
                SELECT
                    COUNT()
                FROM Encounter__c
                WHERE Guarantor__c = :contactId AND
                CreatedDate >= :startDate
            ];
        }
        return null;
    }

    /**
     * Return the patient MRN and Name for all encounters for the given guarantor
     *
     * @param Contact - the guarantor to retrieve Encounter__c for
     * @returns List<Encounter__c> - The list of encounters.
     */
    public static List<Encounter__c> getAllPatients(Contact guarantor) {
        ElevatedPrivilegesHelper helper = new ElevatedPrivilegesHelper();
        return helper.getInfoForRelatedPatients(guarantor);
    }
}