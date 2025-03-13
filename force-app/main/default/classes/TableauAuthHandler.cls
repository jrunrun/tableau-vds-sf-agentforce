/**
 * @description This class handles the authentication process for Tableau REST API.
 * @author jcraycraft@salesforce.com
 */

public with sharing class TableauAuthHandler {
    // Move static variables to class level
    private static String tsSite;
    private static String tsServer;
    private static String tsApiVersion;
    private static String caJWT;

    @AuraEnabled(cacheable=false)
    public static String authenticate(String siteName) {
        // Get the tableau environment config (siteName, server)


        TableauUtility.TableauConfig config = TableauUtility.getTableauEnvConfig(siteName);
        
        
        tsSite = config.siteName;
        tsServer = config.tableauCloud;
        tsApiVersion = '3.25';

        caJWT = TableauCATokenProvider.generateJWT('REST_API', tsSite);
        
        // Create the nested structure for the JSON body
        Map<String, Object> requestBody = new Map<String, Object>();
        Map<String, Object> credentials = new Map<String, Object>();
        Map<String, Object> site = new Map<String, Object>();
        
        site.put('contentUrl', tsSite);
        credentials.put('jwt', caJWT);
        credentials.put('site', site);
        requestBody.put('credentials', credentials);

        String jsonBody = JSON.serialize(requestBody);
        System.debug(LoggingLevel.INFO, 'jsonBody: ' + jsonBody);

        // Construct the URL
        String tsUrl = tsServer + '/api/' + tsApiVersion + '/auth/signin';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(tsUrl);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');  // Changed to JSON content type
        req.setHeader('Accept', 'application/json');
        req.setBody(jsonBody);  // Use the JSON body instead of undefined xmlBody

        // System.debug(LoggingLevel.INFO, 'Request: ' + JSON.serializePretty(req));
        // System.debug(LoggingLevel.INFO, 'Request Body: ' + req.getBody());
        // System.debug(LoggingLevel.INFO, 'tsUrl: ' + tsUrl);
        
        try {
            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                System.debug(LoggingLevel.INFO, 'Successful sign-in, received status code of ' + res.getStatusCode());
                
                // Parse the response
                Map<String, Object> responseAuth = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                System.debug(LoggingLevel.INFO, 'Response: ' + JSON.serializePretty(responseAuth));

                // Extract credentials from response
                Map<String, Object> respCredentials = (Map<String, Object>)responseAuth.get('credentials');
                Map<String, Object> respSite = (Map<String, Object>)respCredentials.get('site');
                Map<String, Object> respUser = (Map<String, Object>)respCredentials.get('user');

                // Store these if needed
                String tsSiteLuid = (String)respSite.get('id');
                String tsAuthToken = (String)respCredentials.get('token');
                String tsUserLuid = (String)respUser.get('id');

                return tsAuthToken;
            } else {
                String errorMessage = 'Could not authenticate to tableau server api: ' + res.getStatusCode();
                System.debug(LoggingLevel.ERROR, errorMessage);
                throw new TableauAuthException(errorMessage);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error during Tableau authentication: ' + e.getMessage());
            throw new TableauAuthException('Authentication failed: ' + e.getMessage());
        }
    }

    // Custom exception class
    public class TableauAuthException extends Exception {}
}