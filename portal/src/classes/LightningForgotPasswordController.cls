/*
 * Copyright (c) 2017-present Sirono LLC, All rights reserved
 */

global class LightningForgotPasswordController {

    public LightningForgotPasswordController() {

    }

    @AuraEnabled
    public static String forgotPassword(String username, String checkEmailUrl) {
        try {
            Site.forgotPassword(username);
            ApexPages.PageReference checkEmailRef = new PageReference(checkEmailUrl);
            if (!Site.isValidUsername(username)) {
                return Label.Site.invalid_email;
            }
            Aura.redirect(checkEmailRef);
            return null;
        } catch (Exception ex) {
            return ex.getMessage();
        }
    }

}