<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update_Invoice_Name</fullName>
        <field>Name</field>
        <formula>Display_Name__c</formula>
        <name>Update Invoice Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Invoice Name</fullName>
        <actions>
            <name>Update_Invoice_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>Name &lt;&gt;  Display_Name__c</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>