/**
 * @description Utility class for managing Tableau integration with Salesforce.
 * Provides functionality for:
 * - Retrieving Tableau configuration settings from Custom Metadata
 * - Managing Tableau views and metrics
 * - Handling user authentication and authorization
 * - Retrieving user context (email, division, account)
 * - Managing Tableau claims and scopes for SSO and REST API access
 * - Accessing user-specific Salesforce data (Opportunities, Cases)
 * 
 * @author jcraycraft@salesforce.com
 */

public with sharing class TableauUtility {

    
    
    // Wrapper class to hold Tableau configuration values
    public class TableauConfig {
        @AuraEnabled public String clientId;
        @AuraEnabled public String kid;
        @AuraEnabled public String secret;
        @AuraEnabled public String siteName;
        @AuraEnabled public String tableauCloud;
        
        public TableauConfig(String clientId, String kid, String secret, String siteName, String tableauCloud) {
            this.clientId = clientId;
            this.kid = kid;
            this.secret = secret;
            this.siteName = siteName;
            this.tableauCloud = tableauCloud;
        }
    }

    @AuraEnabled(cacheable=false)
    public static TableauConfig getTableauEnvConfig(String siteName) {
            
            // Build query
        String query = 'SELECT DeveloperName, secret__c, kid__c, clientId__c, SiteName__c, TableauCloud__c FROM TableauConnectedApp__mdt';
        if (String.isNotBlank(siteName)) {
            query += ' WHERE SiteName__c = :siteName';
        }
        query += ' LIMIT 1';
        
        // Execute query
        List<TableauConnectedApp__mdt> tabEnv = Database.query(query);
        
        if (tabEnv.isEmpty()) {
            throw new AuraHandledException('No Tableau Connected App configuration found' + 
                (String.isNotBlank(siteName) ? ' for site: ' + siteName : ''));
        }
        
        TableauConnectedApp__mdt ca = tabEnv[0];
        System.debug('Using Tableau config for site: ' + ca.SiteName__c);
        
        return new TableauConfig(
            ca.clientId__c,
            ca.kid__c,
            ca.secret__c,
            ca.SiteName__c,
            ca.TableauCloud__c
        );
    }

  



    // Returns user's email & division (Map)
    // @AuraEnabled annotation makes the method accessible via LWC

    /* 
    Partner/Community/Experience Cloud users are associated with a Contact, which has a relationship to an Account. 
    */
    @AuraEnabled(cacheable=false)
    public static Map<String, String> getUserDetails() {
        // Get the user's division, email, and account name
        User currentUser = [SELECT Email, Division, ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        String accountName = '';

        if (currentUser.ContactId != null) {
            // Query the Contact to get the Account Name
            Contact userContact = [SELECT Account.Name FROM Contact WHERE Id = :currentUser.ContactId];
            accountName = userContact.Account.Name;
            System.debug('Account Name: ' + accountName);
        }

        Map<String, String> userDetails = new Map<String, String>{
            'Email' => currentUser.Email,
            'Division' => currentUser.Division,
            'Account' => accountName
        };
        return userDetails;
    }

    // helper to convert comma delimited strings to list
    public static List<String> convertStringToList(String input) {
        return input.split(',\\s*');
    }

    // helper to get authenticated user's Division field for UAF
    public static String getCurrentUserDivision() {
        User currentUser = [SELECT Division FROM User WHERE Id = :UserInfo.getUserId()];
        return currentUser.Division;
    }

    // helper to get authenticated user's Account Name field for UAF
    @AuraEnabled(cacheable = false)
    public static String getCurrentUserAccountName() {
        User currentUser = [SELECT Email, Division, ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        String accountName = '';
        if (currentUser.ContactId != null) {
            // Query the Contact to get the Account Name
            Contact userContact = [SELECT Account.Name FROM Contact WHERE Id = :currentUser.ContactId];
            accountName = userContact.Account.Name;
        }
        return accountName;
    }

    // helper to get authenticated user's Opportunities
    @AuraEnabled(cacheable=false)
    public static List<Opportunity> getCurrentUserOpportunities() {
        // Query to fetch opportunities where the current user is the owner
        List<Opportunity> opps = [SELECT Id, Name, CloseDate, Amount FROM Opportunity WHERE OwnerId = :UserInfo.getUserId()];
        return opps;
    }

    // helper to get authenticated user's Cases
    @AuraEnabled(cacheable = false)
    public static List < Case > getCurrentUserCases() {
        // Query to fetch cases where the current user is the owner
        List < Case > cases = [SELECT Id, CaseNumber, Subject, Status, Priority FROM Case WHERE OwnerId =: UserInfo.getUserId()];
        return cases;
    }

    // helper to get aauthenticated user's username
    public static String getCurrentUserUsername() {
        User currentUser = [SELECT Username FROM User WHERE Id = :UserInfo.getUserId()];
        return currentUser.Username;
    }

    // helper method for base64 url encoding
    public static String base64UrlEncode(Blob input) {
        String output = EncodingUtil.base64Encode(input);
        output = output.replace('+', '-');
        output = output.replace('/', '_');
        output = output.replace('=', '');
        return output;
    }

    // helper to create a list of required Tableau claims
    public static List<String> getTableauClaims(String input) { 
        List<String> scopes;
        if (input == 'SSO') {
            // Add tableau scopes (List)
            scopes = new List<String>{
                'tableau:views:embed',
                'tableau:views:embed_authoring',
                'tableau:metrics:embed',
                'tableau:insights:embed'
            };
        } else if (input == 'REST_API') {
            // Add tableau scopes (List)
            scopes = new List<String>{
                'tableau:content:read',
                'tableau:views:download',
                'tableau:views:embed',
                'tableau:views:embed_authoring',
                'tableau:metrics:embed'
            };
        }
        return scopes;
    }
}