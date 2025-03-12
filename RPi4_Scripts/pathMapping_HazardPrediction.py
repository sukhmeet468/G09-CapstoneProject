import numpy as np
import json
import bisect
import copy
import os
import shutil
import joblib
import pandas as pd

def predict_entry(model, entry):
    # Check confidence threshold (>=90%)
    if entry['confidence'] < 90:
        entry['prediction'] = "Low confidence (<90%)"
        return entry
    
    # Create a DataFrame with feature names matching training data
    features = pd.DataFrame([{
        'distance': entry['distance'],
        'confidence': entry['confidence'],
        'latitude': entry['latitude'],
        'longitude': entry['longitude']
    }])
    
    # Predict danger level
    prediction = model.predict(features)[0]
    entry['prediction'] = str(prediction)  # Convert to string for JSON
    return entry

class Node:
	def __init__(self, name, data):
		self.name = name
		self.data = data
		self.next = None
		self.prev = None

class Compass:
	def __init__(self, rotation="CW", data=None):
		self.head = None
		if rotation == "CW":
			self.append("N", [0,1])
			self.append("NE", [1,1])
			self.append("E", [1,0])
			self.append("SE", [1,-1])
			self.append("S", [0,-1])
			self.append("SW", [-1,-1])
			self.append("W", [-1,0])
			self.append("NW", [-1,1])
		elif rotation == "CCW":
			self.append("N", [0,1])
			self.append("NW", [-1,1])
			self.append("W", [-1,0])
			self.append("SW", [-1,-1])
			self.append("S", [0,-1])
			self.append("SE", [1,-1])
			self.append("E", [1,0])
			self.append("NE", [1,1])
		if data:
			self.setHead(data)

	def setHead(self, data):
		while self.head.data[0] != data[0] or self.head.data[1] != data[1]:
				self.head = self.head.next

	# Insert a node at the end of the list
	def append(self, name, data):
		new_node = Node(name, data)
		if not self.head:  # If the list is empty
			self.head = new_node
			new_node.next = new_node  # Point to itself (circular reference)
			new_node.prev = new_node
		else:
			last = self.head.prev  # The previous node to the head
			last.next = new_node  # Link the last node to the new node
			new_node.prev = last  # Link the new node back to the last node
			new_node.next = self.head  # Link the new node to the head
			self.head.prev = new_node  # Link the head back to the new node

	# Print the list from head to tail (forward traversal)
	def print_forward(self):
		if not self.head:
			print("List is empty")
			return

		current = self.head
		while True:
			print(current.name, end=" -> ")
			current = current.next
			if current == self.head:
				break
		print("... (circular)")

	# Print the list from tail to head (backward traversal)
	def print_backward(self):
		if not self.head:
			print("List is empty")
			return

		current = self.head  # Start from the last node
		while True:
			print(current.name, end=" -> ")
			current = current.prev
			if current == self.head:
				break
		print("... (circular)")

HAZ_SIZE_MUL = 2
MAX_RECUR = 512

recurCnt = 0
itrCnt = 0

def extractData(data, confidence=90):
	filterData = data[:]
	for i in range(len(data)):
		if data[i]["confidence"] < confidence or data[i]["confidence"] > 100:
			filterData.remove(data[i])
	
	coor_vals = []
	z_vals = []
	for reading in filterData:
		coor_vals.append([reading["longitude"], reading["latitude"]])
		z_vals.append(-reading["distance"])

	return coor_vals, z_vals, filterData

# Calculate Weights from x, y, and z samples points
# mu: constant 0.03
# sample_coors 	(n,2): list of coors from readings
# z 			(n,1): list of depths from readings
def calcWeights(sample_coors, z, mu):
	# sample_mat (n,2)*(2,n) = (n,n)
	sample_mat = np.matmul(sample_coors, sample_coors.transpose())
	# sample_diag (n,1)
	sample_diag = np.diagonal(sample_mat)
	# X_sqr, Y_sqr (n,n)
	X_sqr, Y_sqr = np.meshgrid(sample_diag, sample_diag)
	# gramMatrix (n,n)
	gramMatrix = np.exp(-1/mu * (X_sqr - 2*sample_mat + Y_sqr))
	# weights (n,1)
	weights = np.matmul(np.linalg.pinv(gramMatrix), z)
	
	return weights

