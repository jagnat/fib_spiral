import json
import cadquery as cq
from collections import defaultdict
import math

TOTAL_HEIGHT = 12.0  # Height of the cell walls
WALL_THICKNESS = 1.6 # Thickness of the wall structure
BASE_HEIGHT = 1.2 # height of the base plate with the led holes
LED_HOLE_DIA = 8  # Diameter for the PL9823 LED hole
TOTAL_WIDTH = 400 # in mm

PAPER_FRAME_HEIGHT = 1.0



def load_cells():
    try:
        with open("data/voronoi_cells_251201_230731.json", 'r') as f:
            cells_data = json.load(f)
    except FileNotFoundError:
        print("ERROR: JSON data file not found. Run the Processing sketch first.")
        exit()
    all_x = [v['x'] for cell in cells_data for v in cell['vertices']]
    all_y = [v['y'] for cell in cells_data for v in cell['vertices']]
    min_x, max_x = min(all_x), max(all_x)
    min_y, max_y = min(all_y), max(all_y)
    pw = max_x - min_x
    scale_factor = TOTAL_WIDTH / pw
    print(f"Scale factor: {scale_factor} min_x: {min_x} max_x: {max_x}")
    cells = []
    quads = [[], [], [], []]
    for cell in cells_data:
        # if cell['centerX'] < 0 or cell['centerY'] < 0:
        #     continue
        # if cell['quadrant'] != 3:
        #     continue
        scaled_cell = {
            'center': (
                (cell['centerX']) * scale_factor,
                (cell['centerY']) * scale_factor
            ),
            'vertices': [
                ((v['x']) * scale_factor, 
                 (v['y']) * scale_factor)
                for v in cell['vertices']
            ],
            'ledAngle': cell['ledAngle']
        }
        quads[cell['quadrant']].append(scaled_cell)
        cells.append(scaled_cell)
    return cells, quads

def generate_main_plate():
    led_hole = (
        cq.Workplane("XY")
        .sketch()
        .rect(4.7, 4.7, mode = 'a')
        .rect(2.8, 9, mode = 'a')
        .finalize()
        .extrude(TOTAL_HEIGHT)
        .union(cq.Workplane("XY").rect(8, 1.7).extrude(TOTAL_HEIGHT).translate((0.0, 1.7, 0.0)))
        .union(cq.Workplane("XY").rect(8, 1.7).extrude(TOTAL_HEIGHT).translate((0.0, -1.7, 0.0)))
    )
    
    total_shape = cq.Workplane("XY")
    for i, cell in enumerate(cells):
        vertices = cell['vertices']
        cell_shape = cq.Workplane("XY").polyline(vertices).close().extrude(TOTAL_HEIGHT)
        if i == 0:
            total_shape = cell_shape
        else:
            total_shape = total_shape.union(cell_shape)
    
    for i, cell in enumerate(cells):
        vertices = cell['vertices']
        angle = cell['ledAngle']
        cell_shape = cq.Workplane("XY").polyline(vertices).close().offset2D(-WALL_THICKNESS/2, kind='intersection').extrude(TOTAL_HEIGHT).translate((0, 0, BASE_HEIGHT))
        total_shape = total_shape.cut(cell_shape)
        total_shape = total_shape.cut(led_hole.rotate((0, 0, 0), (0, 0, 1), math.degrees(angle)).translate((cell['center'][0], cell['center'][1], 0)))
    return total_shape

def intersection_resolve_test():
    total_shape = cq.Workplane("XY")
    base_quads = [1, 1, 1, 1]
    for j, quadshapes in enumerate(quads):
        total_shape = cq.Workplane("XY")
        for i, cell in enumerate(quadshapes):
            vertices = cell['vertices']
            # cell_shape = cq.Workplane("XY").polyline(vertices).close().offset2D(WALL_THICKNESS/2, kind='intersection').extrude(TOTAL_HEIGHT)
            cell_shape = cq.Workplane("XY").polyline(vertices).close().extrude(TOTAL_HEIGHT)
            if i == 0:
                total_shape = cell_shape
            else:
                total_shape = total_shape.union(cell_shape)
        base_quads[j] = total_shape
    expanded_quads = [1, 1, 1, 1]
    for j, quadshapes in enumerate(quads):
        total_shape = cq.Workplane("XY")
        for i, cell in enumerate(quadshapes):
            vertices = cell['vertices']
            cell_shape = cq.Workplane("XY").polyline(vertices).close().offset2D(WALL_THICKNESS/2, kind='intersection').extrude(TOTAL_HEIGHT)
            # cell_shape = cq.Workplane("XY").polyline(vertices).close().extrude(TOTAL_HEIGHT)
            if i == 0:
                total_shape = cell_shape
            else:
                total_shape = total_shape.union(cell_shape)
        expanded_quads[j] = total_shape
    for j in range(4):
        expanded_quads[j] = expanded_quads[j].cut(base_quads[(j+1)%4]).cut(base_quads[(j-1)%4])
    return expanded_quads

cells, quads = load_cells()

def generate_quadrants(baseplates):
    led_hole = (
        cq.Workplane("XY")
        .sketch()
        .rect(4.7, 4.7, mode = 'a')
        .rect(2.8, 9, mode = 'a')
        .finalize()
        .extrude(TOTAL_HEIGHT)
        .union(cq.Workplane("XY").rect(8, 1.7).extrude(TOTAL_HEIGHT).translate((0.0, 1.7, 0.0)))
        .union(cq.Workplane("XY").rect(8, 1.7).extrude(TOTAL_HEIGHT).translate((0.0, -1.7, 0.0)))
    )
    total_shapes = [None] * 4
    
    for j in range(4):
        total_shape = baseplates[j]
        cells = quads[j]
        for i, cell in enumerate(cells):
            vertices = cell['vertices']
            angle = cell['ledAngle']
            cell_shape = cq.Workplane("XY").polyline(vertices).close().offset2D(-WALL_THICKNESS/2, kind='intersection').extrude(TOTAL_HEIGHT).translate((0, 0, BASE_HEIGHT))
            total_shape = total_shape.cut(cell_shape)
            total_shape = total_shape.cut(led_hole.rotate((0, 0, 0), (0, 0, 1), math.degrees(angle)).translate((cell['center'][0], cell['center'][1], 0)))
        total_shapes[j] = total_shape
    return total_shapes

shapes = intersection_resolve_test()
shapes2 = generate_quadrants(shapes)

s0, s1, s2, s3 = shapes2

# s333 = generate_main_plate()
