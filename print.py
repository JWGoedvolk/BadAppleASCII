import os
import time
#import wave
#import sys
#import pyaudio
#import winsound
#import playsound
#import pygame
#import threading

#pygame.init()
#pygame.mixer.music.load('badapple.mp3')
#chunk = 1024
#wf = wave.open('dong-fang-bad-apple-pv-ying-hui.wav', 'rb')
#p = pyaudio.PyAudio()
#stream = p.open(format =
#                p.get_format_from_width(wf.getsampwidth()),
#                channels = wf.getnchannels(),
#                rate = wf.getframerate(),
#                output = True)
#def thread_function():
#    data = wf.readframes(chunk)
#    while data:
#        stream.write(data)
#        data = wf.readframes(chunk)
    #playsound.playsound('badapple.mp3')

imgs = os.listdir("C:/Users/janwi/AppData/Roaming/LOVE/bad apple") #find all the files in the love2d save directory
txt = [] #will store the frames
for i in range(len(imgs)): #go through each file
    with open(f"C:/Users/janwi/AppData/Roaming/LOVE/bad apple/{imgs[i]}") as f: #open and read it
        frameH = 0
        text = [] #store the current frame
        for x in f: #go through the file line by line
            frameH += 1
            #if frameH >= 51:
            #    text.append(x.strip('\n')) #add the line to the current frame
            #else:
            #    text.append(x)
            text.append(x)
            # print(x.strip('\r\n'))
        # print(frameH)
        txt.append(text) #add the current frame to the array of frames
        # print(text)

#txt.reverse()
#print(txt)

#winsound.PlaySound('dong-fang-bad-apple-pv-ying-hui', winsound.SND_ASYNC | winsound.SND_ALIAS)


#pygame.mixer.music.play(-1)

#x = threading.Thread(target=thread_function())
#x.start()
# for i in range(51):
    # print(i)
def show():
    for i in range(len(txt)): #go through all the frames
        for j in range(len(txt[i])):
            print(txt[i][j], end=f'{i}') #print the frame
        time.sleep(1) #wait a bit before showing the next frame

show()
#print(txt[1]) #print the frame

#wf.close()
#stream.close()
#p.terminate()