import SimpleOpenNI.*;

//for cube head
PVector head_position = new PVector();
PVector Shoulder_left_jointPos = new PVector();
PVector Shoulder_right_jointPos = new PVector();
PVector neck_jointPos = new PVector();
boolean handsTrackFlag = false; 
PVector handVec = new PVector();
//end for cube head

SimpleOpenNI context;

PVector      bodyCenter = new PVector();
PVector      bodyDir = new PVector();

color[]       userClr = new color[] { 
  color(255, 0, 0), 
  color(0, 255, 0), 
  color(0, 0, 255), 
  color(255, 255, 0), 
  color(255, 0, 255), 
  color(0, 255, 255)
};

void setup()
{
  size(640, 480, P3D);
  perspective(radians(45), float(width)/float(height), 10, 150000);


  context = new SimpleOpenNI(this);

  println("context init successfully");

  if (context.isInit() == false)
  {
    println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
    exit();
    return;
  }

  // disable mirror
  context.setMirror(false);
  println("set mirror successfully");
  // enable skeleton generation for all joints
  context.enableUser();
  println("enable user successfully");
  // enable ir generation
  context.enableRGB();
  println("enable rgb successfully");
}

void draw()
{

  try {

    context.update();
    PVector myPositionScreenCoords  = new PVector(); //storage device
    //convert the weird kinect coordinates to screen coordinates.
    context.convertRealWorldToProjective(handVec, myPositionScreenCoords);
    background(0, 0, 0);

    pushMatrix();
    translate(-600, -500, -1000);
    scale(3);
    image(context.rgbImage(), 0, 0);
    filter(GRAY);
    popMatrix();

    // set the scene pos
    translate(width/2, height/2, 0);
    rotateX(180);
    rotateY(0);
    scale(0.5);


    translate(0, 0, -1000);  // set the rotation center of the scene 1000 infront of the camera

    // draw the pointcloud


    // draw the skeleton if it's available
    int[] userList = context.getUsers();
    for (int i=0; i<userList.length; i++)
    {
      if (context.isTrackingSkeleton(userList[i]))
        drawSkeleton(userList[i]);


      float confident;
      confident = context.getJointPositionSkeleton(userList[i], 
        SimpleOpenNI.SKEL_HEAD, head_position);
      confident = context.getJointPositionSkeleton(userList[i], 
        SimpleOpenNI.SKEL_LEFT_SHOULDER, Shoulder_left_jointPos);
      confident = context.getJointPositionSkeleton(userList[i], 
        SimpleOpenNI.SKEL_RIGHT_SHOULDER, Shoulder_right_jointPos);
      confident = context.getJointPositionSkeleton(userList[i], 
        SimpleOpenNI.SKEL_NECK, neck_jointPos);    

      pushMatrix();
      translate(head_position.x, head_position.y, head_position.z);
      rotateY(((PI/2) * (Shoulder_left_jointPos.z - Shoulder_right_jointPos.z))/200);
      fill(0, 235);
      stroke(200);
      strokeWeight(1);
      stroke(0, 0);
      if (userList.length != 0 && head_position.z != 0) {
        box(350);
        strokeWeight(1);
      }

      popMatrix();
    }
  }
  catch(Exception e) {
    println(e);
  }
}


// draw the skeleton with the selected joints
void drawSkeleton(int userId)
{
  strokeWeight(3);

  // to get the 3d joint data
  drawLimb(userId, SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_NECK);
  drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_LEFT_SHOULDER);
  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_LEFT_ELBOW);
  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_ELBOW, SimpleOpenNI.SKEL_LEFT_HAND);

  drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_RIGHT_SHOULDER);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_RIGHT_ELBOW);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW, SimpleOpenNI.SKEL_RIGHT_HAND);

  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_TORSO);

  drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_LEFT_HIP);
  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_HIP, SimpleOpenNI.SKEL_LEFT_KNEE);
  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_KNEE, SimpleOpenNI.SKEL_LEFT_FOOT);

  drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_RIGHT_HIP);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_HIP, SimpleOpenNI.SKEL_RIGHT_KNEE);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_KNEE, SimpleOpenNI.SKEL_RIGHT_FOOT);  



  // draw body direction
  getBodyDirection(userId, bodyCenter, bodyDir);
  bodyDir.mult(200);  // 200mm length
  bodyDir.add(bodyCenter);
  //
  //  stroke(255, 200, 200);
  // 
  //  line(bodyCenter.x, bodyCenter.y, bodyCenter.z, 
  //  bodyDir.x, bodyDir.y, bodyDir.z);

  strokeWeight(1);
}

void drawLimb(int userId, int jointType1, int jointType2)
{
  PVector jointPos1 = new PVector();
  PVector jointPos2 = new PVector();
  float  confidence;



  // draw the joint position
  confidence = context.getJointPositionSkeleton(userId, jointType1, jointPos1);
  confidence = context.getJointPositionSkeleton(userId, jointType2, jointPos2);

  //pass the positions to our cubes' PVectors


  if (jointType1 == SimpleOpenNI.SKEL_LEFT_SHOULDER) {
    Shoulder_left_jointPos = jointPos1;
  }

  if (jointType1 == SimpleOpenNI.SKEL_RIGHT_SHOULDER) {
    Shoulder_right_jointPos = jointPos1;
  }

  if (jointType1 == SimpleOpenNI.SKEL_HEAD) {
    head_position = jointPos1;
  }


  stroke(255, 0, 0, confidence * 200 + 55);
  stroke(0, 0);
  line(jointPos1.x, jointPos1.y, jointPos1.z, 
    jointPos2.x, jointPos2.y, jointPos2.z);

  drawJointOrientation(userId, jointType1, jointPos1, 50);
}



void drawJointOrientation(int userId, int jointType, PVector pos, float length)
{
  // draw the joint orientation  
  PMatrix3D  orientation = new PMatrix3D();
  float confidence = context.getJointOrientationSkeleton(userId, jointType, orientation);
  if (confidence < 0.001f) 
    // nothing to draw, orientation data is useless
    return;

  pushMatrix();
  translate(pos.x, pos.y, pos.z);

  // set the local coordsys
  applyMatrix(orientation);

  // coordsys lines are 100mm long
  // x - r


  stroke(255, 0, 0, confidence * 200 + 55);
  stroke(0, 0);
  line(0, 0, 0, 
    length, 0, 0);
  // y - g


  stroke(0, 255, 0, confidence * 200 + 55);
  stroke(0, 0);
  line(0, 0, 0, 
    0, length, 0);
  // z - b    

  stroke(0, 0, 255, confidence * 200 + 55);
  stroke(0, 0);
  line(0, 0, 0, 
    0, 0, length);
  popMatrix();
}

// -----------------------------------------------------------------
// SimpleOpenNI user events




void onNewUser(SimpleOpenNI curContext, int userId)
{
  println("onNewUser - userId: " + userId);
  println("\tstart tracking skeleton");
  context.startTrackingSkeleton(userId);
}



void getBodyDirection(int userId, PVector centerPoint, PVector dir)
{
  PVector jointL = new PVector();
  PVector jointH = new PVector();
  PVector jointR = new PVector();
  float  confidence;

  // draw the joint position
  confidence = context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, jointL);
  confidence = context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_HEAD, jointH);
  confidence = context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, jointR);

  // take the neck as the center point
  confidence = context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_NECK, centerPoint);


  PVector up = PVector.sub(jointH, centerPoint);
  PVector left = PVector.sub(jointR, centerPoint);

  dir.set(up.cross(left));
  dir.normalize();
}