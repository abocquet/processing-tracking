import processing.video.*;
import java.util.Iterator;

/* CHOOSE YOUR EFFECT 
 
 1: Get center of main moving regions
 2: Get the detail of moving regions
 3: Get the detail of modified pixels
 4: Remove the image
 5: Get only modified pixels
 6: Get only modified regions
 
 */
int coolEffect =  2 ;

PImage prev ;
Capture cam ;

int threshold = 50 ;
int children_threshold = 10 ;
int blob_scale = 40 ;
int frame_padding = 40 ;

int tigers = 1 ;

boolean[][] liste_pixels ;
ArrayList<Blob> blobs ;
MasterBlob[] master_blobs ;

void setup() {

  cam = new Capture(this, 640, 480, 60);
  prev = createImage(cam.width, cam.height, RGB);
  size(cam.width, cam.height);

  cam.start();

  liste_pixels = new boolean[cam.width][cam.height] ;
  blobs = new ArrayList<Blob>() ;
  master_blobs = new MasterBlob[tigers]; 

  for (int i = 0; i < master_blobs.length; i++) { 
    master_blobs[i] = new MasterBlob();
  }
}

boolean sketchFullScreen() {
  return false;
}

void keyPressed() {

  if (keyCode >= 49 && keyCode <= 54) {
    coolEffect = keyCode - 48 ;
  }
}

void draw() {

  if (cam.available()) {
    prev.copy(cam, 0, 0, cam.width, cam.height, 0, 0, cam.width, cam.height); // Before we read the new frame, we always save the previous frame for comparison!
    prev.updatePixels();
    cam.read();
  }

  background(0);
  if (coolEffect < 4)
  {
    image(cam, 0, 0);
  }

  loadPixels();
  cam.loadPixels();
  prev.loadPixels();

  liste_pixels = diff(cam, prev);

  for (int y = 0; y < liste_pixels[0].length; y++ ) {
    for (int x = 0; x < liste_pixels.length; x++ ) {
      //pixels[x + y*liste_pixels.length] = liste_pixels[x][y] ? color(255) : color(0);

      if (liste_pixels[x][y] && coolEffect >= 3 && coolEffect <= 5) {
        pixels[x + y*liste_pixels.length]=color(255);
      }
      if (liste_pixels[x][y]) {
        boolean owned = false ;
        int i = 0;

        while (!owned && i < blobs.size ()) {
          owned = blobs.get(i).has(x, y);
          i++ ;
        }

        if (!owned) { 
          blobs.add(new Blob(x, y)) ;
        }
      }
    }
  }

  updatePixels();

  if ((coolEffect >= 2 && coolEffect <= 4)|| coolEffect ==  6)
  {
    for (int i = 0; i < blobs.size (); i ++)
    {
      blobs.get(i).draw();
    }
  }

  while (blobs.size () > 0) {
    MasterBlob current = new MasterBlob(blobs.get(0));

    if (current.m_blobs.size() > children_threshold) {

      int closer = 0 ;
      for (int i = 1; i < master_blobs.length; i++)
      {
        if (current.distanceTo(master_blobs[closer]) > current.distanceTo(master_blobs[i])) {
          closer = i ;
        }
      }

      master_blobs[closer] = current;
    }
  }


  if (coolEffect >= 1)
  {
    for (int i = 0; i < master_blobs.length; i ++)
    {
      master_blobs[i].drawCenter();
    }
  }

  noFill();
  stroke(255, 0, 0);
  rect(frame_padding, frame_padding, width - 2* frame_padding, height - 2* frame_padding);
}



class MasterBlob {

  ArrayList<Blob> m_blobs ;
  MasterBlob(Blob first) {

    m_blobs = new ArrayList<Blob>() ;
    m_blobs.add(first);

    this.fulfill();
  }

  MasterBlob() {

    m_blobs = new ArrayList<Blob>() ;
    m_blobs.add(new Blob(0, 0));
  }

