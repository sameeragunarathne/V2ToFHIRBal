import ballerina/http;

import wso2healthcare/healthcare.hl7;
import wso2healthcare/healthcare.fhir.r4;
import wso2healthcare/healthcare.hl7v23;
import ballerina/io;

# A service representing a FHIR Patient API
# bound to port `9090`.
service / on new http:Listener(9090) {

    # Patient read
    # + id - patient id
    # + return - returns patient FHIR resource
    resource function get r4/Patient/[string id]() returns json|error {

        hl7:HL7Parser hl7Parser = new ();
        hl7:HL7Encoder hl7Encoder = new ();
        //building patient query message
        hl7v23:QRY_A19 qry_a19 = {
            msh: {
                msh3: {hd1: "ADT1"},
                msh4: {hd1: "MCM"},
                msh5: {hd1: "LABADT"},
                msh6: {hd1: "MCM"},
                msh8: "SECURITY",
                msh9: {cm_msg1: "QRY", cm_msg2: "A19"},
                msh10: "MSG00001",
                msh11: {pt1: "P"},
                msh12: "2.3"
            },
            qrd: {
                qrd1: {ts1: "20220828104856+0000"},
                qrd2: "R",
                qrd3: "I",
                qrd4: "QueryID01",
                qrd8: [{xcn1: id}]
            }
        };
        //encoding query message to HL7 wire format.
        byte[] encodedQRYA19 = check hl7Encoder.encode(hl7v23:VERSION, qry_a19);
        
        do {
            //sending query message to HL7 server
            hl7:HL7Client hl7Client = check new ("localhost", 9988);
            byte[]|hl7:HL7Error response = hl7Client.sendMessage(encodedQRYA19);

            if response is byte[] {
                //parsing response message from the HL7 server 
                hl7:Message|hl7v23:GenericMessage?|hl7:HL7Error responseMsg = hl7Parser.parse(response);
                //parsing to ADR_A19 response message: https://hl7-definition.caristix.com/v2/HL7v2.3/TriggerEvents/ADR_A19
                if responseMsg is hl7v23:ADR_A19 {
                    r4:Patient[] patients = ADR_A19ToPatient(responseMsg);
                    if patients.length() > 0 {
                        return patients[0].toJson();
                    }
                }
            }
            if response is hl7:HL7Error {
                io:println(response.message());
            }
        } on fail var e {
            io:println(e.message());
        }

        return {};
    }
}