# Interpolate z values from grid of x and y points
# mu: constant 0.03
# X 			(m,p): longitude matrix
# Y 			(m,p): latitude matrix
# w 			(n,1): weights
# sample_coors 	(n,2): list of coors from readings
def interpolate(X, Y, w, sample_coors, mu):
	# interp_coors (m x p, 2)
	interp_coors = np.array([X.flatten()[:], Y.flatten()[:]]).transpose()
	# sample_mat (n,2)*(2,n) = (n,n)
	sample_mat = np.matmul(sample_coors, sample_coors.transpose())
	# sample_diag (n,1)
	sample_diag = np.diagonal(sample_mat)
	# interp_mat (m x p, 2)*(m x p, n) = (m x p, m x p)
	interp_mat = np.matmul(interp_coors, interp_coors.transpose())
	# interp_diag (m x p, 1)
	interp_diag = np.diagonal(interp_mat)
	# Y_sqr, X_sqr (n, m x p)
	Y_sqr, X_sqr = np.meshgrid(interp_diag, sample_diag)
	w = w.reshape((1,w.size))
	# gramMatrix (n, m x p)
	gramMatrix = np.exp(-1/mu * (X_sqr - 2*np.matmul(sample_coors, interp_coors.transpose()) + Y_sqr))
	# z_vals (1, n)*(n, m x p) = (1, m x p) which is reshaped to (m,p)
	z_vals = np.matmul(w, gramMatrix).reshape(X.shape)

	return z_vals

def normSamples(coor_vals):
	xyMin = np.min(coor_vals, axis=0) #[min xVals, min yVals]
	xyMax = np.max(coor_vals, axis=0) #[max xVals, max yVals]
	
	# all x values will be between 0 and 1
	# all y values will be between 0 and 1
	coor_vals = (coor_vals - xyMin) / (xyMax - xyMin) #translate and normalize

	return coor_vals, xyMin, xyMax

def rbfInterpolate(X, Y, coor_vals, z_vals, mu):
	weights = calcWeights(coor_vals, z_vals, mu)
	z = interpolate(X, Y, weights, coor_vals, mu)

	return z

def addHazards(data, lat, lon, depthMap):
	for i in range(len(data)):
		if data[i].get('prediction') is not None and data[i]['prediction'] != 0:
			close_lat = findClosest(lat, data[i]['latitude'])
			close_lon = findClosest(lon, data[i]['longitude'])

			try:
			    prediction = float(data[i]['prediction'])
			    width = max(int((prediction * HAZ_SIZE_MUL / 100) * depthMap.shape[1]), 1)
			    length = max(int((prediction * HAZ_SIZE_MUL / 100) * depthMap.shape[0]), 1)
			except ValueError:
			    # Handle the case where conversion fails
			    print(f"Invalid prediction value: {data[i]['prediction']}")

			startIdx = [max(close_lon-width, 0), max(close_lat-length, 0)]
			endIdx = [min(close_lon+width, depthMap.shape[1]), min(close_lat+length, depthMap.shape[0])]

			depthMap[startIdx[1]:endIdx[1], startIdx[0]:endIdx[0]] = 0
	return depthMap

def findClosest(arr, target):
    # Special case: if the array is empty, return None
    if len(arr) == 0:
        return None
    
    # Use binary search to find the closest position
    pos = bisect.bisect_left(arr, target)
    
    # If the position is at the end of the array, return the index of the last element
    if pos == len(arr):
        return len(arr) - 1
    
    # Compare the element at the found position and the one before it (if possible)
    if pos > 0 and abs(arr[pos - 1] - target) <= abs(arr[pos] - target):
        return pos - 1
    else:
        return pos

