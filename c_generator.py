import json
import math

try:
    with open("data/voronoi_cells_251201_230731.json", 'r') as f:
        cells_data = json.load(f)
except FileNotFoundError:
    print("ERROR: JSON data file not found. Run the Processing sketch first.")
    exit()

all_x = [cell['centerX'] for cell in cells_data]
all_y = [cell['centerY'] for cell in cells_data]
min_x, max_x = min(all_x), max(all_x)
min_y, max_y = min(all_y), max(all_y)

# Calculate center of the entire pattern
center_x = 0
center_y = 0

print(f"Center: ({center_x}, {center_y})")

# Find maximum distance from center
max_distance = 0
for cell in cells_data:
    dx = cell['centerX'] - center_x
    dy = cell['centerY'] - center_y
    distance = math.sqrt(dx*dx + dy*dy)
    max_distance = max(max_distance, distance)

print(f"Max distance from center: {max_distance}")

lut = [78, 57, 36, 15, 7, 28, 49, 70, 83, 62, 41, 20, 12, 33, 54, 75, 88, 67, 46, 25, 4, 17, 38, 59, 80, 72, 51, 30, 9, 1, 22, 43, 64, 85, 77, 56, 35, 14, 6, 27, 48, 69, 82, 61, 40, 19, 11, 32, 53, 74, 87, 66, 45, 24, 3, 16, 37, 58, 79, 71, 50, 29, 8, 0, 21, 42, 63, 84, 76, 55, 34, 13, 5, 26, 47, 68, 81, 60, 39, 18, 10, 31, 52, 73, 86, 65, 44, 23, 2]

print()
print("const float led_positions[NUM_LEDS][2] = {")
for i in lut:
    point = cells_data[i]
    # Center and normalize based on max distance
    px = -(point['centerX'] - center_x) / max_distance
    py = -(point['centerY'] - center_y) / max_distance
    print(f"  {{{px:.6f}f, {py:.6f}f}},")
print("};")