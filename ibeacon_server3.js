var fs = require('fs');
var noble = require('noble');
var WebSocket = require('ws');
var WebSocketServer = require('ws').Server
var wss = new WebSocketServer({ port: 8080 });

var ibeacon_name = "FyxBoot";
var discovered_ibeacons_file_path = "discovered_ibeacons.json";
var discovered_arr = new Array();

console.log("Running iBeacon Server...");

noble.on('stateChange', function(state) {
  console.log(state);
  if (state == 'poweredOn'){
    noble.startScanning([],false);
  }else{
    noble.stopScanning();
  }
});

// code from: https://gist.github.com/maciej/11217917
noble.on('discover', connectToiBeacon);

function calculateDistance(rssi) {
  var txPower = -59 //hard coded power value. Usually ranges between -59 to -65
  if (rssi == 0) {
    return -1.0; 
  }
  var ratio = rssi*1.0/txPower;
  if (ratio < 1.0) {
    return Math.pow(ratio,10);
  }
  else {
    var distance =  (0.89976)*Math.pow(ratio,7.7095) + 0.111;    
    return distance;
  }
}

function connectToiBeacon(peripheral) {
  if(peripheral.advertisement.localName!=ibeacon_name){
    return;
  }
  peripheral.connect(function(error) {});


  peripheral.on('connect',function(){
    var data = peripheral.uuid + ",connected";
    // record the iBeacon discovery
    discovered_arr.push(peripheral);
    // broadcast the data
    console.log(data);
    wss_broadcast(data);
  });
  
  peripheral.on('disconnect',function(){
    var data = peripheral.uuid + ",disconnected";
    // broadcast the data
    console.log(data);
    wss_broadcast(data);
  });

  peripheral.on('rssiUpdate',function(rssi){
    var dist = calculateDistance(peripheral.rssi);
    var data = peripheral.uuid + ",update," + peripheral.rssi + "," + dist;
    // broadcast the data
    console.log(data);
    //console.log({"uuid": peripheral.uuid, "rssi": peripheral.rssi , "distance": dist});
    wss_broadcast(data);
  });
}

function wss_broadcast(data){
  wss.clients.forEach(function each(client) {
    client.send(data);
  });
}

// updateRssi for each active iBeacon
setInterval(function(){
  for(var i=0; i<discovered_arr.length; i++){
    if(discovered_arr[i].state == "connected"){
      discovered_arr[i].updateRssi();
    }
  }
}, 200);

setInterval(function(){
  for(var i=0; i<discovered_arr.length; i++){
    if(discovered_arr[i].state == "disconnected"){
      discovered_arr[i].connect();
    }
  }
},1000);

