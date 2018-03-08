import SimpleOpenNI.*;

SimpleOpenNI  context;

//body center
PVector com = new PVector();                                   
PVector com2d = new PVector();    


PVector[] afterSmoothHeadPos2Ds = new PVector[100];
float[] afterSmoothHeadRots = new float[100];



float posSmoothRate = 0.7;
float rotSmoothRate = 0.1;

//smooth

void setup()
{
  size(640, 480, P3D);
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
}

void draw()
{
  // update the cam
  context.update();
  background(context.rgbImage());
  filter(GRAY);

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
      stroke(255);
      strokeWeight(1);
      beginShape(LINES);
      vertex(com2d.x, com2d.y - 5);
      vertex(com2d.x, com2d.y + 5);

      vertex(com2d.x - 5, com2d.y);
      vertex(com2d.x + 5, com2d.y);
      endShape();
    }
  }
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

  pushMatrix();
  stroke(255, 20);
  fill(0, 230);
  translate(afterSmoothHeadPos2Ds[userId].x, afterSmoothHeadPos2Ds[userId].y + 15, 0);
  float headRot = ((PI/2) * (leftShouldPos.z - rightShouldPos.z))/200;
  afterSmoothHeadRots[userId] += (headRot - afterSmoothHeadRots[userId]) * rotSmoothRate;
  rotateY(afterSmoothHeadRots[userId]);


  box(130 * map( afterSmoothHeadPos2Ds[userId].z, 900, 1800, 1.5, 0.7));
  popMatrix();
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