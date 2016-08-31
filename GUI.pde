void mousePressed_GUI()
{
  for (int i = 0; i < menu.tabs.size(); ++i) {
    Tab tab = menu.tabs.get(i);
    if (tab.header.isClicked(mouseX, mouseY)) {
      menu.openTab(tab.index);   
    }
    for (int j = 0; j < tab.buttons.size(); ++j) {
      Button b = tab.buttons.get(j);
      if (b.isClicked(mouseX, mouseY))
      {
        b.focus();
        if (b.id == "b_on") {
          sensorControl = true;
          tab_s.setInfoText("Sensor control is ON");
        } else if (b.id == "b_off") {
          sensorControl = false;
          tab_s.setInfoText("Sensor control is OFF");
        } else if (b.id == "b_discover") {
          bt.discoverDevices();
        } else if (b.id == "b_discoverable") {
          bt.makeDiscoverable();                
        } else if (b.id == "b_connect") {
          //If we have not discovered any devices, try prior paired devices
          if (bt.getDiscoveredDeviceNames().size() > 0)
            klist = new KetaiList(this, bt.getDiscoveredDeviceNames());
          else if (bt.getPairedDeviceNames().size() > 0)
            klist = new KetaiList(this, bt.getPairedDeviceNames());            
        } else if (b.id == "b_paireddevice") {
        } else if (b.id == "b_info") {
        } else if (b.id == "b_standalone") { 
          standAlone = true; 
          testMode = false;
          tab_m.setInfoText("MultiScreen=OFF");           
        } else if (b.id == "b_center") {
          standAlone = false;
          sensorControl = false;
          displayId = "center"; 
          testMode = false; 
          tab_m.setInfoText("MultiScreen=ON (center)");
          tab_s.setInfoText("Sensor control is OFF");
        } else if (b.id == "b_left") {
          standAlone = false;
          sensorControl = false;
          displayId = "left"; 
          testMode = false;  
          tab_m.setInfoText("MultiScreen=ON (left)");
          tab_s.setInfoText("Sensor control is OFF");          
        } else if (b.id == "b_right") {
          standAlone = false;
          sensorControl = false;
          displayId = "right";  
          testMode = false;
          tab_m.setInfoText("MultiScreen=ON (right)");
          tab_s.setInfoText("Sensor control is OFF");
        } else if (b.id == "b_test") {
          standAlone = false;
          sensorControl = false;
          testMode = true;
          tab_m.setInfoText("MultiScreen=TEST"); 
          tab_s.setInfoText("Sensor control is OFF");          
        }             
        lastClickedId = b.id;
      }
    }
  }  
}

void mouseDragged_GUI()
{
  if (testMode) {
    if (menu.isVisible() == false) { // メニュー画面でなかったら何もしない
      return;
    }
  } else {
    if (isMultiScreenMode() == false || isMultiScreenServer() == false) {
      return;
    }
  }
  
  //send data to everyone
  //  we could send to a specific device through
  //   the writeToDevice(String _devName, byte[] data)
  //  method.
  OscMessage m = new OscMessage("/remoteMouse/");
  
  if (testMode) {
    m.add((int)(((float)mouseX / displayWidth - 0.5) * 360));
    m.add((int)(((float)mouseY / displayHeight - 0.5) * 180));
    m.add((int)fov);    
  } else {
    m.add((int)(degrees(theta)));
    m.add((int)(degrees(phi)));
    m.add((int)fov);
  }
  
  bt.broadcast(m.getBytes());   
}

void mouseReleased_GUI()
{
  for (int i = 0; i < menu.tabs.size(); ++i) {
    Tab tab = menu.tabs.get(i);
    for (int j = 0; j < tab.buttons.size(); ++j) {
      tab.buttons.get(j).unfocus();
    }
  }  
}

void initGUI()
{
  menu = new Menu();
  tab_s = menu.addTab("t_sensor", "Sensor");
  tab_b = menu.addTab("t_bluetooth", "Bluetooth");
  tab_m = menu.addTab("t_multiscreen", "MultiScreen");
  
  tab_s.setButtonSize(width / 5, 40);
  tab_s.addButton("b_on", "On");
  tab_s.addButton("b_off", "Off");
  tab_s.setInfoText("Sensor control is OFF");
  tab_b.setButtonSize(width / 5, 40);
  tab_b.addButton("b_discover", "d");
  tab_b.addButton("b_discoverable", "b");
  tab_b.addButton("b_connect", "c"); 
  tab_b.addButton("b_paireddevice", "p");
  tab_b.addButton("b_info", "i");
  tab_m.setButtonSize(width / 5, 40);
  tab_m.addButton("b_standalone", "StandAlone"); 
  tab_m.addButton("b_center", "Center");
  tab_m.addButton("b_left", "Left");
  tab_m.addButton("b_right", "Right");
  tab_m.addButton("b_test", "TEST");  
  tab_m.setInfoText("MultiScreen=OFF"); 
  
  menu.openTab(0);
  menu.hide();
}