def updateIdx(currIdx, nextIdx, endIdx, compass, route):
	step = findStep(nextIdx, endIdx)
	
	currIdx[:] = nextIdx[:]
	route.append([currIdx[0], currIdx[1]])
	if currIdx[0] == endIdx[0] and currIdx[1] == endIdx[1]:
		return True
	compass.setHead(step)

	return False

def getNextIdx(currIdx, nextIdx, maxIdx, step):
	nextIdx[0] = currIdx[0] + step[0]
	nextIdx[1] = currIdx[1] + step[1]
	if nextIdx[0] >= maxIdx[0] or nextIdx[0] < 0 or nextIdx[1] >= maxIdx[1] or nextIdx[1] < 0:
		return None
	return nextIdx

def routing(endIdx, depthMap, minDepth, route, compass, firstCollision):
	global recurCnt, itrCnt
	if recurCnt >= MAX_RECUR or itrCnt >= depthMap.shape[0]*depthMap.shape[1]:
		return None
	recurCnt += 1
	
	MAX_IDX = [depthMap.shape[1], depthMap.shape[0]]
	MIN_MOMENTUM = int(max(depthMap.shape) * 0.1)

	foundEnd = False
	movDir = compass.head
	currIdx = [route[-1][0], route[-1][1]]
	nextIdx = [None,None]
	momentum = 0
	# print("max", MAX_IDX)
	while foundEnd == False:
		itrCnt += 1
		nextIdx = getNextIdx(currIdx, nextIdx, MAX_IDX, movDir.data)
		if nextIdx == None:
			return None
		# print(currIdx, "--1->", nextIdx)
		# print("depth:", depthMap[nextIdx[1], nextIdx[0]])
		if depthMap[nextIdx[1], nextIdx[0]] < minDepth:
			foundEnd = updateIdx(currIdx, nextIdx, endIdx, compass, route)
			movDir = compass.head
			if momentum >= MIN_MOMENTUM:
				firstCollision = True
			else:
				momentum += 1
		elif firstCollision == True:
			#branch
			routeOne = routing(endIdx, depthMap, minDepth, route[:], Compass(rotation="CW", data=movDir.data), firstCollision=False)
			routeTwo = routing(endIdx, depthMap, minDepth, route[:], Compass(rotation="CCW", data=movDir.data), firstCollision=False)
			
			if routeOne == None and routeTwo == None:
				return None
			elif routeOne == None:
				return routeTwo
			elif routeTwo == None:
				return routeOne
			else:
				lenOne = len(routeOne)
				lenTwo = len(routeTwo)
				if lenOne <= lenTwo:
					return routeOne
				else:
					return routeTwo
		elif firstCollision == False:
			#trace
			foundEscape = False
			newDir = compass.head.next.next
			while foundEscape == False:
				itrCnt += 1
				foundNext = False
				newDir = newDir.prev
				# print("newDir:", newDir.name)
				while foundNext == False:
					nextIdx = getNextIdx(currIdx, nextIdx, MAX_IDX, newDir.data)
					if nextIdx == None:
						return None
					if depthMap[nextIdx[1], nextIdx[0]] >= minDepth:
						newDir = newDir.next
					else:
						foundNext = True
				# print(currIdx, "--2->", nextIdx)
				foundEnd = updateIdx(currIdx, nextIdx, endIdx, compass, route)
				if movDir.name != compass.head.name:
					movDir = compass.head
					if movDir.data[0] == -newDir.data[0] and movDir.data[1] == -newDir.data[1]:
						newDir = compass.head.next.next
					else:
						newDir = compass.head.next
					# print("movDir:", movDir.name)

				if foundEnd == True:
					foundEscape = True

				if newDir.name == movDir.name:
					foundEscape = True
			momentum = 0

	return route

