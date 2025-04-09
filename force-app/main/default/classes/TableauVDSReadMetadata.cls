public with sharing class TableauVDSReadMetadata {
   
    @InvocableMethod(label='TableauVDSReadMetadata' description='Fetches metadata from the VDS')
    public static List<OutputResponse> readMetadata(List<Request> requests) {
        Request myRequest = requests[0];
        String VDSQuery = myRequest.User_Query;
        System.debug('VDS Read Metadata - User query: ' + VDSQuery);

        // Create a request object for querying VDS datasource
        Map<String, Object> readMetadataRequest = new Map<String, Object>();
        Map<String, Object> connectionBody = new Map<String, Object>();
        
        // String datasourceLuid = '30c08e5a-49c6-4f4a-a71f-75b3dfff11d8';
        String datasourceLuid = 'ca44d18c-b33b-41c3-81f0-a8f291194300';
        
        connectionBody.put('datasourceLuid', datasourceLuid);
        readMetadataRequest.put('datasource', connectionBody);

        // Send the HTTP request manually
        HttpRequest httpRequest = new HttpRequest();
        Http http = new Http();
        HttpResponse httpResponse;
        List<OutputResponse> outputResponse = new List<OutputResponse>();

        try {
       

            // Authenticate to REST API
            String x_tableau_auth = TableauAuthHandler.authenticate('eacloudstage8');
            System.debug('token @ TableauVDSReadMetadata: ' + x_tableau_auth);

        
            // Configure HTTP request
            // TODO: Make this dynamic using custom metadata
            httpRequest.setEndpoint('https://stage-dataplane8.tableau.sfdc-shbmgi.svc.sfdcfc.net/api/v1/vizql-data-service/read-metadata');
            httpRequest.setMethod('POST');
            httpRequest.setHeader('Content-Type', 'application/json');
            httpRequest.setHeader('X-Tableau-Auth', x_tableau_auth);
            httpRequest.setBody(JSON.serialize(readMetadataRequest));
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

    // Response class to hold the response data
    public class OutputResponse {
        @InvocableVariable
        public String Prompt;

        public OutputResponse(String responseBody, String Error) {
            this.Prompt = responseBody;
        }
    }
}