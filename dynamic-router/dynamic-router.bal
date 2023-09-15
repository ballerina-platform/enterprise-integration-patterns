import ballerina/http;
import ballerina/mqtt;

type RoutingEntry record {|
    string deviceId;
    readonly int roomNo;
    boolean dimmable;
|};

type SwitchRequest record {|
    int roomNo;
    State state;
|};

enum State {
    ON,
    OFF,
    DIM
}

final mqtt:Client mqttClient = check new (mqtt:DEFAULT_URL, "routermqttclient");
table<RoutingEntry> key(roomNo) routingTable = table [];

service /bulbs on new http:Listener(8080) {

    resource function post switch(SwitchRequest switchRequest) returns error? {
        RoutingEntry? entry = routingTable[switchRequest.roomNo];
        if entry == () {
            return error("Invalid room");
        }
        if switchRequest.state == DIM && !entry.dimmable {
            return error("Bulb is not dimmable");
        }
        check mqttClient->publish("bulb/" + entry.deviceId, {payload: switchRequest.state.toBytes()});
    }
}

listener mqtt:Listener mqttSubscriber = check new (mqtt:DEFAULT_URL, "routermqttlistener", "bulb/config");

service on mqttSubscriber {
    remote function onMessage(mqtt:Message message, mqtt:Caller caller) returns error? {
        RoutingEntry entry = check (check string:fromBytes(message.payload)).fromJsonStringWithType();
        routingTable.put(entry);
        check caller->complete();
    }
}
