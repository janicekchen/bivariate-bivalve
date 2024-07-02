import board
import neopixel

# initiating lights with the correct pin (GPIO12) and number of lights
pixels = neopixel.NeoPixel(board.D12, 18, brightness = 0.3)
pixels.fill((0, 0, 0))

