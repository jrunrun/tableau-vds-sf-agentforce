public with sharing class TableauVDSQueryDatasource {
    @InvocableMethod(label='TableauVDSQueryDatasource' description='Returns response from the VDS')
    // public static List<OutputResponse> queryDatasource(List<String> User_Query) {
    public static List<OutputResponse> queryDatasource(List<Request> input_data) {

        Request myRequest = input_data[0];

        
        System.debug('input_data ' + input_data);  

        String VDSQuery = myRequest.User_Query;

        // Debug the extracted values
        System.debug('VDS Query Datasource User_Query: ' + VDSQuery);

        // Create a request object for querying VDS datasource
        Map<String, Object> queryRequest = new Map<String, Object>();
        Map<String, Object> connectionBody = new Map<String, Object>();

        // E-bikes datasource info: https://stage-dataplane8.tableau.sfdc-shbmgi.svc.sfdcfc.net/#/site/eacloudstage8/datasources/179496/connections
        // String datasourceLuid = 'ca44d18c-b33b-41c3-81f0-a8f291194300';

          // Using the VDS API endpoint for the RCGSEPulse site
        // a30bb0b0-cac9-4268-9f42-3142bd09529b
        // https://10ax.online.tableau.com/#/site/rcgsepulse/datasources/8266875/connections
        String datasourceLuid = 'a30bb0b0-cac9-4268-9f42-3142bd09529b';


        
        
        // Authenticate to REST API
        String x_tableau_auth = TableauAuthHandler.authenticate('rcgsepulse');
        System.debug('token @ TableauVDSQueryDatasource: ' + x_tableau_auth);

        connectionBody.put('datasourceLuid', datasourceLuid);
        queryRequest.put('datasource', connectionBody);

        // Parse the User_Query string into a Map structure
        Map<String, Object> query = (Map<String, Object>) JSON.deserializeUntyped(VDSQuery);
        queryRequest.put('query', query);
        
        // Send the HTTP request manually
        HttpRequest httpRequest = new HttpRequest();
        Http http = new Http();
        HttpResponse httpResponse;
        List<OutputResponse> outputResponse = new List<OutputResponse>();

        try {

            

            // Configure HTTP request
            httpRequest.setEndpoint('https://10ax.online.tableau.com/api/v1/vizql-data-service/query-datasource');
            httpRequest.setMethod('POST');
            httpRequest.setHeader('Content-Type', 'application/json');
            httpRequest.setHeader('X-Tableau-Auth', x_tableau_auth );
            httpRequest.setBody(JSON.serialize(queryRequest));
            System.debug('HTTP Request: ' + httpRequest);

            // Send the request and get the response
            httpResponse = http.send(httpRequest);
            System.debug('HTTP Response: ' + httpResponse.getBody());

            if (httpResponse.getStatusCode() == 200) {
                // Deserialize the response into an untyped Map
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(httpResponse.getBody());

                // Extract the "data" property
                if (responseMap.containsKey('data')) {
                    List<Object> rawData = (List<Object>) responseMap.get('data');

                    // Convert rawData into a serialized JSON string
                    String serializedData = JSON.serialize(rawData);
                    outputResponse.add(new OutputResponse(serializedData, ''));
                } else {
                    outputResponse.add(new OutputResponse('', 'Error: "data" key not found in the response'));
                }
            } else {
                outputResponse.add(new OutputResponse('', 'Error: HTTP response code ' + httpResponse.getStatusCode()));
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            outputResponse.add(new OutputResponse('', 'Error: ' + e.getMessage()));
        }

        return outputResponse;
    }

    // Request class to match the expected input for invocable method
    public class Request {
        @InvocableVariable(required=true)
        public String User_Query;
    }
    
    public class OutputResponse {
        @InvocableVariable(label='Response Body' description='Response from the VDS')
        public String responseBody;
        @InvocableVariable(label='Error' description='Error response')
        public String error;

        public OutputResponse(String responseBody, String error) {
            this.responseBody = responseBody;
            this.error = error;
        }
    }
}