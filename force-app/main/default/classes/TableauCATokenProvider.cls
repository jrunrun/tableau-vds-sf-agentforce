/**
 * @description This class handles the generation of JSON Web Tokens (JWTs) for Tableau Connected App authentication.
 * The class provides functionality to create signed JWTs with specific claims required by Tableau's Connected Apps
 * authentication protocol.
 * 
 * The JWT includes the following claims:
 * - iss (issuer): Client ID of the Connected App
 * - exp (expiration): 5 minutes from generation time
 * - jti (JWT ID): A unique UUID for the token
 * - aud (audience): Set to 'tableau'
 * - sub (subject): Current user's Tableau username
 * - scp (scope): Array of Tableau-specific claims
 * - Account Name: List of account names associated with the current user for RLS via UAF
 * 
 * The class relies on TableauUtility helper class for:
 * - Retrieving Connected App configuration (secrets, client ID, etc.)
 * - Getting current user's username
 * - Handling Tableau-specific claims
 * - Base64URL encoding utilities
 * @author jcraycraft@salesforce.com
 */

public with sharing class TableauCATokenProvider {
    private static String ts_ca_iss;
    private static String ts_ca_kid;
    private static String ts_ca_secret;

    public TableauCATokenProvider() {

    }



    // Returns JWT (String)
    // @AuraEnabled annotation makes the method accessible via LWC 
    @AuraEnabled(cacheable=false)
    public static String generateJWT(String tokenType, String siteName) {
        // get secret, secret_id, client_id from custom meta data object 
        TableauUtility.TableauConfig config = TableauUtility.getTableauEnvConfig(siteName);
        ts_ca_iss = config.clientId;
        ts_ca_kid = config.kid;
        ts_ca_secret = config.secret;

        // getCurrentUserOpportunities();


        // Header (Map)
        Map<String, String> header = new Map<String, String>();
        header.put('alg', 'HS256');
        header.put('iss', ts_ca_iss);
        header.put('kid', ts_ca_kid);
        header.put('typ', 'JWT');
        // Claims (Map)
        Map<String, Object> claims = new Map<String, Object>();
        claims.put('iss', ts_ca_iss);
        // Add expiration
        Datetime now = Datetime.now();
        Datetime exp = now.addMinutes(5);
        claims.put('exp', exp.getTime()/1000); // Convert to seconds
        // Add UUID
        Blob base = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(base);
        String uuid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);
        claims.put('jti', uuid); 
        claims.put('aud', 'tableau');
        // TODO: make this dynamic
        // claims.put('sub', TableauUtility.getCurrentUserUsername());
        claims.put('sub', 'jcraycraft@salesforce.com');
        List<String> scp = TableauUtility.getTableauClaims(tokenType);
        claims.put('scp', scp);
        String uafValues = TableauUtility.getCurrentUserAccountName();
        List<String> uafValuesList = TableauUtility.convertStringToList(uafValues);
        claims.put('Account Name', uafValuesList);
        // Encode Header and Claims
        String encodedHeader = TableauUtility.base64UrlEncode(Blob.valueOf(JSON.serialize(header)));
        String encodedClaims = TableauUtility.base64UrlEncode(Blob.valueOf(JSON.serialize(claims)));
        // Create JWT
        String jwt = encodedHeader + '.' + encodedClaims;
        // Sign JWT 
        Blob hmacData = Crypto.generateMac('hmacSHA256', Blob.valueOf(jwt), Blob.valueOf(ts_ca_secret));
        // Encode JWT
        String signature = TableauUtility.base64UrlEncode(hmacData);
        // Add signature to JWT
        jwt += '.' + signature;
        return jwt;
    }
}