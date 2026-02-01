import cv2
import socket
import numpy as np
import threading 
import time 


# --- CONFIGURATION ---
# TARGET_IP = "192.168.1.XX"  <-- PUT YOUR PHONE'S IP HERE!
TARGET_IP = "192.0.0.4" # Example (Change this!)
UDP_PORT = 4242

# CAMERA SOURCE
# Use 0 for Laptop Webcam (Best for testing logic)
# Use the URL if you want to test the phone stream: 'http://192.168.../video'
SOURCE = 'http://192.0.0.4:8080/video'  #0 

class CameraBuffer:
    def __init__(self,src=0):
        self.stream = cv2.VideoCapture(src)
        self.stream.set(cv2.CAP_PROP_BUFFERSIZE, 1)
        (self.grabbed, self.frame) = self.stream.read()
        self.stopped = False

    def start(self):
        # Start the separate thread
        threading.Thread(target=self.update, args=()).start()
        return self

    def update(self):
        # Keep looping infinitely until the main thread says stop
        while True:
            if self.stopped:
                return
            # READ AND OVERWRITE IMMEDIATELY
            # This ensures 'self.frame' is always the absolute newest reality
            (self.grabbed, self.frame) = self.stream.read()

    def read(self):
        return self.frame

    def stop(self):
        self.stopped = True




# --- SETUP ---
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
cap = cv2.VideoCapture(SOURCE)
face_cascade = cv2.CascadeClassifier( 'haarcascade_frontalface_default.xml')

cam = CameraBuffer(SOURCE).start()

# Give it a second to wake up
time.sleep(1.0)



print(f">>> SENTINEL LAPTOP BRAIN ONLINE")
print(f">>> TARGETING WAIFU AT: {TARGET_IP}:{UDP_PORT}")

while True:
    frame = cam.read()
    if frame is None :
        countinue

    # 1. MIRROR (So it feels natural)
    frame = cv2.flip(frame, 0)
    #frame = cv2.rotate(frame,cv2.ROTATE_180_CLOCKWISE)
    # 2. DETECT
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    faces = face_cascade.detectMultiScale(
        gray, 
        scaleFactor=1.1, 
        minNeighbors=5, # Higher stability for laptop
        minSize=(30, 30)
    )

    # 3. DRAW & CALCULATE
    height, width = frame.shape[:2]
    screen_center_x = width // 2
    screen_center_y = height // 2

    if len(faces) > 0:
        # Pick biggest face
        (x, y, w, h) = faces[0]
        
        # DRAW THE BOX (This is what we missed!)
        cv2.rectangle(frame, (x, y), (x+w, y+h), (0, 255, 0), 2)
        
        # CALC CENTER
        face_center_x = x + (w // 2)
        face_center_y = y + (h // 2)
        cv2.circle(frame, (face_center_x, face_center_y), 5, (0, 0, 255), -1)

        # NORMALIZE
        look_x = (face_center_x - screen_center_x) / screen_center_x
        look_y = (face_center_y - screen_center_y) / screen_center_y

        # SEND TO PHONE
        msg = f"LOOK:{look_x:.2f},{look_y:.2f}"
        sock.sendto(bytes(msg, "utf-8"), (TARGET_IP, UDP_PORT))
        
        # LOG
        cv2.putText(frame, f"X:{look_x:.2f} Y:{look_y:.2f}", (10, 30), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)

    # 4. SHOW THE WINDOW
    cv2.imshow('Sentinel Debugger', frame)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()

