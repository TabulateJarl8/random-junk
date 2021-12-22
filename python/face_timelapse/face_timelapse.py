import cv2
import pathlib
import sys
import selectinwindow

descaling_factor = 4
sys.setrecursionlimit(10 ** 9)

def confirm_eye_coordinates(eyes, image):
	imgheight, imgwidth = image.shape[:2]
	resizedImg = cv2.resize(image, (int(imgwidth / descaling_factor), int(imgheight / descaling_factor)), interpolation = cv2.INTER_AREA)

	resized_eyes = [value / 4 for value in eyes]

	cv2.namedWindow('Indicate Eye')
	rect1 = selectinwindow.DragRectangle(resizedImg, 'Indicate Eye', resizedImg.shape[:2][1], resizedImg.shape[:2][0])
	cv2.setMouseCallback('Indicate Eye', selectinwindow.dragrect, (rect1, resized_eyes))
	cv2.imshow('Indicate Eye', resizedImg)
	cv2.waitKey(0)

	print(rect1.outRect)

def find_eye(image, outfile_name = 'image.png'):
	detector = cv2.CascadeClassifier('haarcascade_eye.xml')

	eyes = detector.detectMultiScale(image, 1.3, 5)

	for (x, y, w, h) in eyes:
		cv2.rectangle(image, (x, y), (x+w, y+h), (0, 255, 0), 2)

	confirm_eye_coordinates(eyes, image)

# i = 0
# for file in pathlib.Path('Face/').glob('*.jpg'):
# 	img = cv2.imread(str(file.resolve()))
# 	find_eye(img, outfile_name=f'image{i}.jpg')
# 	i += 1
img = cv2.imread('image17.jpg')
find_eye(img)