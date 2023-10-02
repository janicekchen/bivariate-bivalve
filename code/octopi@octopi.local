import board
import neopixel
import RPi.GPIO as GPIO
from time import sleep
GPIO.setmode(GPIO.BOARD)

pixelpin = 12
switchpin = 7

GPIO.setup(pixelpin, GPIO.OUT)
GPIO.setup(switchpin, GPIO.IN, pull_up_down = GPIO.PUD_UP)

pixels = neopixel.NeoPixel(board.D18, 18)
pixels.fill((0, 255, 0))

# while True:
#     GPIO.output(pixelpin, not GPIO.input(switchpin))
#     sleep(0.2)

