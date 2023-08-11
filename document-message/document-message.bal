import ballerina/http;
import ballerina/mime;

type CsvRequest record {
    string path;
    string CRM_ORG;
    string feature;
};

type ZohoResponse record {
    string status;
    string code;
    string message;
    record {|
        string file_id;
        string created_time;
    |} details;
};

service /upload on new http:Listener(8080) {

    resource function post csv(CsvRequest csvRequest) returns ZohoResponse|error {
        http:Request request = new;
        request.addHeader("CRM_ORG", csvRequest.CRM_ORG);
        request.addHeader("feature", csvRequest.feature);
        request.setFileAsPayload(csvRequest.path, contentType = mime:MULTIPART_FORM_DATA);
        
        http:Client zohoClient = check new ("http://api.zoho.com.balmock.io");
        return zohoClient->/crm/v5/upload.post(request);
    }
}