def findCoor(currIdx, endIdx, step, depthMap, minDepth):
	while depthMap[currIdx[1], currIdx[0]] >= minDepth:
		currIdx[1] += step[1]
		currIdx[0] += step[0]
		if currIdx[1] == endIdx[1]:
			step[1] = 0
		if currIdx[0] == endIdx[0]:
			step[0] = 0
		if currIdx[1] == endIdx[1] and currIdx[0] == endIdx[0]:
			break
			
	return currIdx

def findStep(currIdx, endIdx):
	step = [None,None]
	if currIdx[1] < endIdx[1]:
		step[1] = 1
	elif currIdx[1] > endIdx[1]:
		step[1] = -1
	else:
		step[1] = 0
	if currIdx[0] < endIdx[0]:
		step[0] = 1
	elif currIdx[0] > endIdx[0]:
		step[0] = -1
	else:
		step[0] = 0

	return step

def findRoute(startCoor, endCoor, lat, lon, depthMap, minDepth):
	close_lat_start = findClosest(lat, startCoor[0])
	close_lon_start = findClosest(lon, startCoor[1])
	close_lat_end = findClosest(lat, endCoor[0])
	close_lon_end = findClosest(lon, endCoor[1])

	startIdx = [close_lon_start, close_lat_start]
	endIdx = [close_lon_end, close_lat_end]

	step = findStep(startIdx, endIdx)

	startIdx = findCoor(startIdx, endIdx, [step[0], step[1]], depthMap, minDepth)
	endIdx = findCoor(endIdx, startIdx, [-step[0], -step[1]], depthMap, minDepth)

	route = [[startIdx[0],startIdx[1]]]
	route = routing(endIdx, depthMap, minDepth, route, Compass(data=step), firstCollision=True)
	if route:
		routeCoor = []
		for coor in route:
			routeCoor.append([lat[coor[1]], lon[coor[0]]])
		return routeCoor

	return None
    
def runhazardalg(model, data):
	# Add predictions to each entry
	updated_data = [predict_entry(model, entry) for entry in data]
	return updated_data

def process_file(filename, filepath, model):
    full_path = os.path.join(filepath, filename)

    # Skip files already processed
    if "PathMap_Prediction_Completed" in filename:
        return

    print(f"Checking file: {filename}")

    # Try to read existing data from the file
    existing_data = []
    if os.path.exists(full_path):
        try:
            with open(full_path, "r") as f:
                existing_data = json.load(f)  # Load as list
        except (json.JSONDecodeError, ValueError):
            print(f"Skipping {filename}: File is empty or not in JSON format.")
            return  # Skip processing if file is unreadable

    # If there's no data in the file, skip processing
    if not existing_data:
        print(f"Skipping {filename}: No data found.")
        return

    print(f"Processing: {filename}")

    mu = 0.03
    trim = 0.05  # percentage to trim off the boundaries
    
    print(f"Predicting hazard for file: {filename}")
    
    # call the hazard algorithm
    predicted_data = runhazardalg(model, existing_data)
    
    print(f"Prediction Completed changed data: {predicted_data}")
    
    coor_vals, z_vals, data = extractData(predicted_data)
    
    # Normalize Points
    coor_vals_norm, xyMin, xyMax = normSamples(coor_vals)
    
    horz = xyMax[0] - xyMin[0]
    vert = xyMax[1] - xyMin[1]
    
    if horz > vert:
	    xValsSize = max(100, coor_vals_norm.shape[0])
	    yValsSize = int(xValsSize * (vert/horz))
    else:
	    yValsSize = max(100, coor_vals_norm.shape[0])
	    xValsSize = int(yValsSize * (horz/vert))
	
    x_vals = np.linspace(0,1,xValsSize)
    y_vals = np.linspace(0,1,yValsSize)
    X_norm,Y_norm = np.meshgrid(x_vals, y_vals)
    
    # matrix of depth values
    Z_interp = rbfInterpolate(X_norm, Y_norm, coor_vals_norm, z_vals, mu)
    # matrix of longitudes 
    X_norm = (X_norm * (xyMax[0] - xyMin[0])) + xyMin[0]
    # matrix of latitudes
    Y_norm = (Y_norm * (xyMax[1] - xyMin[1])) + xyMin[1]
    
    lats = Y_norm[:,0]
    lons = X_norm[0,:]
    
    Z_interp = addHazards(data, lats, lons, Z_interp)
    
    # apply trim
    xtrim = max(int(xValsSize * trim), 1)
    ytrim = max(int(yValsSize * trim), 1)
    
    lats = lats[ytrim:-ytrim]
    lons = lons[xtrim:-xtrim]
    X_norm = X_norm[ytrim:-ytrim, xtrim:-xtrim]
    Y_norm = Y_norm[ytrim:-ytrim, xtrim:-xtrim]
    Z_interp = Z_interp[ytrim:-ytrim, xtrim:-xtrim]
    
    minDepth = -100
    startCoor = [lats[-1], lons[0]]
    endCoor = [lats[0], lons[-1]]
    route = np.array(findRoute(startCoor[:], endCoor[:], lats, lons, Z_interp, minDepth))
	
    print(f"Route from Path Mapping Algorithm is: {route}")

    if route is not None and len(route) > 0:
        new_filename = f"PathMap_Prediction_Completed_{filename}"
        new_filepath = os.path.join(filepath, new_filename)

        # Append new route to existing data
        predicted_data.append(route.tolist())  

        # Save the updated data in JSON format
        with open(new_filepath, "w") as f:
            json.dump(predicted_data, f, indent=4)

        print(f"Saved processed file: {new_filename}")

        # Delete the original file
        os.remove(full_path)
        print(f"Deleted original file: {filename}")

