import SimpleOpenNI.*;

SimpleOpenNI  context;

//body center
PVector com = new PVector();                                   
PVector com2d = new PVector();    

PVector[] afterSmoothHeadPos2Ds = new PVector[100];
float[] afterSmoothHeadRots = new float[100];

float posSmoothRate = 0.6;
float rotSmoothRate = 0.3;

float boxSize = 130;
PVector finalOffset = new PVector(0, 13, 0); 


PGraphics render;

//smooth

boolean sketchFullScreen() {
  return true;
}

void setup()
{
  size(displayWidth, displayHeight, P3D);
  context = new SimpleOpenNI(this);
  if (context.isInit() == false)
  {
    println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
    exit();
    return;
  }

  // enable depthMap generation 
  context.enableDepth();
  context.enableRGB();

  // enable skeleton generation for all joints
  context.enableUser();
  smooth();

  for (int i=0; i<afterSmoothHeadPos2Ds.length; i++) {
    afterSmoothHeadPos2Ds[i] = new PVector();
  }


  render = createGraphics(640, 480, P3D);
}

void draw()
{

  noCursor();
  // update the cam
  context.update();
  render.beginDraw();
  render.background(context.rgbImage());
  render.filter(GRAY);

  // draw the skeleton if it's available
  int[] userList = context.getUsers();
  for (int i=0; i<userList.length; i++)
  {
    if (context.isTrackingSkeleton(userList[i]))
    {
      //stroke(userClr[ (userList[i] - 1) % userClr.length ] );
      drawSkeleton(userList[i]);
    }      

    // draw the center of mass
    if (context.getCoM(userList[i], com))
    {
      context.convertRealWorldToProjective(com, com2d);
      render.stroke(255);
      render.strokeWeight(1);
      render.beginShape(LINES);
      render.vertex(com2d.x, com2d.y - 5);
      render.vertex(com2d.x, com2d.y + 5);

      render.vertex(com2d.x - 5, com2d.y);
      render.vertex(com2d.x + 5, com2d.y);
      render.endShape();
    }
  }
  render.endDraw();


  imageMode(CENTER);

  image(render, width/2, height/2, (render.width*height)/render.height, height);
}

// draw the skeleton with the selected joints
void drawSkeleton(int userId)
{

  PVector headPos = new PVector();
  PVector headPos2D = new PVector();
  PVector leftShouldPos = new PVector();
  PVector rightShouldPos = new PVector();


  context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_HEAD, headPos);


  context.getJointPositionSkeleton(userId, 
  SimpleOpenNI.SKEL_LEFT_SHOULDER, leftShouldPos);
  context.getJointPositionSkeleton(userId, 
  SimpleOpenNI.SKEL_RIGHT_SHOULDER, rightShouldPos);


  context.convertRealWorldToProjective(headPos, headPos2D);

  afterSmoothHeadPos2Ds[userId] = PVector.add(afterSmoothHeadPos2Ds[userId], 
  PVector.mult(PVector.sub(headPos2D, afterSmoothHeadPos2Ds[userId]), posSmoothRate));

  render.pushMatrix();
  render.stroke(255, 20);
  render.fill(0, 240);

  render.translate(afterSmoothHeadPos2Ds[userId].x  + finalOffset.x, 
  afterSmoothHeadPos2Ds[userId].y + finalOffset.y, 
  0 + finalOffset.z);


  float headRot =  -((PI/2) * (leftShouldPos.z - rightShouldPos.z))/250;



  afterSmoothHeadRots[userId] += (headRot - afterSmoothHeadRots[userId]) * rotSmoothRate;
  render.rotateY(afterSmoothHeadRots[userId]);


  render.box(boxSize * map( afterSmoothHeadPos2Ds[userId].z, 900, 1800, 1.3, 0.9));
  render.popMatrix();
}

// -----------------------------------------------------------------
// SimpleOpenNI events

void onNewUser(SimpleOpenNI curContext, int userId)
{
  println("onNewUser - userId: " + userId);
  println("\tstart tracking skeleton");

  curContext.startTrackingSkeleton(userId);
}

void onLostUser(SimpleOpenNI curContext, int userId)
{
  println("onLostUser - userId: " + userId);
}

void onVisibleUser(SimpleOpenNI curContext, int userId)
{
  //println("onVisibleUser - userId: " + userId);
}

