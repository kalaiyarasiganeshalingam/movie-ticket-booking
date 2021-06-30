import ballerina/http;
import ballerinax/java.jdbc;
import ballerina/io;
import ballerina/sql;

jdbc:Client dbClient = check new(url = "jdbc:h2:file:./local-transactions/db",
                           user = "test", password = "test");

service / on new http:Listener(9092) {
    resource function get moviName() returns string {
        int i = 0;
        stream<record{}, error> resultStream = dbClient->query("Select * from Movie");
        string movieNames = "";
        error? e = resultStream.forEach(function(record {} movie) {
            movieNames = movieNames + ", " + movie["NAME"].toString();
            i += 1;
        });
        return movieNames;
    }

    resource function get seatNo() returns string {
        int i = 0;
        stream<record{}, error> resultStream = dbClient->query("Select * from Seat");
        string seatNos = "Empty";
        error? e = resultStream.forEach(function(record{} seats) {
            seatNos = seatNos + ", " + seats["SEATNO"].toString();
            i += 1;
        });
        return seatNos;
    }

    resource function post createTable() returns error|string {
        _ = check dbClient->execute("DROP TABLE IF EXISTS Movie");
        _ = check dbClient->execute("DROP TABLE IF EXISTS Seat");
        _ = check dbClient->execute("CREATE TABLE Movie " +
                                    "(movieId INTEGER NOT NULL AUTO_INCREMENT, name  VARCHAR(300), time VARCHAR(300)," +
                                    "PRIMARY KEY(movieId))");
        _ = check dbClient->execute("CREATE TABLE Seat " +
                                    "(seatNo  INTEGER, name VARCHAR(300), " +
                                    "PRIMARY KEY(seatNo))");
        var e1 = check dbClient->execute("INSERT INTO Movie(name) VALUES ('Star Wars')");
        e1 = check dbClient->execute("INSERT INTO Movie(name) VALUES ('Little Women')");
        e1 = check dbClient->execute("INSERT INTO Movie(name) VALUES ('Cinderella')");
        e1 = check dbClient->execute("INSERT INTO Movie(name) VALUES ('Hary Potter')");
        return "Table created succesfully";
    }

    resource function post update(http:Request req) returns error|string {
        json|error details = req.getJsonPayload();
        if (details is json) {
            json name = check details.name;
            json seatNo = check details.seatNo;
            if (name is json && seatNo is json) {
                string value = name.toString();
                int seatId = check int:fromString(seatNo.toString());
                sql:ParameterizedQuery query = `INSERT INTO Seat (seatNo, name) VALUES (${seatId}, ${value})`;
                var creditResult = check dbClient->execute(query);
                io:println("Movie booking completed successfully!");

            }
            return "Data updated succesfully";
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
