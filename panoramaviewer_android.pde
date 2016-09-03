// Sensor classes
import android.content.Context; // Android4
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;

// for multitouch
import ketai.ui.*;
import android.view.MotionEvent; // 追加しないとコンパイルエラー

// for bluetooth
import android.content.Intent;
import android.os.Bundle;
import ketai.net.bluetooth.*;
import ketai.ui.*;
import ketai.net.*;
import oscP5.*;

// for list
import java.util.*;

// sensor
Context context; // Android4+
SensorManager mSensorManager;
SensorEventListener sensorEventListener;
Sensor accelerometer;
Sensor magnetometer;
boolean sensorAvailable = false;
Float azimuth       = 0.0;
Float pitch         = 0.0;
Float roll          = 0.0;

// cube
PImage pano_u;
PImage pano_d;
PImage pano_f;
PImage pano_b;
PImage pano_r;
PImage pano_l;
int cube_screen_size = 200;
float theta = 0;
float phi = 0;
float fov = 60.0;

// for camera control
boolean sensorControl = false; // センサでカメラコントロール
float theta_tmp = 0.0;
float phi_tmp = 0.0;
float startX = -1;
float startY = -1;

// multi touch
KetaiGesture gesture;

// bluetooth
KetaiBluetooth bt;
KetaiList klist;
PVector remoteMouse = new PVector();
ArrayList<String> devicesDiscovered = new ArrayList();
String btHelpText;
String btInfoText = "";

// GUI
Menu menu;
Tab tab_s;
Tab tab_b;
Tab tab_m;
String lastClickedId;

// MultiScreen Control
boolean standAlone = true;
String displayId = "center";
boolean testMode = false;

void setup() {
  size(displayWidth, displayHeight, P3D);
  noStroke();
  
  // Set this so the sketch won't reset as the phone is rotated:
  orientation(LANDSCAPE);

  // Setup Fonts:
  String[] fontList = PFont.list();
  PFont androidFont = createFont(fontList[0], 20, true);
  textFont(androidFont);
  
  // cube textures
  pano_u = loadImage("mobile_u.jpg");  
  pano_d = loadImage("mobile_d.jpg");  
  pano_f = loadImage("mobile_f.jpg");  
  pano_b = loadImage("mobile_b.jpg");  
  pano_r = loadImage("mobile_r.jpg");  
  pano_l = loadImage("mobile_l.jpg");   
 
  // multi touch
  gesture = new KetaiGesture(this);

  //start listening for BT connections
  bt.start();

  btHelpText =  "d - discover devices\n" +
    "b - make this device discoverable\n" +
    "c - connect to device\n     from discovered list.\n" +
    "p - list paired devices\n" +
    "i - Bluetooth info"; 
    
  // GUI
  initGUI();
}
 
void draw() {
  background(0);

  if (menu.isVisible() == false) { 
    draw_cube();
    camera_control(); 
  } else {
    camera(); //resets viewport to 2D equivalent  
    drawGUI();
    
    if (testMode) {
      float tx = 0, ty = 0;
      tx = (remoteMouse.x + 180.0) / 360.0 * displayWidth;
      ty = (remoteMouse.y + 90.0) / 180.0 * displayHeight; 
      pushStyle();
      fill(0, 255, 0);
      stroke(0, 255, 0);
      ellipse(tx, ty, 20, 20);   
      popStyle();        
    }
  }  
}

