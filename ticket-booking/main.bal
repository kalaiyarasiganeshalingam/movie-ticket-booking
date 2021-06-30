import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/regex;


http:Client httpClient = check new("http://localhost:9092");

string name = "";
string seatNo = "";
boolean paidPayment = false;

public function main(string... args) returns error? {
    http:Request request = new;
    string output = check httpClient->post("/createTable", request);
    name  = io:readln(string `Enter your name: `);
    retry<MyRetryManager>() {
        var result = check getName();
        result = check getSeatNo();
        paidPayment = check isPaymentPaid();
    }
    if (paidPayment) {
        json jsonPart = {
            name: name,
            seatNo: seatNo
        };
        request.setJsonPayload(jsonPart);
        string result = check httpClient->post("/update", request);
        io:println("Booking successfully completed.");
    }
}

function getName() returns error|string {
    boolean validation = false;
    string[] movieNames = [];
    var result = httpClient->get("/moviName", targetType = string);
    if (result is string) {
        movieNames = regex:split(result.substring(2, result.length()), ", ");
    } else if (!(result.message() == "No payload")) {
        log:printError(result.message());
        return result;
    }
    string movieName = io:readln(string `Enter the movie name from ${movieNames.toString()}: `);
    foreach string val in movieNames {
        if (val.equalsIgnoreCaseAscii(movieName)) {
            validation = true;
        }
    }
    if (!validation) {
        log:printError("Invalid movie name");
        return error error:Retriable("Invalid movie name");
    } else {
        return name;
    }
}

function getSeatNo() returns error|string {
    boolean validation = true;
    string[] seats = [];
    var result = httpClient->get("/seatNo", targetType = string);
    if (result is string) {
        seats = regex:split(result.substring(5, result.length()), ", ");
    } else if (!(result.message() == "No payload")) {
        log:printError(result.message());
        return result;
    }
    seatNo = io:readln(string `Enter the non-reserved seat. Reserved seat:${seats.toString()}. `);
    foreach string val in seats {
        if (val.equalsIgnoreCaseAscii(seatNo)) {
            validation = false;
        }
    }
    if (!validation) {
        log:printError("This seat already booked");
        return error error:Retriable("This seat already booked");
    } else {
        return seatNo;
    }
}

function isPaymentPaid() returns boolean|error {
    string cardNo = io:readln(string `Enter your credit card no[The no shoud be contain 15 character]: `);
    if (cardNo.length() < 15 || int:fromString(cardNo) is error) {
        retry<MyRetryManager>() {
            var result = check getName();
            result = check getSeatNo();
            return check isPaymentPaid();
        }
    }
    return true;
}

public class MyRetryManager {
   public function shouldRetry(error? err) returns boolean {
     if err is error {
        return true;
     } else {
        return false;
     }
   }
}
