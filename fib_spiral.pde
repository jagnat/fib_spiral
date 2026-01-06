import processing.svg.*;

import megamu.mesh.*;

import java.util.*;

final int numCells = 89;
final int numOuter = 34;
//final int numOuter = 24;
final int numInner = 55;

float[][] points = new float[numCells + numOuter + numInner][2];

ArrayList<HashSet<Integer>> paraGroups = new ArrayList<>();
MPolygon[] allRegions;
ArrayList<MPolygon> usedRegions;

Integer[] wiringIndices = {78, 57, 36, 15, 7, 28, 49, 70, 83, 62, 41, 20, 12, 33, 54, 75, 88, 67, 46, 25, 4, 17, 38, 59, 80, 72, 51, 30, 9, 1, 22, 43, 64, 85, 77, 56, 35, 14, 6, 27, 48, 69, 82, 61, 40, 19, 11, 32, 53, 74, 87, 66, 45, 24, 3, 16, 37, 58, 79, 71, 50, 29, 8, 0, 21, 42, 63, 84, 76, 55, 34, 13, 5, 26, 47, 68, 81, 60, 39, 18, 10, 31, 52, 73, 86, 65, 44, 23, 2};

void setup()
{
  size(800, 800);
  pixelDensity(2);
  background(0);
  //beginRecord(SVG, "output/output_"+timestamp()+".svg");
  stroke(0);
  strokeWeight(.5);
  noFill();
  translate(width/2, height/2);

  float outerRad = width / 2;
  //circle(width/2, height/2, outerRad * 2);
  final int total = numCells + numInner + numOuter;
  for (int i = 0; i < total; i++)
  {
    float f = i / float(total);
    float a = i * 1.6180339887;
    //float a = i * sqrt(2);
    
    float dist = f * outerRad;
    //float dist = sqrt(f) * outerRad;
    
    float x = -cos(a * TWO_PI) * dist;
    float y = sin(a * TWO_PI) * dist;
    
    points[i][0] = x;
    points[i][1] = y;
  }
  
  stroke(100);
  strokeWeight(1);
  textSize(28);
  
  Voronoi test = new Voronoi(points);
  
  float[][] edges = test.getEdges();
  
  println(edges.length);
  
  //for (int i = 0; i < edges.length; i++)
  //{
  //  int b = int(255 * (i / float(edges.length)));
  //  line(edges[i][0], edges[i][1], edges[i][2], edges[i][3]);
  //}
  
  allRegions = test.getRegions();
  usedRegions = new ArrayList<MPolygon>();
  JSONArray allCells = new JSONArray();
  
  // Generate parastichy groupings
  int numGroupings = 4;
  for (int i = 0; i < 4; i++) {
    paraGroups.add(new HashSet<Integer>());
  }
  
  int currentSeed = 2;
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 5; j++) {
      paraGroups.get(i).add(currentSeed);
      int paraWalk = currentSeed + 21;
      while (paraWalk < numCells) {
        paraGroups.get(i).add(paraWalk);
        paraWalk += 21;
      }
      currentSeed = (currentSeed + 13) % 21;
    }
  }
  for (int j = 0; j < 5; j++) {
    paraGroups.get(3).add(currentSeed);
    int paraWalk = currentSeed + 21;
    while (paraWalk < numCells) {
      paraGroups.get(3).add(paraWalk);
      paraWalk += 21;
    }
    currentSeed = (currentSeed + 13) % 21;
  }
  
  findOptimalStartingSeed();
  
  line(0, -1200, 0, 1200);
  line(-1200,0, 1200, 0);

  //for(int i=numInner; i<numInner + numCells; i++)
  for(int i=0; i < numInner + numCells + numOuter; i++)
  {
    
    float[][] regionCoordinates = allRegions[i].getCoords();
    //int r = int(random(155) + 100);
    //int g = int(random(155) + 100);
    //int b = int(random(155) + 100);
    if (i < numInner) {
      stroke(255, 0, 0, 40);
      continue;
    } else if (i < numInner + numCells) {
      stroke(255, 255, 255, 255);
    } else {
      stroke(0, 255, 0, 100);
      continue;
    }

    // usedRegions.add(allRegions[i]);
    
    JSONObject cellData = new JSONObject();
    float cx = points[i][0];
    float cy = points[i][1];
    cellData.setFloat("centerX", cx);
    cellData.setFloat("centerY", cy);
    JSONArray vertices = new JSONArray();
    
    float nextX = points[i + 21][0];
    float nextY = points[i + 21][1];
    float angle = atan2(nextY - cy, nextX - cx);
    cellData.setFloat("ledAngle", angle);
    
    //stroke(255, 255, 255, 255);
    //stroke(255, 255, 255, 255);
    int sz = regionCoordinates.length;
    for (int p = 0; p < sz; p++)
    {
      JSONObject vertex = new JSONObject();
      vertex.setFloat("x", regionCoordinates[p][0]);
      vertex.setFloat("y", regionCoordinates[p][1]);
      vertices.append(vertex);
      //point(regionCoordinates[p][0], regionCoordinates[p][1]);
      line(regionCoordinates[p][0], regionCoordinates[p][1],
        regionCoordinates[(p+1) % sz][0], regionCoordinates[(p+1) % sz][1]);
      strokeWeight(10);
      int idx = i - numInner;
      if (paraGroups.get(0).contains(idx)) { stroke(255, 0, 0); }
      else if (paraGroups.get(1).contains(idx)) { stroke(0, 255, 0); }
      else if (paraGroups.get(2).contains(idx)) { stroke(0, 0, 255); }
      else if (paraGroups.get(3).contains(idx)) { stroke(0, 255, 255); }
      
      //if (cx > 0 && cy > 0) { stroke(255, 0, 0); }
      //else if (cx <= 0 && cy > 0) { stroke(0, 255, 0); }
      //else if (cx > 0 && cy <= 0) { stroke(0, 255, 255); }
      //else if (cx <= 0 && cy <= 0) { stroke(0, 0, 255); }
      point(cx, cy);
      strokeWeight(1);
      stroke(255);
      int wireIdx = Arrays.asList(wiringIndices).indexOf(i - numInner);
      // text("" + (i - numInner), cx, cy);
      text("" + wireIdx, cx, cy);
    }
    
    cellData.setJSONArray("vertices", vertices);
    int quadrant = -1;
    for (int q = 0; q < paraGroups.size(); q++) {
      if (paraGroups.get(q).contains(i - numInner)) {
        quadrant = q;
        break;
      }
    }
    cellData.setInt("quadrant", quadrant);
    allCells.append(cellData);

    //allRegions[i].draw(this); // draw this shape
    //break;
  }

  setupUsedRegions();
  
  // saveJSONArray(allCells, "data/voronoi_cells_" + timestamp() + ".json");
  
  //endRecord();
}