void draw_cube()
{
  noStroke();
  
  // front
  pushMatrix();
  translate(width / 2, height / 2, -cube_screen_size / 2);
  beginShape();
  texture(pano_f);
  vertex(-cube_screen_size / 2, -cube_screen_size / 2, 0, 0, 0);
  vertex(cube_screen_size / 2, -cube_screen_size / 2, 0, pano_f.width, 0);
  vertex(cube_screen_size / 2, cube_screen_size / 2, 0, pano_f.width, pano_f.height);
  vertex(-cube_screen_size / 2, cube_screen_size / 2, 0, 0, pano_f.height);
  endShape();
  popMatrix();
 
  // right
  pushMatrix();
  translate(width / 2 + cube_screen_size / 2, height / 2, 0);
  rotateY(-PI/2);
  beginShape();
  texture(pano_r);
  vertex(-cube_screen_size / 2, -cube_screen_size / 2, 0, 0, 0);
  vertex(cube_screen_size / 2, -cube_screen_size / 2, 0, pano_r.width, 0);
  vertex(cube_screen_size / 2, cube_screen_size / 2, 0, pano_r.width, pano_r.height);
  vertex(-cube_screen_size / 2, cube_screen_size / 2, 0, 0, pano_r.height);
  endShape();
  popMatrix();

  // left
  pushMatrix();
  translate(width / 2 - cube_screen_size / 2, height / 2, 0);
  rotateY(PI/2);
  beginShape();
  texture(pano_l);
  vertex(-cube_screen_size / 2, -cube_screen_size / 2, 0, 0, 0);
  vertex(cube_screen_size / 2, -cube_screen_size / 2, 0, pano_l.width, 0);
  vertex(cube_screen_size / 2, cube_screen_size / 2, 0, pano_l.width, pano_l.height);
  vertex(-cube_screen_size / 2, cube_screen_size / 2, 0, 0, pano_l.height);
  endShape();
  popMatrix();
  
  // down
  pushMatrix();
  translate(width / 2, height / 2 + cube_screen_size / 2, 0);
  rotateX(PI/2);
  beginShape();
  texture(pano_d);
  vertex(-cube_screen_size / 2, -cube_screen_size / 2, 0, 0, 0);
  vertex(cube_screen_size / 2, -cube_screen_size / 2, 0, pano_d.width, 0);
  vertex(cube_screen_size / 2, cube_screen_size / 2, 0, pano_d.width, pano_d.height);
  vertex(-cube_screen_size / 2, cube_screen_size / 2, 0, 0, pano_d.height);
  endShape();
  popMatrix();  
  
  // up
  pushMatrix();
  translate(width / 2, height / 2 - cube_screen_size / 2, 0);
  rotateX(-PI/2);
  beginShape();
  texture(pano_u);
  vertex(-cube_screen_size / 2, -cube_screen_size / 2, 0, 0, 0);
  vertex(cube_screen_size / 2, -cube_screen_size / 2, 0, pano_u.width, 0);
  vertex(cube_screen_size / 2, cube_screen_size / 2, 0, pano_u.width, pano_u.height);
  vertex(-cube_screen_size / 2, cube_screen_size / 2, 0, 0, pano_u.height);
  endShape();
  popMatrix();

  // back
  pushMatrix();
  translate(width / 2, height / 2, cube_screen_size / 2);
  rotateY(PI);
  beginShape();
  texture(pano_b);
  vertex(-cube_screen_size / 2, -cube_screen_size / 2, 0, 0, 0);
  vertex(cube_screen_size / 2, -cube_screen_size / 2, 0, pano_b.width, 0);
  vertex(cube_screen_size / 2, cube_screen_size / 2, 0, pano_b.width, pano_b.height);
  vertex(-cube_screen_size / 2, cube_screen_size / 2, 0, 0, pano_b.height);
  endShape();
  popMatrix();
}

//-----------------------------------------------------------------------------------------

void camera_control()
{
  if (sensorControl) {
    theta = azimuth;
    phi = pitch;
  }
  
  // pan, tilt
  float cx = width / 2 + (cube_screen_size / 2) * abs(cos(phi)) * sin(theta);
  float cy = height / 2 +  (cube_screen_size / 2) * sin(phi);
  float cz = -cube_screen_size / 2 * abs(cos(phi)) * cos(theta); 
  camera(width/2, height/2, 0, cx, cy, cz, 0, 1, 0);
  
  // zoom
  float fov_rad = radians(fov);
  float cameraZ = (height / 2.0) / tan(fov_rad/2.0);
//  perspective(fov_rad, float(width) / float(height), cameraZ / 10.0, cameraZ * 10.0);
  perspective(fov_rad, float(width) / float(height), cameraZ / 20.0, cameraZ * 10.0);
}

void mousePressed() {
  startX = mouseX;
  startY = mouseY;
  
  theta_tmp = theta;
  phi_tmp = phi;
  
  mousePressed_GUI();
}

void mouseReleased() {
  startX = -1;
  startY = -1;
  
  mouseReleased_GUI();   
}

void mouseDragged() {  
  if (startX >=0 && startY >= 0) {
    float dX = mouseX - startX;
    float dY = mouseY - startY;
    
    // 移動量をラジアンに変換
    dX = (dX / width) * PI * -1;
    dY = (dY / height) * (PI / 2) * -1;   
   
    theta = theta_tmp + dX;
    phi = phi_tmp + dY;  
  }  

  mouseDragged_GUI(); 
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == BACK) {
      // do something here for the back button behavior
      // you'll need to set keyCode to 0 if you want to prevent quitting (see above)
    } else if (keyCode == MENU) {
      // user hit the menu key, take action
      if (menu.isVisible()) {
        menu.hide();
      } else {
        menu.show();
      }
    }
  }
}

boolean isMultiScreenMode()
{
  return standAlone == false;
}

boolean isMultiScreenServer()
{
  return displayId == "center";
}

//-----------------------------------------------------------------------------------------

void onPinch(float x, float y, float d){ 
  float gain = 0.25;
  fov = constrain(fov - d * gain, 30, 120);
  
  mouseDragged_GUI();  
}

void onLongPress(float x, float y) {
  if (menu.isVisible()) {
    menu.hide();
  } else {
    menu.show();
  }
}

public boolean surfaceTouchEvent(MotionEvent event){
  super.surfaceTouchEvent(event);
  return gesture.surfaceTouchEvent(event);
}

//-----------------------------------------------------------------------------------------

// Override the parent (super) Activity class:
// States onCreate(), onStart(), and onStop() aren't called by the sketch.  Processing is entered at

