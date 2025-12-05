import processing.svg.*;

import megamu.mesh.*;

import java.util.*;

final int numCells = 89;
final int numOuter = 34;
//final int numOuter = 24;
final int numInner = 55;

float[][] points = new float[numCells + numOuter + numInner][2];
ArrayList<HashSet<Integer>> paraGroups = new ArrayList<>();
MPolygon[] myRegions;

void setup()
{
  size(1200, 1200);
  background(0);
  //beginRecord(SVG, "output/output_"+timestamp()+".svg");
  stroke(0);
  strokeWeight(.5);
  noFill();
  translate(width/2, height/2);
  

  float outerRad = 580;
  //circle(width/2, height/2, outerRad * 2);
  final int total = numCells + numInner + numOuter;
  for (int i = 0; i < total; i++)
  {
    float f = i / float(total);
    float a = i * 1.6180339887;
    //float a = i * sqrt(2);
    
    float dist = f * outerRad;
    //float dist = sqrt(f) * outerRad;
    
    float x = cos(a * TWO_PI) * dist;
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
  
  myRegions = test.getRegions();
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
  
  //line(0, -1200, 0, 1200);
  //line(-1200,0, 1200, 0);

  //for(int i=numInner; i<numInner + numCells; i++)
  for(int i=0; i < numInner + numCells + numOuter; i++)
  {
    
    float[][] regionCoordinates = myRegions[i].getCoords();
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
      //text("" + (i - numInner), cx, cy);
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

    //myRegions[i].draw(this); // draw this shape
    //break;
  }
  
  saveJSONArray(allCells, "data/voronoi_cells_" + timestamp() + ".json");
  
  //endRecord();
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
        float[][] coords = myRegions[regionIdx].getCoords();
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
