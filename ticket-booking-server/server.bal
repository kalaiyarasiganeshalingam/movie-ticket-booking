import ballerina/http;
import ballerinax/java.jdbc;
import ballerina/io;
import ballerina/sql;

type Movie record {|
    string name;
    string time;
|};

type Seat record {|
    int seatNo;
    string name;
|};

jdbc:Client dbClient = check new(url = "jdbc:h2:file:./local-transactions/db",
                           user = "test", password = "test");

service / on new http:Listener(9090) {
    resource function get moviName(http:Request req) returns string {
        int i = 0;
        stream<record{}, error> resultStream = dbClient->query("Select * from Movie", Movie);
        string movieNames = "";
        error? e = resultStream.forEach(function(record {} movie) {
            movieNames = movieNames + ", " + movie["name"].toString();
            i += 1;
        });
        return movieNames;
    }

    resource function get seatNo(http:Request req) returns string {
        int i = 0;
        stream<record{}, error> resultStream = dbClient->query("Select * from Seat", Seat);
        string seatNos = "";
        error? e = resultStream.forEach(function(record {} seats) {
            seatNos = seatNos + ", " + seats["seatNo"].toString();
            i += 1;
        });
        return seatNos;
    }

    resource function post createTable(http:Request req) returns error? {
        _ = check dbClient->execute("CREATE TABLE IF NOT EXISTS Movie " +
                                    "(name  VARCHAR(300), time VARCHAR(300)," +
                                    "PRIMARY KEY(name))");
        _ = check dbClient->execute("CREATE TABLE IF NOT EXISTS Seat " +
                                    "(seatNo  INTEGER, name VARCHAR(300), " +
                                    "PRIMARY KEY(seatNo))");
        var e1 = check dbClient->execute("INSERT INTO Movie(name) VALUES ('Star Wars')");
        e1 = check dbClient->execute("INSERT INTO Movie(name) VALUES ('Little Women')");
        e1 = check dbClient->execute("INSERT INTO Movie(name) VALUES ('Cinderella')");
        e1 = check dbClient->execute("INSERT INTO Movie(name) VALUES ('Hary Potter')");
    }

    resource function post update(http:Request req) returns error? {
        json|error details = req.getJsonPayload();
        if (details is json) {
            json|error name = details.name;
            json|error seatNo = details.seatNo;
            if (name is json && seatNo is json) {
                string value = name.toString();
                int seatId = check int:fromString(seatNo.toString());
                    sql:ParameterizedQuery query = `INSERT INTO Seat (seatNo, name) VALUES (${seatId}, ${value})`;
                    var creditResult = check dbClient->execute(query);
                    io:println("Movie booking completed successfully: ", creditResult);
            }
        } else {
            return details;
        }
    }
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
