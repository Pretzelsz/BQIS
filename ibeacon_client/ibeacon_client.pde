import java.net.URI;
import java.net.URISyntaxException;

import org.java_websocket.WebSocketImpl;
import org.java_websocket.client.WebSocketClient;
import org.java_websocket.drafts.Draft;
import org.java_websocket.drafts.Draft_10;
import org.java_websocket.drafts.Draft_17;
import org.java_websocket.drafts.Draft_75;
import org.java_websocket.drafts.Draft_76;
import org.java_websocket.handshake.ServerHandshake;

import java.util.concurrent.ConcurrentHashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Timer;
import java.util.TimerTask;
import java.util.ArrayDeque;

BeaconWebSocketClient cc;
Draft[] drafts = { new Draft_17(), new Draft_10(), new Draft_76(), new Draft_75() };
Timer connectTimer = null;
MovingAverage moving = new MovingAverage(20);


public class iBeaconData {
  public String id;
  public int rssi;
  public float distance;
}

ConcurrentHashMap<String, iBeaconData> iBeaconMap = new ConcurrentHashMap<String, iBeaconData>();

PImage person;

void setup() {
  size(640, 480);
  setupWebSocket("ws://localhost:8080", false, 1000);
  person = loadImage("sprite.png");
}

void draw() {
  fill(255, 253, 208, 50);
  rect(0, 0, 640, 480);
  fill(97, 93, 90);
  stroke(0, 0, 0);
  rect(295, 200, 10, 10);
  for (iBeaconData beacon : iBeaconMap.values()) {
    fill(19, 202, 123);
    ellipse(295, beacon.distance+200, 20, 20);
    //image(person, 295,beacon.distance+200);
  }
}

/***************************************************/
// WebSocket Methods
/***************************************************/

class BeaconWebSocketClient extends WebSocketClient {

  private Object connectLock = new Object();
  private boolean connected = false;

  public BeaconWebSocketClient(URI uri, Draft draft) {
    super(uri, draft);
  }

  @Override
    public void onMessage( String message ) {
    //println( "got: " + message );
    if (message==null || message.trim().equals("")) {
      return;
    }
    String[] msg = message.split(",");
    try {
      if (msg[1].equals("connected")) {
      } else if (msg[1].equals("update")) {
        iBeaconData data = new iBeaconData();
        data.id = msg[0];
        data.rssi = Integer.parseInt(msg[2]);
        data.distance = moving.average( Float.parseFloat(msg[3]) );
        iBeaconMap.put(msg[0], data);
      } else if (msg[1].equals("disconnected")) {
        iBeaconMap.remove(msg[0]);
      }
    }
    catch(Exception e) {
      e.printStackTrace();
    }
  }

  @Override
    public void onOpen( ServerHandshake handshake ) {
    synchronized(connectLock) {
      connected = true;
      println( "You are connected to: " + getURI() );
    }
  }

  @Override
    public void onClose( int code, String reason, boolean remote ) {
    synchronized(connectLock) {
      connected = false;
      println( "You have been disconnected from: " + getURI() + "; Code: " + code + " " + reason  );
    }
  }

  public boolean isConnected() {
    synchronized(connectLock) {
      return connected;
    }
  }

  @Override
    public void onError( Exception ex ) {
    ex.printStackTrace();
  }
}

void setupWebSocket(final String uri, boolean debug, long retry_delay_ms) {
  WebSocketImpl.DEBUG = false;
  Timer connectTimer = new Timer("web socket connect");
  connectTimer.schedule(new TimerTask() {
    @Override
      public void run() {
      try {
        if (cc==null || !cc.isConnected()) {
          cc = new BeaconWebSocketClient( new URI( uri ), drafts[1] );
          cc.connect();
        }
      }
      catch ( URISyntaxException ex ) {
        ex.printStackTrace();
      }
    }
  }
  , 0, retry_delay_ms);
}


class MovingAverage{
  private int maxSize;
  private ArrayDeque<Float> valQ = null;
  
  public MovingAverage(int maxSize){
    this.maxSize = maxSize;
    valQ = new ArrayDeque<Float>(maxSize+1);
  }
 
  public float average(float val){
    valQ.addLast(val);
    if(valQ.size()>maxSize){
      valQ.removeFirst();
    }
    float sum = 0;
    for(float d: valQ){
      sum+=d;
    }
    float average = sum/valQ.size();
    return average;
  }
}