//********************************************************************
// The following code is required to enable bluetooth at startup.
//********************************************************************
void onCreate(Bundle savedInstanceState) {
  super.onCreate(savedInstanceState);
  bt = new KetaiBluetooth(this);
}

void onActivityResult(int requestCode, int resultCode, Intent data) {
  bt.onActivityResult(requestCode, resultCode, data);
}
//********************************************************************

// the 'onResume()' state, and exits at the 'onPause()' state, so just override them:
void onResume() {
  super.onResume();
  initSensor(); 
  
  // start bluetooth
  bt.start(); 
}

void onPause() {
// Unregister all of our SensorEventListeners upon exit:
  super.onPause();
  exitSensor(); 
  
  // stop bluetooth
  bt.stop();
}

void initSensor(){
  sensorEventListener = new mSensorEventListener();
  //mSensorManager = (SensorManager)getSystemService(SENSOR_SERVICE); // under Android4
  context = getActivity(); // Android4+
  mSensorManager = (SensorManager)context.getSystemService(Context.SENSOR_SERVICE); // Android4+
  
  accelerometer  = mSensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
  magnetometer   = mSensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD);
  sensorAvailable = true;
  mSensorManager.registerListener(sensorEventListener, accelerometer, mSensorManager.SENSOR_DELAY_GAME);
  mSensorManager.registerListener(sensorEventListener, magnetometer, mSensorManager.SENSOR_DELAY_GAME);
}

void exitSensor(){
  if (sensorAvailable) mSensorManager.unregisterListener(sensorEventListener);
}

//-----------------------------------------------------------------------------------------

// Setup our SensorEventListener
class mSensorEventListener implements SensorEventListener{
  float[] mGravity;
  float[] mGeomagnetic;
  float orientation[] = new float[3];

  public void onSensorChanged(SensorEvent event){
    if (event.accuracy == SensorManager.SENSOR_STATUS_ACCURACY_LOW) return;
    switch (event.sensor.getType()){
      case Sensor.TYPE_MAGNETIC_FIELD:
        mGeomagnetic = event.values.clone();
        break;        
      case Sensor.TYPE_ACCELEROMETER:
        mGravity = event.values.clone();
        break;
    }

    if (mGravity != null && mGeomagnetic != null) {
      float I[] = new float[16];
      float R[] = new float[16];
      float outR[] = new float[16];
      
      if (SensorManager.getRotationMatrix(R, I, mGravity, mGeomagnetic)){
//        SensorManager.remapCoordinateSystem(R, SensorManager.AXIS_X, SensorManager.AXIS_Y, outR);
        SensorManager.remapCoordinateSystem(R, SensorManager.AXIS_X, SensorManager.AXIS_Z, outR); // 端末を両手でもつ場合
        SensorManager.getOrientation(outR, orientation);
        azimuth = orientation[0];
        pitch   = orientation[1];
        roll    = orientation[2];
      }
    }
  }

  public void onAccuracyChanged(Sensor sensor, int accuracy) {
  }
}

//-----------------------------------------------------------------------------------------

//Call back method to manage data received
void onBluetoothDataEvent(String who, byte[] data)
{
  if (testMode) {
    if (menu.isVisible() == false) { // メニュー画面でなかったら何もしない
      return;
    }
  } else {
//    if (isMultiScreenMode() == false || isMultiScreenServer() == true)) {    
    if (isMultiScreenMode() == false) { // デバッグ用にcenterでも他からのコマンドを受信する
      return;
    }
  }

  //KetaiOSCMessage is the same as OscMessage
  //   but allows construction by byte array
  KetaiOSCMessage m = new KetaiOSCMessage(data);
  if (m.isValid())
  {
    if (m.checkAddrPattern("/remoteMouse/"))
    {
      if (m.checkTypetag("iii"))
      {
        remoteMouse.x = (float)m.get(0).intValue(); // hlookat (-180 - + 180)
        remoteMouse.y = (float)m.get(1).intValue(); // vlookat (-90 - +90)
        remoteMouse.z = (float)m.get(2).intValue(); // fov
      
        if (testMode == false) {    
          // パラメータを反映
          theta = radians(remoteMouse.x);
          phi = radians(remoteMouse.y); 
          fov = remoteMouse.z;
 
          if (displayId == "left") {
            theta = theta - radians(fov);
          } else if (displayId == "right") {
            theta = theta + radians(fov);
          }
        }       
      }
    }
  }
}

String getBluetoothInformation()
{
  String btInfo = "Server Running: ";
  btInfo += bt.isStarted() + "\n";
  btInfo += "Discovering: " + bt.isDiscovering() + "\n";
  btInfo += "Device Discoverable: "+bt.isDiscoverable() + "\n";
  btInfo += "\nConnected Devices: \n";

  ArrayList<String> devices = bt.getConnectedDeviceNames();
  for (String device: devices)
  {
    btInfo+= device+"\n";
  }

  return btInfo;
}

void onKetaiListSelection(KetaiList klist)
{
  String selection = klist.getSelection();
  bt.connectToDeviceByName(selection);

  //dispose of list for now
  klist = null;
}