void setupUsedRegions() {
  int count = 0;
  int parastichy = 8;
  int dir = 1;
  while (count < numCells) {
    if (dir == 1) {
      for (int i = 0; i < 7; i++) {
        if (i * 21 + parastichy >= numCells) { break; }
        count += 1;
        int idx = i * 21 + parastichy;
        println("idx: " + idx);
        usedRegions.add(allRegions[idx + numInner]);
      }
    } else {
      for (int i = 6; i >= 0; i--) {
        if (i * 21 + parastichy >= numCells) { continue; }
        count += 1;
        int idx = i * 21 + parastichy;
        println("idx: " + idx);
        usedRegions.add(allRegions[idx + numInner]);
      }
    }
    dir *= -1;
    parastichy = (parastichy + 13) % 21;
  }
  // Collections.reverse(usedRegions);
}

void draw2()
{
  background(0);
  translate(width/2, height/2);

  stroke(0,0,0);
  fill(255);
  strokeWeight(3);

  int time = millis() / 50;

  int cell = time % usedRegions.size();

  for (int i = 0; i < usedRegions.size(); i++)
  {
    MPolygon region = usedRegions.get(i);
    // fill(color(random(255), random(255), random(255)));
    float inter = i / (float)usedRegions.size();
    fill(color(inter * 255, 0, (255 - inter) * 255));
    // if (i == cell) {
    //   fill(color(255, 255, 255));
    // } else {
    //   fill(color(100, 0, 0));
    // }
    float[][] coords = region.getCoords();
    beginShape();
    for (int p = 0; p < coords.length; p++) {
      vertex(coords[p][0], coords[p][1]);
    }
    vertex(coords[0][0], coords[0][1]);
    endShape();
  }
}

String timestamp() 
{
  Calendar now = Calendar.getInstance();
  return String.format("%1$ty%1$tm%1$td_%1$tH%1$tM%1$tS", now);
}

int findOptimalStartingSeed() {
  float bestScore = Float.MAX_VALUE;
  int bestStartSeed = 0;
  
  for (int startSeed = 0; startSeed < 21; startSeed++) {
    // Generate groupings with this start seed
    ArrayList<HashSet<Integer>> testGroups = new ArrayList<>();
    for (int i = 0; i < 4; i++) {
      testGroups.add(new HashSet<Integer>());
    }
    
    int seed = startSeed;
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 5; j++) {
        testGroups.get(i).add(seed);
        int paraWalk = seed + 21;
        while (paraWalk < numCells) {
          testGroups.get(i).add(paraWalk);
          paraWalk += 21;
        }
        seed = (seed + 13) % 21;
      }
    }
    for (int j = 0; j < 5; j++) {
      testGroups.get(3).add(seed);
      int paraWalk = seed + 21;
      while (paraWalk < numCells) {
        testGroups.get(3).add(paraWalk);
        paraWalk += 21;
      }
      seed = (seed + 13) % 21;
    }
    
    // Calculate worst-case diagonal across all 4 groups
    float maxDiagonal = 0;
    for (int g = 0; g < 4; g++) {
      float minX = Float.MAX_VALUE;
      float maxX = -Float.MAX_VALUE;
      float minY = Float.MAX_VALUE;
      float maxY = -Float.MAX_VALUE;
      
      for (int cellIdx : testGroups.get(g)) {
        int regionIdx = cellIdx + numInner;
        float[][] coords = allRegions[regionIdx].getCoords();
        for (int v = 0; v < coords.length; v++) {
          minX = min(minX, coords[v][0]);
          maxX = max(maxX, coords[v][0]);
          minY = min(minY, coords[v][1]);
          maxY = max(maxY, coords[v][1]);
        }
      }
      
      float diagonal = sqrt(pow(maxX - minX, 2) + pow(maxY - minY, 2));
      maxDiagonal = max(maxDiagonal, diagonal);
    }
    
    if (maxDiagonal < bestScore) {
      bestScore = maxDiagonal;
      bestStartSeed = startSeed;
    }
  }
  
  println("Optimal starting seed: " + bestStartSeed + " (max diagonal: " + bestScore + ")");
  return bestStartSeed;
}
