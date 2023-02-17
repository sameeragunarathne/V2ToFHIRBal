import ballerina/http;

import wso2healthcare/healthcare.hl7;
import wso2healthcare/healthcare.fhir.r4;
import wso2healthcare/healthcare.hl7v23;

# A service representing a network-accessible API
# bound to port `9090`.
service / on new http:Listener(9090) {

    # A resource for generating greetings
    # + id - the input string name
    # + return - string name with hello message or error
    resource function get r4/Patient/[string id]() returns json|error {

        string adtMsgStr = "MSH|^~\\&|SendingApp|SendingFacility|HL7API|PKB|20160102101112||ADT^A01|ABC0000000001|P|2.3\r" +
"PID|||9999999999^^^NHS^NH||Smith^John^Joe^^Mr||19700101|M|||Flat name^1, The Road^London^London^SW1A 1AA^GBR||01234567890^PRN~07123456789^PRS|^NET^john.smith@company.com~01234098765^WPN||||||||||||||||N|\r" +
"PV1|1|I|^^^^^^^^My Ward||||^Jones^Stuart^James^^Dr^|^Smith^William^^^Dr^|^Foster^Terry^^^Mr^||||||||||V00001|||||||||||||||||||||||||201508011000|201508011200";

    byte[] queryMessage = hl7:createHL7WirePayload(adtMsgStr.toBytes());

    hl7:HL7Parser parser = new ();
    hl7:Message|hl7:GenericMessage parsedMsg = check parser.parse(queryMessage);

    // Based on the message type, transformation applied
    if parsedMsg is hl7v23:ADT_A01 {
        // 1). Applying the v2 to fhir transformation for ADT_A01 Message
        r4:Patient patient = ADT_A01ToPatient(parsedMsg);
        return patient.toJson();
    }
        return {};
    }
}