import boto3
import os
from botocore.exceptions import NoCredentialsError

# Function to download a file from AWS S3 to a local folder
def download_from_s3(bucket_name, object_name, local_folder):
    # AWS credentials for S3 access
    aws_access_key_id = "please insert your aws access key id here...."
    aws_secret_access_key = "please insert your aws secret access ket here....."
    
    # Initialize S3 client with provided credentials
    s3 = boto3.client(
        's3',
        aws_access_key_id=aws_access_key_id,
        aws_secret_access_key=aws_secret_access_key
    )
    
    # Ensure the local folder exists
    if not os.path.exists(local_folder):
        os.makedirs(local_folder)
    
    # Construct the local file path
    local_file_path = os.path.join(local_folder, os.path.basename(object_name))
    
    try:
        # Attempt to download the file from S3
        s3.download_file(bucket_name, object_name, local_file_path)
        print(f"File downloaded from S3: {local_file_path}")
    except FileNotFoundError:
        print("The local folder path was not found.")
    except NoCredentialsError:
        print("Credentials not available or incorrect.")
    except Exception as e:
        print(f"An error occurred: {e}")

def main():
    # call the function to check the file from AWS and save it to /home/g9pi/Downloads/Hazard Differentiation Model File/ with the name svm_model_g09.pkl
    download_from_s3(
	bucket_name='g9capstoneiotapp-storage-uniqueusercertsa9559-dev',
	object_name='public/MachineLearningModel/svm_model_g09.pkl',
	local_folder='/home/g9pi/Downloads/Hazard Differentiation Model File/'
	)
    
    # Load the trained model
    model = joblib.load('/home/g9pi/Downloads/Hazard Differentiation Model File/svm_model_g09.pkl')
    
    filepath = "/home/g9pi/Downloads/readyToUpload"
    'sudo /home/g9pi/venv/bin/python /home/g9pi/Downloads/pathMapping_HazardPrediction.py'

    while True:
        files = os.listdir(filepath)

        for file in files:
            if file.endswith(".txt"):
                process_file(file, filepath, model)

if __name__ == "__main__":
    main()
