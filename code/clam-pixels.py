import pandas as pd
import board
import neopixel

# defining colors
green = (0, 255, 127)
red = (255, 0, 0)
orange = (255, 133, 0)

# initiating lights with the correct pin (GPIO12) and number of lights
pixels = neopixel.NeoPixel(board.D12, 18, brightness = 0.3)

# reading in data
beach_data = pd.read_csv("https://raw.githubusercontent.com/janicekchen/bivariate-bivalve/main/data/processed/bivariatebivalve-ledstatus.csv")

for i in range(0, 14):
    # select value of led_status for a row
    beach = beach_data.loc[beach_data["beach_num"] == i, 'BEACHNAME'].iloc[0]
    led_status = beach_data.loc[beach_data["beach_num"] == i, 'LED_status'].iloc[0]

    print(beach, led_status)

    # if value is 0 -> light up pixel as red, etc. 
    if led_status == 0:
        pixels[i] = red
    elif led_status == 1:
        pixels[i] = orange
    else:
        pixels[i] = green

# setting legend lights
pixels[15] = red
pixels[16] = orange
pixels[17] = green