void drawGUI()
{
  if (lastClickedId == "b_info") {
    btInfoText = getBluetoothInformation();
  } else {
    ArrayList<String> names;
      
    if (lastClickedId == "b_paireddevice") {
      btInfoText = "Paired Devices:\n";
      names = bt.getPairedDeviceNames();    
    } else {
      btInfoText = "Discovered Devices:\n";
      names = bt.getDiscoveredDeviceNames();      
    }
    
    for (int i=0; i < names.size(); i++) {
      btInfoText += "["+i+"] "+names.get(i).toString() + "\n";
    }
  }
  
  tab_b.setInfoText(btHelpText + "\n\n" + btInfoText);
  
  menu.render();  
}

class Menu {
  boolean visible = false;
  List<Tab> tabs;
  int tabHeight = 40;
  
  Menu() {
    tabs = new ArrayList<Tab>();
  }
  
  Tab addTab(String id, String caption) {
    Tab tab = new Tab(this, id, caption);
    tab.setIndex(tabs.size());    

    tabs.add(tab);   
    return tab; 
  }
  
  void openTab(int index)
  {
    for (int i = 0; i < tabs.size(); ++i) {
      tabs.get(i).close();
    }    
    tabs.get(index).open();    
  }
  
  void render() {
    background(0); // clear
    
    if (visible == false) return;
    
    for (int i = 0; i < tabs.size(); ++i) {
      Tab tab = tabs.get(i);
      tab.render();
    }
  }
  
  void show()
  {
    visible = true;
  }
  
  void hide()
  {
    visible = false;
  }
  
  boolean isVisible()
  {
    return visible;
  }  
}

class Tab {
  boolean isOpen = false;
  int index = 0;
  Object parent;
  Button header;
  List<Button> buttons;
  int buttonWidth = 100;
  int buttonHeight = 40;
  String info;
  
  Tab(Menu menu, String id, String caption) {
    parent = menu;
    header = new Button(id);
    header.setLabel(caption);
    buttons = new ArrayList<Button>();
  }
  
  void setIndex(int index)
  {
    this.index = index;
  }
  
  void setButtonSize(int w, int h)
  {
    this.buttonWidth = w;
    this.buttonHeight = h;
  }
  
  Button addButton(String id, String label) {
    Button b = new Button(id);
    b.setLabel(label);
    b.setIndex(buttons.size());
    
    buttons.add(b);
    return b;
  }
 
  void setInfoText(String msg)
  {
    info = msg;
  }
  
  void render() { 
    int tabWidth = width / ((Menu)parent).tabs.size();
    
    header.setSize(tabWidth, ((Menu)parent).tabHeight);
    header.setPosition(tabWidth * index, 0);
    header.render();
    
    if (isOpen) {
      if (info != null) {
        text(info, 5, 65);
      }      
      for (int i = 0; i < buttons.size(); ++i) {
        Button button = buttons.get(i);
        button.setSize(buttonWidth, buttonHeight);
        button.setPosition(buttonWidth * i, height - buttonHeight);
        button.render();
      }        
    } 
  }
  
  void open()
  {
    isOpen = true;
    header.focus();
    for (int i = 0; i < buttons.size(); ++i) {
      buttons.get(i).show();
    }        
  }
  
  void close()
  {
    isOpen = false;
    header.unfocus();    
    for (int i = 0; i < buttons.size(); ++i) {
      buttons.get(i).hide();
    }      
  }  
}

class Button {
  int x, y, w, h;
  String id = "";
  String label = "";
  boolean visible = true;
  int index = 0;
  boolean isFocused = false;
  int focusColor = 96;
  
  Button(String id)
  {
    this.id = id;
  }
 
  void setIndex(int index)
  {
    this.index = index;
  }
  
  void setLabel(String label)
  {
    this.label = label;
  }
  
  void setSize(int w, int h)
  {
    this.w = w;
    this.h = h;
  }
  
  void setPosition(int x, int y)
  {
    this.x = x;
    this.y = y;
  }
    
  void render()
  {
    if (visible == false) return;

    stroke(255);
    if (isFocused) {
      fill(focusColor);
    } else {  
      noFill(); 
    }
    rect(x, y, w, h);
    fill(255);
    text(label, x + 10, y + 25);   
  }
  
  boolean isClicked(int mouseX, int mouseY)
  {
    if (visible == false) return false;
    
    if (mouseX >= x && mouseX < (x + w) && mouseY >= y && mouseY < (y + h)) { 
      return true;
    }
    return false;
  }
  
  void show()
  {
    visible = true;
  }
  
  void hide()
  {
    visible = false;
  }
 
  void focus()
  {
    isFocused = true;
  }
  
  void unfocus()
  {
    isFocused = false;
  }
}