  Point center() {

    int x = 0, y = 0 ;

    for (int i = 0; i < m_blobs.size (); i ++)
    {
      Point center = m_blobs.get(i).center();
      x += center.m_x; 
      y += center.m_y;
    }

    x /= m_blobs.size();
    y /= m_blobs.size();

    return new Point(x, y);
  }

  void fulfill() {
    Iterator<Blob> it = blobs.iterator();
    while (it.hasNext ())
    {
      Blob current = it.next();
      int i = 0 ;
      boolean match = false ;
      while (i < m_blobs.size () && !match) {
        match = m_blobs.get(i).intersect(current) ;
        i++ ;
      }

      if (match) {
        m_blobs.add(current);
        it.remove();
        this.fulfill();
        return ;
      }
    }
  }

  boolean isIn()
  {
    Point center = center();
    return center.m_x >= frame_padding && center.m_x <= cam.width - frame_padding && center.m_y >= frame_padding && center.m_y <= cam.height - frame_padding ;
  }  


  void drawCenter() {
    if (isIn()) {
      Point center = center();
      noStroke();
      fill(255, 255, 255);
      ellipse(center.m_x, center.m_y, 25, 25);
    }
  }

  int distanceTo(MasterBlob other) {
    Point c1 = this.center(), c2 = other.center();
    return c2.m_x == 0 && c2.m_y == 0 ? 0 : (int)(pow(c1.m_x - c2.m_x, 2) + pow(c1.m_y - c2.m_y, 2)) ;
  }
}

class Blob {

  int m_x = 0, m_y = 0, m_w = 0, m_h = 0 ;

  // on laisse une petite marge pour la superposition
  boolean has(int x, int y) {
    return x > m_x + 1 && x < m_x + m_w - 1 && y > m_y + 1 && y < m_y + m_h - 1 ;
  }

  boolean valueInRange(int value, int min, int max)
  { 
    return (value >= min) && (value <= max);
  }

  boolean intersect(Blob other)
  {
    return (valueInRange(m_x, other.m_x, other.m_x + other.m_w) || valueInRange(other.m_x, m_x, m_x + m_w))
      && (valueInRange(m_y, other.m_y, other.m_y + other.m_h) || valueInRange(other.m_y, m_y, m_y + m_h))
        ;
  }


  Blob(int x, int y) {

    m_x = x - blob_scale/2 ;
    m_y = y - blob_scale/2;

    m_w = blob_scale ;
    m_h = blob_scale ;
  }

  Point center() {
    return new Point((int)(m_x + m_w/2), (int)(m_y + m_h/2));
  }

  void draw() {

    noFill();
    stroke(255, 0, 0);
    rect(m_x, m_y, m_w, m_h);
  }

  void drawCenter() {

    Point center = center();

    fill(255, 0, 0);
    stroke(255, 0, 0);
    ellipse(center.m_x, center.m_y, 2, 2);
  }
};


class Point {

  int m_x, m_y ;

  Point() {
    m_x = 0 ;
    m_y = 0;
  }

  Point(int x, int y) { 
    m_x = x ; 
    m_y = y;
  }
}

boolean[][] diff(PImage img1, PImage img2) {

  img1.loadPixels();
  img2.loadPixels();

  boolean[][] res = new boolean[img1.width][img1.height] ;

  // Begin loop to walk through every pixel
  for (int y = 0; y < img1.height; y ++ ) {
    for (int x = 0; x < img1.width; x ++ ) {

      int loc = x + y*img1.width;            // Step 1, what is the 1D pixel location
      color current = img1.pixels[loc];      // Step 2, what is the current color
      color previous = img2.pixels[loc]; // Step 3, what is the previous color

      // Step 4, compare colors (previous vs. current)
      float diff = dist(
      red(current), 
      green(current), 
      blue(current), 
      red(previous), 
      green(previous), 
      blue(previous)
        );

      if (diff > threshold) { 
        res[x][y] = true ;
      } else {
        res[x][y] = false ;
      }
    }
  }


  return res  ;
}

